from offline.categorizer import offline_categorize
import re


def process_manual_expense(data):

    text = data.items
    amount = data.amount

    # remove numbers from text
    clean_text = re.sub(r'\d+', '', text)

    # split items
    items = clean_text.split()

    # run categorization
    category_result = offline_categorize(items)

    # get main category
    category = max(category_result, key=category_result.get)

    return {
        "items": text,
        "amount": amount,
        "category": category
    }