import numpy as np

if __package__:
    from .categories import CATEGORIES
    from .embedding import embed
else:
    from categories import CATEGORIES
    from embedding import embed


# category → centroid vector
category_vectors = {}

for category, examples in CATEGORIES.items():

    # embed all example phrases
    vectors = embed(examples)

    # compute centroid (average vector)
    centroid = np.mean(vectors, axis=0)

    category_vectors[category] = centroid