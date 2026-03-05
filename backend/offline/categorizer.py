from product_map import PRODUCT_MAP
from preprocessing import clean_item
from embedding import embed
from category_vectors import category_examples
from similarity import cosine_similarity


def generate_phrases(text):

    words = text.split()

    phrases = [text]

    # single tokens
    phrases.extend(words)

    # bigrams
    for i in range(len(words) - 1):
        phrases.append(words[i] + " " + words[i + 1])

    for i in range(len(words)-2):
        phrases.append(words[i] + " " + words[i+1] + " " + words[i+2])

    return list(set(phrases))


def offline_categorize(items):

    print("\n========= OFFLINE CATEGORIZATION =========\n")

    results = {}

    for original_item in items:

        clean_text = clean_item(original_item)

        # -------- PRODUCT DICTIONARY MATCH --------
        matched = False

        for key in PRODUCT_MAP:
            if key in clean_text:

                category = PRODUCT_MAP[key]

                print(f"ITEM: {original_item}")
                print(f"CLEANED: {clean_text}")
                print(f"PREDICTED CATEGORY: {category}")
                print(f"MATCHED PRODUCT MAP: {key}")
                print("-----------------------------------")

                results[category] = results.get(category, 0) + 1
                matched = True
                break

        # if dictionary matched → skip embedding
        if matched:
            continue

        # -------- EMBEDDING FALLBACK --------

        phrases = generate_phrases(clean_text)

        phrase_vectors = embed(phrases)

        best_category = None
        best_score = -1
        best_example = None

        for phrase_vec in phrase_vectors:

            for category, examples in category_examples.items():

                for example_text, example_vec in examples:

                    score = cosine_similarity(phrase_vec, example_vec)

                    if score > best_score:
                        best_score = score
                        best_category = category
                        best_example = example_text

        if best_score < 0.40:
            best_category = "other"

        results[best_category] = results.get(best_category, 0) + 1

        print(f"ITEM: {original_item}")
        print(f"CLEANED: {clean_text}")
        print(f"PHRASES: {phrases}")
        print(f"PREDICTED CATEGORY: {best_category}")
        print(f"MATCHED EXAMPLE: {best_example}")
        print(f"SIMILARITY SCORE: {round(best_score,3)}")
        print("-----------------------------------")

    print("\n========= CATEGORY TOTALS =========\n")
    print(results)

    return results