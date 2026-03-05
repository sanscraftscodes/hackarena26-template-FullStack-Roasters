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
# OCR CLEANER
# -----------------------------
def clean_ocr_text(raw_text):

    lines = raw_text.split("\n")
    cleaned = []

    buffer = ""

    for line in lines:

        line = line.strip()

        if not line:
            continue

        # join broken decimals like ".00"
        if re.match(r"^\.\d+", line):
            buffer += line
            continue

        if buffer:
            line = buffer + line
            buffer = ""

        cleaned.append(line)

    return "\n".join(cleaned)


# -----------------------------
# EXTRACT VENDOR NAME
# -----------------------------
def extract_vendor_name(raw_text):

    lines = raw_text.split("\n")

    for line in lines[:12]:

        text = line.strip()

        if len(text) < 4:
            continue

        if re.search(r"\d{4,}", text):
            continue

        if any(word in text.lower() for word in [
            "mart", "store", "super", "market", "ltd", "retail"
        ]):
            return text

    return "Unknown"


# -----------------------------
# BUILD ITEM ROWS
# -----------------------------
def build_item_rows(raw_text):

    lines = raw_text.split("\n")

    rows = []
    current_name = ""
    start_items = False

    for line in lines:

        line = line.strip()

        if not line:
            continue

        lower = line.lower()

        # detect item table start
        if "particular" in lower:
            start_items = True
            continue

        if not start_items:
            continue

        # stop when totals start
        if "gst breakup" in lower or "amount received" in lower:
            break

        # detect prices
        numbers = re.findall(r"\d+\.\d{2}", line)

        if numbers:

            unit_price = float(numbers[-1])

            qty_match = re.search(r"(\d+)\s*[xX]", line)

            quantity = 1

            if qty_match:
                quantity = int(qty_match.group(1))

            total_price = round(quantity * unit_price, 2)

            if current_name:

                rows.append(
                    f"{current_name.strip()} | qty:{quantity} | unit:{unit_price} | total:{total_price}"
                )

                current_name = ""

        else:

            # remove HSN codes
            line = re.sub(r"^\d{3,6}\s*", "", line)

            if not line.isdigit():
                current_name += " " + line

    if not rows:
        return ""

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

        clean_items.append(item)

    return clean_items


# -----------------------------
# EXTRACT TOTALS FROM OCR TEXT
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

        # subtotal
        if "taxable" in lower and nums:
            subtotal = float(nums[-1])

        # cgst
        if "cgst" in lower and nums:
            cgst += float(nums[-1])

        # sgst
        if "sgst" in lower and nums:
            sgst += float(nums[-1])

        # total detection
        if "amount received" in lower or "total amount" in lower:

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


    prompt = f"""
You are a STRICT receipt parsing AI.

Your job is to convert receipt text into structured purchase data.

Rules:

1. Extract ONLY purchased products.
2. Ignore:
GST
CGST
SGST
Tax
Subtotal
Total
Invoice
Payment
UPI
Phone numbers
Dates

3. Each item must contain:

name
quantity
unit_price
total_price
category

4. total_price = quantity × unit_price

5. Categories allowed:

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

6. If quantity missing assume quantity = 1

7. Remove HSN codes or serial numbers before names.

8. DO NOT hallucinate items.

Return STRICT JSON ONLY.

JSON format:

{{
"vendor_name":"string",
"items":[
{{
"name":"string",
"quantity":number,
"unit_price":number,
"total_price":number,
"category":"string"
}}
]
}}

ITEM ROWS:

{structured_rows}
"""

    try:

        response = model.generate_content(prompt)

        output = response.text.strip()

        print("🟢 [Gemini] Raw Output:")
        print(output)

        if "```" in output:
            output = output.split("```")[1]

        if output.startswith("json"):
            output = output.replace("json", "", 1)

        output = output.strip()

        try:

            parsed_json = json.loads(output)

            if "items" in parsed_json:
                parsed_json["items"] = remove_invalid_items(parsed_json["items"])

        except json.JSONDecodeError:

            print("⚠️ JSON parse failed")

            parsed_json = {
                "vendor_name": vendor,
                "items": []
            }

        subtotal, tax, total = extract_totals(clean_text)

        parsed_json["vendor_name"] = vendor
        parsed_json["subtotal"] = subtotal
        parsed_json["tax"] = tax
        parsed_json["total"] = total

        parsed_json["computed_items_total"] = compute_items_total(
            parsed_json.get("items", [])
        )

        print("✅ [Gemini] JSON Parsed Successfully")

        return parsed_json

    except Exception as e:

        print("🔴 [Gemini ERROR]:", str(e))

        return {
            "vendor_name": "Unknown Store",
            "items": [],
            "subtotal": None,
            "tax": None,
            "total": None,
            "computed_items_total": None
        }