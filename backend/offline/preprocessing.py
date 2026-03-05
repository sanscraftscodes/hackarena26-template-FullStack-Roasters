import re

def clean_item(text):

    text = text.lower()

    text = re.sub(r'([a-z])([0-9])', r'\1 \2', text)
    text = re.sub(r'([0-9])([a-z])', r'\1 \2', text)
    # remove numbers
    text = re.sub(r'\d+', ' ', text)

    # remove measurement units ONLY when separate words
    text = re.sub(r'\b(kg|gm|g|ml|ltr|l)\b', ' ', text)

    # remove special characters
    text = re.sub(r'[^a-z\s]', ' ', text)

    # normalize spaces
    text = re.sub(r'\s+', ' ', text)

    return text.strip()