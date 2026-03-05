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
    "amount received",
    "received from",
    "amount inr",
    "tax breakup",
    "payment",
    "total"
]


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


def clean_item(text):

    # remove item codes like 0710 1104 etc
    text = re.sub(r"^\d+\s*", "", text)

    # remove special characters
    text = re.sub(r"[^a-zA-Z0-9\s\-]", " ", text)

    text = re.sub(r"\s+", " ", text)

    return text.strip()


def is_price(text):

    return re.fullmatch(r"\d+\.\d{2}", text) is not None


def extract_items_with_price(ocr_text):

    lines = [l.strip() for l in ocr_text.split("\n") if l.strip()]

    items = []
    last_item = None

    for line in lines:

        # Stop parsing when footer begins
        if is_footer(line):
            break

        if is_noise(line):
            continue

        # If line is a price
        if is_price(line):

            if last_item:

                items.append({
                    "item": last_item,
                    "price": float(line)
                })

                last_item = None

            continue

        # Otherwise treat as item
        cleaned = clean_item(line)

        # must contain letters
        if not re.search(r"[a-zA-Z]", cleaned):
            continue

        # too short → ignore
        if len(cleaned) < 4:
            continue

        last_item = cleaned

    return items