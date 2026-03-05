import re


NOISE_WORDS = [
    "cgst","sgst","cess","gst","tax",
    "total","amount","invoice","bill",
    "phone","cin","fssai","qty",
    "rate","value","mrp","discount",
    "received","customer","payment",
    "breakup","taxable","cashier"
]


STOP_WORDS = [
    "total",
    "total amount",
    "total inr",
    "grand total",
    "amount received",
    "received from",
    "payment",
    "tax breakup",
    "cash",
    "balance"
]

FOOTER_WORDS = [
    "subtotal",
    "total",
    "tax",
    "state tax",
    "paid",
    "credit",
    "debit",
    "balance"
]

def is_footer(line):
    line = line.lower()
    return any(word in line for word in FOOTER_WORDS)


def is_noise(text):

    text = text.lower()

    for word in NOISE_WORDS:
        if word in text:
            return True

    return False


def is_footer(text):

    text = text.lower()

    for word in STOP_WORDS:
        if word in text:
            return True

    return False

def is_barcode(line):
    return line.isdigit() and len(line) >= 6

def clean_item(text):

    text=text.strip()
    text=text.lower()

    # OCR corrections
    text = text.replace("0", "o")
    text = text.replace("1", "l")
    text = text.replace("5", "s")
    # remove item codes like 0710 1104 etc
    text = re.sub(r"^\d+\s*", "", text)

    # remove special characters
    text = re.sub(r"[^a-zA-Z0-9\s\-]", " ", text)

    text = re.sub(r"\s+", " ", text)

    return text


def is_price(text):

    return re.fullmatch(r"\d+\.\d{1,2}", text) is not None


def extract_items_with_price(ocr_text):

    lines = [l.strip() for l in ocr_text.split("\n") if l.strip()]

    items = []
    last_item = None

    for line in lines:

        # skip footer or noise lines
        if is_footer(line):
            continue

        if is_noise(line):
            continue



        # ------------------------------------------------
        # CASE 1: ITEM + PRICE on same line
        # Example:
        # CHUM CHURUM PEACH 375ML 5.50
        # ------------------------------------------------
        price_match = re.search(r"(\d+\.\d{2})$", line)

        if price_match:

            price = float(price_match.group())

            item_name = line.replace(price_match.group(), "").strip()

            cleaned = clean_item(item_name)

            if len(cleaned) >= 3 and re.search(r"[a-zA-Z]", cleaned):

                items.append({
                    "item": cleaned,
                    "price": price
                })

                last_item = None
                continue


        # ------------------------------------------------
        # CASE 2: PRICE on separate line
        # Example:
        # ITEM
        # 5.50
        # ------------------------------------------------
        if is_price(line):

            if last_item and len(last_item) > 2:

                items.append({
                    "item": last_item.strip(),
                    "price": float(line)
                })

                last_item = None

            continue


        # ------------------------------------------------
        # OTHERWISE treat line as item description
        # ------------------------------------------------
        cleaned = clean_item(line)

        if "paid" in cleaned.lower():
            continue

        if not re.search(r"[a-zA-Z]", cleaned):
            continue

        if len(cleaned) < 5:
            continue

        last_item = cleaned

    return items