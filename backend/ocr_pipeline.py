# ocr_pipeline.py

import cv2
import numpy as np
from paddleocr import PaddleOCR
from PIL import Image
import io

# Initialize OCR once
ocr = PaddleOCR(use_angle_cls=True, lang='en')


def preprocess_image(image_bytes):
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image = np.array(image)

    # RGB → BGR
    image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)

    # Resize large images
    h, w = image.shape[:2]
    if max(h, w) > 2000:
        scale = 2000 / max(h, w)
        image = cv2.resize(image, (int(w * scale), int(h * scale)))

    # Convert to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Mild denoising
    gray = cv2.fastNlMeansDenoising(gray, None, 15, 7, 21)

    # Contrast enhancement
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    gray = clahe.apply(gray)

    # Slight sharpening (not aggressive)
    kernel = np.array([
        [0,-1,0],
        [-1,5,-1],
        [0,-1,0]
    ])

    sharp = cv2.filter2D(gray, -1, kernel)

    # Convert back to 3 channel
    processed = cv2.cvtColor(sharp, cv2.COLOR_GRAY2BGR)

    return processed


def extract_text(image_bytes):

    processed = preprocess_image(image_bytes)

    # Slight upscale helps OCR
    processed = cv2.resize(processed, None, fx=1.3, fy=1.3, interpolation=cv2.INTER_CUBIC)

    result = ocr.ocr(processed)

    lines = []

    if result and result[0]:
        for line in result[0]:
            text = line[1][0].strip()

            if text:
                lines.append(text)

    return "\n".join(lines)