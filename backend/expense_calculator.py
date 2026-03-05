from collections import defaultdict


def calculate_expenses(items, categories):

    category_totals = defaultdict(float)

    overall_total = 0

    for item, category in zip(items, categories):

        price = item["price"]

        category_totals[category] += price

        overall_total += price

    return dict(category_totals), overall_total