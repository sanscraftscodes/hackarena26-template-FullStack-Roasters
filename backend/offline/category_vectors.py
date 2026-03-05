if __package__:
    from .categories import CATEGORIES
    from .embedding import embed
else:
    from categories import CATEGORIES
    from embedding import embed

# store embeddings for each example phrase
category_examples = {}

for category, examples in CATEGORIES.items():

    vectors = embed(examples)

    pairs = []

    for example_text, vec in zip(examples, vectors):
        pairs.append((example_text, vec))

    category_examples[category] = pairs
    
