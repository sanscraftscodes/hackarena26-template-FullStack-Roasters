import os
import json
import re
import google.generativeai as genai
from dotenv import load_dotenv

os.environ["PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION"] = "python"

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if not GEMINI_API_KEY:
    raise ValueError("❌ GEMINI_API_KEY not found in environment")

genai.configure(api_key=GEMINI_API_KEY)

model = genai.GenerativeModel("gemini-flash-lite-latest")


# -----------------------------
# OCR CLEANER (IMPROVED)
# -----------------------------
def clean_ocr_text(raw_text):

    lines = raw_text.split("\n")
    cleaned = []

    buffer = ""

    for line in lines:

        line = line.strip()

        if not line:
            continue

        # join broken decimals
        if re.match(r"^\.\d+", line):
            buffer += line
            continue

        if buffer:
            line = buffer + line
            buffer = ""

        # remove weird characters
        line = re.sub(r"[^\w\s\.\-%:/]", "", line)

        cleaned.append(line)

    return "\n".join(cleaned)


# -----------------------------
# EXTRACT VENDOR NAME
# -----------------------------
def extract_vendor_name(raw_text):

    lines = raw_text.split("\n")

    for line in lines[:15]:

        text = line.strip()

        if len(text) < 4:
            continue

        if re.search(r"\d{5,}", text):
            continue

        if any(word in text.lower() for word in [
            "mart", "store", "super", "market", "ltd", "retail"
        ]):
            return text

    return "Unknown"


# -----------------------------
# BUILD ITEM ROWS (IMPROVED)
# -----------------------------
def build_item_rows(raw_text):

    lines = raw_text.split("\n")
    rows = []
    start_items = False

    for line in lines:

        line = line.strip()
        if not line:
            continue

        lower = line.lower()

        # detect start of item table
        if any(x in lower for x in ["particular", "description", "item"]):
            start_items = True
            continue

        if not start_items:
            continue

        # stop when totals start
        if any(x in lower for x in [
            "gst", "total", "grand total", "amount received",
            "saved rs", "upi", "payment", "taxable"
        ]):
            break

        # detect price
        price_match = re.search(r"(\d+[.,]\d{2})", line)

        if price_match:

            price = float(price_match.group(1).replace(",", "."))

            # remove price from name
            name = line.replace(price_match.group(1), "").strip()

            # clean HSN codes
            name = re.sub(r"^\d{4,}", "", name).strip()

            # ignore garbage rows
            if len(name) < 3:
                continue

            rows.append(
                f"{name} | qty:1 | unit:{price} | total:{price}"
            )

    return "\n".join(rows)



# -----------------------------
# REMOVE INVALID ITEMS
# -----------------------------
def remove_invalid_items(items):

    clean_items = []

    for item in items:

        name = item.get("name", "").lower()

        if any(x in name for x in [
            "gst",
            "cgst",
            "sgst",
            "tax",
            "breakup",
            "amount",
            "received"
        ]):
            continue

        if item.get("quantity", 1) == 0:
            continue

        # remove blank item names
        if len(item.get("name","").strip()) < 3:
            continue

        clean_items.append(item)

    return clean_items


# -----------------------------
# EXTRACT TOTALS (IMPROVED)
# -----------------------------
def extract_totals(raw_text):

    subtotal = None
    tax = None
    total = None

    cgst = 0
    sgst = 0

    lines = raw_text.split("\n")

    for i, line in enumerate(lines):

        lower = line.lower()

        nums = re.findall(r"\d+\.\d{2}", line)

        if "taxable" in lower and nums:
            subtotal = float(nums[-1])

        if "cgst" in lower and nums:
            cgst += float(nums[-1])

        if "sgst" in lower and nums:
            sgst += float(nums[-1])

        if any(x in lower for x in [
            "amount received",
            "total amount",
            "net payable",
            "grand total"
        ]):

            if nums:
                total = float(nums[-1])

            elif i + 1 < len(lines):

                nums2 = re.findall(r"\d+\.\d{2}", lines[i + 1])

                if nums2:
                    total = float(nums2[0])

    tax = round(cgst + sgst, 2) if (cgst or sgst) else None

    return subtotal, tax, total


# -----------------------------
# CALCULATE ITEM TOTAL
# -----------------------------
def compute_items_total(items):

    total = 0

    for item in items:
        total += item.get("total_price", 0)

    return round(total, 2)

# -----------------------------
# LLM CLEANUP (NEW)
# -----------------------------
def cleanup_items_with_llm(items):

    prompt = f"""
Clean the following OCR extracted product items.

Tasks:
1. Fix obvious OCR spelling mistakes in product names
2. Remove garbage items (single letters, unreadable names)
3. Keep real purchasable products only
4. Do NOT modify prices or quantities

Return STRICT JSON:

{{
 "items":[
  {{
   "name": "string",
   "quantity": number,
   "unit_price": number,
   "total_price": number,
   "category": "string"
  }}
 ]
}}

Items:

{json.dumps(items, indent=2)}
"""

    response = model.generate_content(prompt)

    output = response.text.strip()

    if "```" in output:
        output = output.split("```")[1]

    if output.startswith("json"):
        output = output.replace("json", "", 1)

    cleaned = json.loads(output)

    return cleaned.get("items", items)
# -----------------------------
# GEMINI STRUCTURING
# -----------------------------
def refine_receipt_text(raw_text: str):

    print("\n🔵 [Gemini] Starting refinement...")

    clean_text = clean_ocr_text(raw_text)

    vendor = extract_vendor_name(clean_text)

    structured_rows = build_item_rows(clean_text)

    print("\n🧾 Structured Rows Sent To Gemini:\n")
    print(structured_rows)

    if not structured_rows or not structured_rows.strip():
        print("⚠️ No structured rows detected, sending raw OCR")
        structured_rows = clean_text

    if (
        "amount in figures" in clean_text.lower()
        or "received from" in clean_text.lower()
        or "on account of" in clean_text.lower()
    ):

        amount = None

        patterns = [
            r"amount\s*in\s*figures\D{0,10}(\d+)",
            r"amount\s*paid\D{0,10}(\d+)",
            r"amount\D{0,10}(\d+)",
            r"total\D{0,10}(\d+)"
        ]

        for p in patterns:
            m = re.search(p, clean_text.lower())
            if m:
                amount = float(m.group(1))
                break
        purpose_match = re.search(r"on account of\s*(.*)", clean_text.lower())
        purpose = purpose_match.group(1).strip() if purpose_match else "Payment"

        if amount:

            return {
                "vendor_name": vendor,
                "items": [
                    {
                        "name": purpose,
                        "quantity": 1,
                        "unit_price": amount,
                        "total_price": amount,
                        "category": "Utilities"
                    }
                ],
                "subtotal": amount,
                "tax": 0,
                "total": amount
            }
    prompt = f"""
    You are an expert receipt parsing AI.

    Your task is to convert OCR receipt rows into clean structured purchase data.

    IMPORTANT:
    The OCR text may contain noise, broken words, tax lines, payment lines, or totals.
    You must identify ONLY real purchased products.

    STRICT RULES:

    1. Extract ONLY purchased product items.

    2. IGNORE lines containing:
    GST
    CGST
    SGST
    TAX
    BREAKUP
    TOTAL
    GRAND TOTAL
    AMOUNT RECEIVED
    PAYMENT
    UPI
    INVOICE
    DATE
    TIME
    ITEMS
    SAVED
    CUSTOMER

    3. Ignore rows that:
    - contain mostly numbers
    - contain no readable product name
    - contain only prices
    - look like table headers (Qty, Rate, Value, SN)

    4. Product names may contain OCR mistakes.
    Clean them slightly but keep the recognizable product name.

    Example:
    "FIGAR0 0LIVE 0I-200m1" → "Figaro Olive Oil 200ml"

    5. If quantity is missing assume:
    quantity = 1

    6. Prices must follow:
    total_price = quantity × unit_price

    7. Ignore items where:
    - name length < 3 characters
    - unit_price < 3
    - line clearly belongs to tax or totals section

    8. Allowed categories:

    Food  
    Grocery  
    Utilities  
    Travel  
    Entertainment  
    Medical  
    Stationary  
    Household  
    Electronics  
    Clothes  
    Selfcare  
    Other

    9. Return STRICT JSON ONLY.

    DO NOT include explanations.

    JSON FORMAT:

    {{
    "items": [
        {{
        "name": "string",
        "quantity": number,
        "unit_price": number,
        "total_price": number,
        "category": "string"
        }}
    ]
    }}

    Receipt rows:

    {structured_rows}
    """

    try:

        response = model.generate_content(prompt)

        output = response.text.strip()

        print("🟢 Gemini Raw Output:")
        print(output)

        if "```" in output:
            output = output.split("```")[1]

        if output.startswith("json"):
            output = output.replace("json", "", 1)

        output = output.strip()

        try:

            parsed_json = json.loads(output)

            # handle case where Gemini returns list
            if isinstance(parsed_json, list):
                parsed_json = {
                    "vendor_name": vendor,
                    "items": parsed_json
                }

            if "items" in parsed_json:

                # remove obvious garbage first
                parsed_json["items"] = remove_invalid_items(parsed_json["items"])

                # LLM cleanup pass
                parsed_json["items"] = cleanup_items_with_llm(parsed_json["items"])

        except json.JSONDecodeError:

            print("⚠️ JSON parse failed")

            parsed_json = {
                "vendor_name": vendor,
                "items": []
            }

        subtotal, tax, total = extract_totals(clean_text)
        items_total = compute_items_total(parsed_json.get("items", []))

        if subtotal is None:
            subtotal = items_total

        if total is None and tax is not None:
            total = round(subtotal + tax, 2)

        parsed_json["vendor_name"] = vendor
        parsed_json["subtotal"] = subtotal
        parsed_json["tax"] = tax
        parsed_json["total"] = total

        parsed_json["computed_items_total"] = compute_items_total(
            parsed_json.get("items", [])
        )

        print("✅ JSON Parsed Successfully")

        return parsed_json

    except Exception as e:

        print("🔴 Gemini ERROR:", str(e))

        return {
            "vendor_name": "Unknown Store",
            "items": [],
            "subtotal": None,
            "tax": None,
            "total": None,
            "computed_items_total": None
        }