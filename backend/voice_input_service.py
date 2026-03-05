from faster_whisper import WhisperModel
import tempfile
from manual_input_service import process_manual_expense
from expense_parser import parse_expenses
from offline.claude_classifier import classify, classify_batch, ClassifierResult


model = None

def get_model():
    global model
    if model is None:
        model = WhisperModel(
            "large-v3",
            device="cpu",
            compute_type="int8"
        )
    return model


def process_voice_expense(audio_file):

    with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
        tmp.write(audio_file.read())
        temp_path = tmp.name

    model = get_model()

    segments, info = model.transcribe(temp_path)

    text = " ".join(segment.text for segment in segments)

    parsed_expenses = parse_expenses(text)

    results = []

    for expense in parsed_expenses:
        category = classify(expense["item"])

        results.append({
            "item": expense["item"],
            "amount": expense["amount"],
            "category": category
        })

    return {
        "transcribed_text": text,
        "expenses": results
    }