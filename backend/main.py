import multiprocessing

multiprocessing.set_start_method("spawn", force=True)

from fastapi import FastAPI, UploadFile, File
from dotenv import load_dotenv
from pydantic import BaseModel
from typing import List, Dict, Optional

from ocr_pipeline import extract_text
from gemini_service import refine_receipt_text
from receipt_parser import extract_items_with_price
from offline.categorizer import offline_categorize
from expense_calculator import calculate_expenses
from models import ManualExpense
from manual_input_service import process_manual_expense
from voice_input_service import process_voice_expense
from offline.zero_shot_categorizer import zero_shot_categorize
from expense_parser import parse_expenses
import os
import shutil

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


class ReceiptData(BaseModel):
    vendor_name: str
    items: List[Item]

    subtotal: Optional[float] = None
    tax: Optional[float] = None
    total: Optional[float] = None

    # Map of category → total spent for this receipt
    category_totals: Optional[Dict[str, float]] = None

    budget_alerts: Optional[List[str]] = None
    is_anomaly: Optional[bool] = None
    created_at: Optional[str] = None
    user_id: Optional[str] = None


class APIResponse(BaseModel):
    success: bool
    data: Optional[ReceiptData]
    error: Optional[str]


class TextPayload(BaseModel):
    """Generic text payload for voice/manual expense parsing."""

    text: str


# ------------------ ROUTES ------------------

@app.get("/")
def home():
    return {"message": "SnapBudget backend running"}


@app.get("/health")
def health():
    """Simple health check endpoint used by the mobile app."""
    return {"status": "ok"}


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

    # The Gemini structuring already matches ReceiptData shape closely,
    # so we just coerce it into our model.
    receipt = ReceiptData(**structured_data)
    return APIResponse(success=True, data=receipt, error=None)


def _build_category_totals(items: List[Dict]) -> Dict[str, float]:
    """Aggregate totals per category from a list of item dicts."""
    totals: Dict[str, float] = {}
    for item in items:
        category = item.get("category") or "Other"
        total_price = float(item.get("total_price") or item.get("price") or 0)
        totals[category] = totals.get(category, 0.0) + total_price
    return totals


@app.post("/scan_receipt", response_model=APIResponse)
async def scan_receipt_new(file: UploadFile = File(...)):
    """
    Full online OCR flow used by the Flutter app.

    1. Run PaddleOCR (ocr_pipeline.extract_text)
    2. Clean + structure text using Gemini (gemini_service.refine_receipt_text)
    3. Compute category_totals from structured items
    """

    image_bytes = await file.read()

    # Step 1: OCR
    raw_text = extract_text(image_bytes)

    # Step 2: Gemini structuring
    structured = refine_receipt_text(raw_text)

    items = structured.get("items") or []
    category_totals = _build_category_totals(items)

    # Ensure numeric totals exist
    total = structured.get("total")
    if total is None:
        total = sum(category_totals.values())
        structured["total"] = float(total)

    if structured.get("subtotal") is None:
        structured["subtotal"] = float(total)

    structured["tax"] = float(structured.get("tax") or 0.0)
    structured["category_totals"] = category_totals

    receipt = ReceiptData(**structured)

    return APIResponse(success=True, data=receipt, error=None)


@app.post("/scan-receipt")
async def scan_receipt(file: UploadFile = File(...)):
    """
    Legacy OCR endpoint kept for backwards compatibility.
    Uses heuristic receipt_parser + offline categorizer.
    """

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
    """Legacy manual-expense endpoint (not used by the Flutter app)."""

    result = process_manual_expense(expense)

    return {
        "status": "success",
        "data": result
    }


@app.post("/voice-expense")
async def voice_expense(audio: UploadFile = File(...)):
    """Legacy voice-expense endpoint that accepts raw audio."""

    result = process_voice_expense(audio.file)

    return {
        "success": True,
        "data": result
    }


@app.post("/voice_expense", response_model=APIResponse)
async def voice_expense_text(payload: TextPayload):
    """
    Voice expense endpoint used by Flutter.

    Expects already-transcribed text like:
    "I bought milk for 50 and vegetables for 120"

    Returns a structured receipt-like payload compatible with the mobile app.
    """

    parsed = parse_expenses(payload.text)

    items: List[Dict] = []
    for exp in parsed:
        name = exp["item"]
        amount = float(exp["amount"])
        category = zero_shot_categorize(name)
        items.append(
            {
                "name": name,
                "quantity": 1,
                "unit_price": amount,
                "total_price": amount,
                "category": category,
            }
        )

    category_totals = _build_category_totals(items)
    total = sum(category_totals.values())

    receipt = ReceiptData(
        vendor_name="Voice expense",
        items=[Item(**item) for item in items],
        subtotal=total,
        tax=0.0,
        total=total,
        category_totals=category_totals,
    )

    return APIResponse(success=True, data=receipt, error=None)


@app.post("/manual_expense", response_model=APIResponse)
async def manual_expense_text(payload: TextPayload):
    """
    Manual expense endpoint used by Flutter.

    Expects free-form text such as:
    "Milk 50, Bread 30, Eggs 60"
    """

    parsed = parse_expenses(payload.text)

    items: List[Dict] = []
    for exp in parsed:
        name = exp["item"]
        amount = float(exp["amount"])
        category = zero_shot_categorize(name)
        items.append(
            {
                "name": name,
                "quantity": 1,
                "unit_price": amount,
                "total_price": amount,
                "category": category,
            }
        )

    category_totals = _build_category_totals(items)
    total = sum(category_totals.values())

    receipt = ReceiptData(
        vendor_name="Manual expense",
        items=[Item(**item) for item in items],
        subtotal=total,
        tax=0.0,
        total=total,
        category_totals=category_totals,
    )

    return APIResponse(success=True, data=receipt, error=None)