from transformers import pipeline

# load model once
classifier = pipeline(
    "zero-shot-classification",
    model="facebook/bart-large-mnli"
)

CATEGORIES = [
    "Food",
    "Grocery",
    "Utilities",
    "Travel",
    "Entertainment",
    "Medical",
    "Stationary",
    "Household",
    "Clothes",
    "Selfcare",
    "Other"
]


def zero_shot_categorize(text: str):

    result = classifier(
        text,
        CATEGORIES
    )

    return result["labels"][0]