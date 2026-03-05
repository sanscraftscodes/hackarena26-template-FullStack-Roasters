import re

KNOWN_VENDORS = {
    "dmart": "DMart",
    "avenue supermarts": "DMart",
    "reliance smart": "Reliance Smart",
    "reliance fresh": "Reliance Fresh",
    "big bazaar": "Big Bazaar",
    "more": "More",
    "spencer": "Spencer's",
    "vishal mart": "Vishal Mart",
    "star bazaar": "Star Bazaar",
    "metro cash": "Metro Cash & Carry"
}


def clean_text(text):

    text = text.lower()

    text = re.sub(r"[^a-z\s]", " ", text)

    text = re.sub(r"\s+", " ", text)

    return text.strip()


def detect_vendor(ocr_text):

    lines = ocr_text.split("\n")

    # Only scan top part of receipt
    header_lines = lines[:12]

    header = " ".join(header_lines)

    header = clean_text(header)

    for key, vendor in KNOWN_VENDORS.items():

        if key in header:

            return vendor

    return "Unknown"