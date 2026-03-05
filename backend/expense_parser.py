import re

def parse_expenses(text: str):
    """
    Extract expenses from multilingual speech
    Works for:
    - milk 50
    - milk for 50
    - 50 rupees milk
    - 100 रुपए पेट्रोल
    """

    text = text.lower()

    pattern = r'(\d+)\s*(?:rupees|rs|₹|रुपए|रुपये)?\s*([a-zA-Z\u0900-\u097F ]+)'

    matches = re.findall(pattern, text)

    expenses = []

    for amount, item in matches:

        item = item.strip()

        if len(item) > 1:
            expenses.append({
                "item": item,
                "amount": int(amount)
            })

    return expenses