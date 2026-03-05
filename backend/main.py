from fastapi import FastAPI, UploadFile, File
from ocr_pipeline import extract_text
from gemini_service import refine_receipt_text
from dotenv import load_dotenv
from pydantic import BaseModel
from typing import List, Dict, Optional
import os

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

app = FastAPI()


# ------------------ MODELS ------------------

class Item(BaseModel):
    name: str
    price: float
    category: Optional[str] = None


class ReceiptData(BaseModel):
    vendor_name: str
    items: List[Item]

    category_totals: Optional[Dict[str, float]] = None
    subtotal: float
    tax: float
    total: float

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