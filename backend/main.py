import multiprocessing
multiprocessing.set_start_method("spawn", force=True)
from fastapi import FastAPI, UploadFile, File
from ocr_pipeline import extract_text
from gemini_service import refine_receipt_text
from dotenv import load_dotenv
from pydantic import BaseModel
from typing import List, Dict, Optional
from ocr_pipeline import extract_text
from receipt_parser import extract_items_with_price
from offline.categorizer import offline_categorize
from vendor_detector import detect_vendor
from models import ManualExpense
from manual_input_service import process_manual_expense
from voice_input_service import process_voice_expense
import os
import shutil
import os

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

app = FastAPI()


# ------------------ MODELS ------------------



class Item(BaseModel):
    name: str
    quantity: int
    unit_price: float
    total_price: float
    category: str


from typing import Optional

class ReceiptData(BaseModel):
    vendor_name: str
    items: List[Item]

    subtotal: Optional[float] = None
    tax: Optional[float] = None
    total: Optional[float] = None

    budget_alerts: Optional[List[str]] = None
    is_anomaly: Optional[bool] = None
    created_at: Optional[str] = None
    user_id: Optional[str] = None

class APIResponse(BaseModel):
    success: bool
    data: Optional[ReceiptData]
    error: Optional[str]


# ------------------ ROUTES ------------------

@app.get("/")
def home():
    return {"message": "SnapBudget backend running"}


@app.post("/process_receipt", response_model=APIResponse)
async def process_receipt(file: UploadFile = File(...)):
    print("\n📥 [API] Receipt received")

    image_bytes = await file.read()

    print("🟡 [OCR] Extracting text...")
    raw_text = extract_text(image_bytes)

    print("🟡 [OCR] Extraction complete")

    print("🌐 [Gemini] Structuring receipt...")
    structured_data = refine_receipt_text(raw_text)

    print("📤 [API] Returning structured response")

    return {
        "success": True,
        "data": structured_data,
        "error": None
    }

@app.post("/scan-receipt")
async def scan_receipt(file: UploadFile = File(...)):

    image_bytes = await file.read()

    # Optional: save for debugging
    path = f"temp_{file.filename}"
    with open(path, "wb") as f:
        f.write(image_bytes)

    # ---------------- OCR ----------------
    text = extract_text(image_bytes)

    # ---------------- PARSE ITEMS ----------------
    parsed_items = extract_items_with_price(text)

    item_names = [i["item"] for i in parsed_items]

    # ---------------- CLASSIFICATION ----------------
    categories = offline_categorize(item_names)

    structured_items = []

    for item in parsed_items:

        name = item["item"]
        price = item["price"]

        category = categories.get(name, "other")

        structured_items.append({
            "name": name,
            "quantity": 1,
            "unit_price": price,
            "total_price": price,
            "category": category.capitalize()
        })

    # ---------------- CATEGORY TOTALS ----------------
    category_totals = {}

    for item in structured_items:
        cat = item["category"]
        price = item["total_price"]

        category_totals[cat] = category_totals.get(cat, 0) + price

    # ---------------- TOTALS ----------------
    subtotal = sum(i["total_price"] for i in structured_items)

    # ---------------- VENDOR DETECTION ----------------
    vendor_name = detect_vendor(text)

    # ---------------- RESPONSE ----------------
    return {
        "success": True,
        "data": {
            "vendor_name": vendor_name,
            "items": structured_items,
            "subtotal": subtotal,
            "tax": None,
            "total": subtotal,
            "budget_alerts": None,
            "is_anomaly": None,
            "created_at": None,
            "user_id": None
        },
        "error": None
    }   

@app.post("/manual-expense")
def manual_expense(expense: ManualExpense):
    
    result = process_manual_expense(expense)

    return {
        "status": "success",
        "data": result
    }


@app.post("/voice-expense")
async def voice_expense(audio: UploadFile = File(...)):

    result = process_voice_expense(audio.file)

    return {
        "success": True,
        "data": result
    }