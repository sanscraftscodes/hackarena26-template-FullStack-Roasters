# 🚀 SmartBudgetOCR

AI-powered hybrid expense management system with:
- 📷 Receipt OCR (PaddleOCR)
- 🌐 Online structuring (Gemini)
- 🧠 Category analytics
- 🚨 Anomaly detection
- 📊 Dashboard-ready backend
- ☁ Firestore-ready architecture

---

# 🛠 SYSTEM REQUIREMENTS

## ✅ Required Versions

- Python **3.11.x** (IMPORTANT – do NOT use 3.13)
- Git
- Flutter (for mobile_app)
- VS Code (recommended)

---

# 🧑‍💻 BACKEND SETUP (FIRST TIME)

## 1️⃣ Clone Repository

```bash
git clone https://github.com/sanscraftscodes/SmartBudgetOCR.git
cd SmartBudgetOCR
```

---

## 2️⃣ Use Python 3.11 (VERY IMPORTANT)

Check version:

```bash
python --version
```

If it shows 3.13, explicitly use:

```bash
py -3.11 -m venv venv
```

---

## 3️⃣ Create Virtual Environment

Inside project root:

```bash
py -3.11 -m venv venv
```

Activate it:

### Windows:
```bash
venv\Scripts\activate
```

### Mac/Linux:
```bash
source venv/bin/activate
```

You should see:

```
(venv)
```

---

## 4️⃣ Install Dependencies

```bash
pip install -r backend/requirements.txt
```

If requirements.txt is missing:

```bash
pip freeze > backend/requirements.txt
```

---

## 5️⃣ Create .env File (DO NOT COMMIT)

Inside:

```
backend/.env
```

Add:

```
GEMINI_API_KEY=your_api_key_here
```

⚠️ Never push this file.

---

## 6️⃣ Run Backend

Go to backend:

```bash
cd backend
uvicorn main:app --reload
```

Open:

```
http://127.0.0.1:8000/docs
```

If Swagger loads → Backend is healthy.

---

# 🔐 GIT SETUP RULES (VERY IMPORTANT)

## `.gitignore` is already included.

It ignores:

- backend/venv
- backend/.env
- __pycache__
- Flutter build files
- Firebase JSON
- OS junk files

### NEVER COMMIT:

- `.env`
- `venv/`
- Firebase service account JSON
- `build/` folders

---

# 🔄 DAILY WORKFLOW FOR TEAM MEMBERS

## Activate environment every time after reopening terminal:

```bash
cd SmartBudgetOCR
venv\Scripts\activate
```

Then run backend:

```bash
cd backend
uvicorn main:app --reload
```

---

# 🌿 BRANCH WORKFLOW

### DO NOT push directly to main.

Create your branch:

```bash
git checkout -b feature-name
```

Push branch:

```bash
git push origin feature-name
```

Create Pull Request → Merge to main.

---

# 📦 PROJECT STRUCTURE

```
SmartBudgetOCR/
│
├── backend/
│   ├── main.py
│   ├── ocr_pipeline.py
│   ├── gemini_service.py
│   ├── analytics/
│   ├── database/
│   └── requirements.txt
│
├── mobile_app/
│
├── .gitignore
└── README.md
```

---

# 🚨 COMMON ISSUES

## ❌ cv2 / numpy error

Ensure:

```
numpy==1.26.4
opencv-python==4.6.0.66
paddlepaddle==2.6.2
paddleocr==2.7.3
```

---

## ❌ Gemini not working

Check:

```
backend/.env exists
GEMINI_API_KEY is valid
```

---

# 🔥 FINAL CHECK BEFORE PUSHING

Run:

```bash
git status
```

Make sure you DO NOT see:

- .env
- venv
- JSON credential files

---

# 📊 Current Features

- OCR → PaddleOCR
- Online structuring → Gemini
- Item categorization
- Category aggregation
- Anomaly detection (Isolation Forest)
- Budget alerts
- Firestore-ready structure

---

# 👨‍💻 Built With

- FastAPI
- PaddleOCR
- Gemini API
- Scikit-learn
- Flutter
- Firebase (planned)

---

# 🧠 Notes

This project supports:
- Online mode (Gemini)
- Offline-ready architecture (future MiniLM ONNX)
- Scalable analytics layer
- Multi-user Firestore design

---

# 🚀 Ready To Build

Backend is stable.
Frontend can now integrate API.
Analytics & database modules can be extended independently.