from offline.zero_shot_categorizer import zero_shot_categorize
import re


def process_manual_expense(text):

    # text = data.items
    # amount = data.amount
    # extract amount
    amount_match = re.search(r'\d+', text)
    amount = int(amount_match.group()) if amount_match else 0
    # remove numbers from text
    clean_text = re.sub(r'\d+', '', text)

    # split items
    items = clean_text.split()

    # run categorization
    category = zero_shot_categorize(cleaned_text)

    # get main category
    category = max(category_result, key=category_result.get)

    return {
        "items": text,
        "amount": amount,
        "category": category
    }