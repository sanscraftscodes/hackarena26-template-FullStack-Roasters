import os
import json

import os
os.environ["PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION"] = "python"

import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if not GEMINI_API_KEY:
    raise ValueError("❌ GEMINI_API_KEY not found in environment")

genai.configure(api_key=GEMINI_API_KEY)

model = genai.GenerativeModel("gemini-flash-lite-latest")


def refine_receipt_text(raw_text: str):
    print("\n🔵 [Gemini] Starting refinement...")

    prompt = f"""
    You are an AI receipt parser.

    Convert the following OCR receipt text into STRICT JSON format.

    Rules:
    - Extract vendor name
    - Extract list of items with name, price, and category
    - Categories must be one of:
    Food, Grocery, Utilities, Travel, Entertainment, Medical, Stationary, Household, Clothes, Selfcare (includes cosmetics, skincare items etc) Other
    - Extract subtotal, tax, total if present
    - Output ONLY valid JSON
    - Do NOT include explanation
    - Do NOT include markdown

    OCR TEXT:
    {raw_text}
    """

    try:
        response = model.generate_content(prompt)
        output = response.text.strip()

        print("🟢 [Gemini] Raw Output:")
        print(output)

        # Clean markdown if present
        if output.startswith("```"):
            output = output.split("```")[1]

        parsed_json = json.loads(output)

        print("✅ [Gemini] JSON Parsed Successfully")
        return parsed_json

    except Exception as e:
        print("🔴 [Gemini ERROR]:", str(e))
        return {
            "error": "Gemini parsing failed",
            "raw_text": raw_text
        }