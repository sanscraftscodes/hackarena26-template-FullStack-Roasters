from offline.claude_classifier import classify, classify_batch, ClassifierResult
import re


def process_manual_expense(expense):
    text = (expense.items or expense.note or "").strip()

    if expense.amount is not None:
        amount = float(expense.amount)
    else:
        amount_match = re.search(r"\d+(\.\d+)?", text)
        amount = float(amount_match.group()) if amount_match else 0.0

    clean_text = re.sub(r"\d+(\.\d+)?", "", text).strip()
    category = classify(clean_text or "expense")

    return {
        "items": clean_text or text,
        "amount": amount,
        "category": category
    }