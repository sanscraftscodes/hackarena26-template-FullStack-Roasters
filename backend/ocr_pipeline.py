# ocr_pipeline.py

import cv2
import numpy as np
from paddleocr import PaddleOCR
from PIL import Image
import io

# Initialize OCR once (important for performance)
ocr = PaddleOCR(use_angle_cls=True, lang='en')


def preprocess_image(image_bytes):
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image = np.array(image)

    # Convert RGB to BGR
    image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)

    # Downscale if too large
    h, w = image.shape[:2]
    if max(h, w) > 2000:
        scale = 2000 / max(h, w)
        image = cv2.resize(image, (int(w*scale), int(h*scale)))

    # Convert to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # CLAHE
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    gray = clahe.apply(gray)

    # 🔥 IMPORTANT FIX:
    # Convert back to 3-channel image
    processed = cv2.cvtColor(gray, cv2.COLOR_GRAY2BGR)

    return processed

def extract_text(image_bytes):
    processed = preprocess_image(image_bytes)

    result = ocr.ocr(processed)

    lines = []
    if result and result[0]:
        for line in result[0]:
            text = line[1][0]
            lines.append(text)

    return "\n".join(lines)