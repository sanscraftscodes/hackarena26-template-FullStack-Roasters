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
from expense_calculator import calculate_expenses
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

    # OCR
    text = extract_text(image_bytes)

    # Extract items + prices
    parsed_items = extract_items_with_price(text)

    item_names = [i["item"] for i in parsed_items]

    # Categorize
    categories = offline_categorize(item_names)

    # Calculate totals
    category_totals, overall_total = calculate_expenses(parsed_items, categories)

    return {
        "items": parsed_items,
        "category_totals": category_totals,
        "overall_total": overall_total
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