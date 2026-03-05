if __package__:
    from .product_map import PRODUCT_MAP
    from .preprocessing import clean_item
    from .embedding import embed
    from .category_vectors import category_vectors
    from .similarity import cosine_similarity
else:
    from product_map import PRODUCT_MAP
    from preprocessing import clean_item
    from embedding import embed
    from category_vectors import category_vectors
    from similarity import cosine_similarity


SIM_THRESHOLD = 0.45


def generate_phrases(text):

    words = text.split()

    phrases = [text]

    # single tokens
    phrases.extend(words)

    # bigrams
    for i in range(len(words) - 1):
        phrases.append(words[i] + " " + words[i + 1])

    # trigrams
    for i in range(len(words) - 2):
        phrases.append(words[i] + " " + words[i + 1] + " " + words[i + 2])

    # remove duplicates + empty
    return list(set(p for p in phrases if p.strip()))


def dictionary_lookup(text):

    for key, category in PRODUCT_MAP.items():
        if key in text:
            return category, key

    return None, None


def offline_categorize(items):

    print("\n========= OFFLINE CATEGORIZATION =========\n")

    item_categories = {}
    category_counts = {}

    for original_item in items:

        clean_text = clean_item(original_item)

        # skip empty OCR garbage
        if not clean_text or len(clean_text) < 3:
            continue

        # ---------------------------
        # STEP 1 : PRODUCT MAP
        # ---------------------------

        category, key = dictionary_lookup(clean_text)

        if category:

            item_categories[original_item] = category
            category_counts[category] = category_counts.get(category, 0) + 1

            print(f"ITEM: {original_item}")
            print(f"CLEANED: {clean_text}")
            print(f"PREDICTED CATEGORY: {category}")
            print(f"MATCHED PRODUCT MAP: {key}")
            print("-----------------------------------")

            continue


        # ---------------------------
        # STEP 2 : EMBEDDING SIMILARITY
        # ---------------------------

        phrases = generate_phrases(clean_text)
        phrase_vectors = embed(phrases)

        best_category = None
        best_score = -1

        for phrase_vec in phrase_vectors:

            for category, category_vec in category_vectors.items():

                score = cosine_similarity(phrase_vec, category_vec)

                if score > best_score:
                    best_score = score
                    best_category = category


        # threshold fallback
        if best_score < SIM_THRESHOLD:
            best_category = "other"

        item_categories[original_item] = best_category
        category_counts[best_category] = category_counts.get(best_category, 0) + 1


        print(f"ITEM: {original_item}")
        print(f"CLEANED: {clean_text}")
        print(f"PHRASES: {phrases}")
        print(f"PREDICTED CATEGORY: {best_category}")
        print(f"SIMILARITY SCORE: {round(best_score,3)}")
        print("-----------------------------------")


    print("\n========= CATEGORY TOTALS =========\n")
    print(category_counts)

    return item_categories