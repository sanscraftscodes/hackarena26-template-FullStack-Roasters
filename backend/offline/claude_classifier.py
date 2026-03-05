"""
India-specific Product Classifier  v2
=======================================
Classifies product / expense names into:
    Food · Grocery · Utilities · Travel · Entertainment
    Medical · Stationary · Household · Clothes · Selfcare · Other

Handles:
  • Proper nouns  – brand names, pharmacy chains, airlines, apps
  • Collective nouns – "sabzi", "fruits", "medicines", "stationery"
  • Vernacular / Hinglish – "dudh", "sabun", "kela", "tamatar"
  • How daily shoppers actually type – "2 kg aata", "recharge kar do",
    "crocin le aao", "veggies", "monthly ration"
  • All Indian vegetables (Hindi + English + regional)
  • All common Indian medicines (generic + brand)
  • Abbreviations, short forms, typos (dal, daal, dhal)

Usage
-----
    from product_classifier import classify, classify_batch, get_category

    classify("tamatar 1kg").category          # "Grocery"
    classify("crocin 10 tab").category        # "Medical"
    classify("recharge 299").category         # "Utilities"
    classify("sabzi lao").category            # "Grocery"
    classify("medicines").category            # "Medical"
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Optional

# ─────────────────────────────────────────────────────────────────────────────
# Result dataclass
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class ClassifierResult:
    product: str
    category: str
    confidence: str           # "high" | "medium" | "low"
    method: str               # "exact_brand" | "keyword" | "pattern" | "collective" | "ai" | "default"
    matched_keyword: Optional[str] = None


# ─────────────────────────────────────────────────────────────────────────────
# COLLECTIVE / GENERIC nouns  → instant high-confidence mapping
# These are what shoppers write when they don't bother with specifics
# ─────────────────────────────────────────────────────────────────────────────

COLLECTIVE_NOUNS: dict[str, str] = {
    # Grocery collectives
    "grocery": "Grocery",
    "groceries": "Grocery",
    "kirana": "Grocery",
    "kiryana": "Grocery",
    "ration": "Grocery",
    "monthly ration": "Grocery",
    "provisions": "Grocery",
    "provision store": "Grocery",
    "staples": "Grocery",
    "daily needs": "Grocery",
    "household ration": "Grocery",
    "masala": "Grocery",
    "masale": "Grocery",
    "spices": "Grocery",
    "dal": "Grocery",
    "daal": "Grocery",
    "dhal": "Grocery",
    "pulses": "Grocery",
    "lentils": "Grocery",
    "cereals": "Grocery",
    "grains": "Grocery",
    "anaj": "Grocery",
    "aata": "Grocery",
    "atta": "Grocery",
    "flour": "Grocery",
    "rice": "Grocery",
    "chawal": "Grocery",
    "oil": "Grocery",
    "tel": "Grocery",
    "ghee": "Grocery",
    "milk": "Grocery",
    "dudh": "Grocery",
    "dairy": "Grocery",
    "eggs": "Grocery",
    "anda": "Grocery",
    "ande": "Grocery",
    "dry fruits": "Grocery",
    "mewa": "Grocery",
    "nuts": "Grocery",
    "snacks": "Grocery",
    "namkeen": "Grocery",
    "biscuits": "Grocery",
    "biscuit": "Grocery",

    # Vegetables (collective)
    "sabzi": "Grocery",
    "sabziya": "Grocery",
    "sabziyaan": "Grocery",
    "vegetables": "Grocery",
    "veggies": "Grocery",
    "greens": "Grocery",
    "hare sabzi": "Grocery",
    "tarkari": "Grocery",
    "bhaji": "Grocery",           # bhaji = veg in Marathi context
    "subzi": "Grocery",

    # Fruits (collective)
    "fruits": "Grocery",
    "phal": "Grocery",
    "phalon": "Grocery",
    "seasonal fruits": "Grocery",
    "mixed fruits": "Grocery",

    # Food collectives — only clear food-intent phrases, not bare meal times
    # (bare "lunch"/"dinner" removed: "dal for dinner" should map to Grocery via dal)
    "food": "Food",
    "khana": "Food",
    "khaana": "Food",
    "khaane": "Food",
    "meal": "Food",
    "meals": "Food",
    "nashta": "Food",
    "naashta": "Food",
    "tiffin": "Food",
    "khana order": "Food",
    "food order": "Food",
    "order kiya": "Food",

    # Medicine collectives
    "medicine": "Medical",
    "medicines": "Medical",
    "dawa": "Medical",
    "dawai": "Medical",
    "davaai": "Medical",
    "davakhana": "Medical",
    "dawakhana": "Medical",
    "pharmacy": "Medical",
    "chemist": "Medical",
    "medical store": "Medical",
    "tablets": "Medical",
    "tablet": "Medical",
    "capsule": "Medical",
    "capsules": "Medical",
    "syrup": "Medical",
    "injection": "Medical",
    "doctor": "Medical",
    "doctor fee": "Medical",
    "doctor visit": "Medical",
    "hospital": "Medical",
    "clinic": "Medical",
    "test": "Medical",
    "lab test": "Medical",
    "blood test": "Medical",
    "checkup": "Medical",
    "check up": "Medical",

    # Stationery collectives
    "stationery": "Stationary",
    "stationary": "Stationary",
    "office supplies": "Stationary",
    "school supplies": "Stationary",
    "school stuff": "Stationary",
    "books": "Stationary",
    "copies": "Stationary",
    "pens": "Stationary",
    "pencils": "Stationary",

    # Clothes collectives
    "clothes": "Clothes",
    "clothing": "Clothes",
    "garments": "Clothes",
    "kapde": "Clothes",
    "kapda": "Clothes",
    "kpadein": "Clothes",
    "dress": "Clothes",
    "dresses": "Clothes",
    "outfit": "Clothes",
    "outfits": "Clothes",
    "footwear": "Clothes",
    "shoes": "Clothes",
    "chappals": "Clothes",
    "uniform": "Clothes",
    "dry cleaning": "Clothes",
    "dry clean": "Clothes",
    "ironing": "Clothes",

    # Selfcare collectives
    "toiletries": "Selfcare",
    "personal care": "Selfcare",
    "beauty": "Selfcare",
    "makeup": "Selfcare",
    "cosmetics": "Selfcare",
    "skincare": "Selfcare",
    "skin care": "Selfcare",
    "haircare": "Selfcare",
    "hair care": "Selfcare",
    "grooming": "Selfcare",
    "salon": "Selfcare",
    "parlour": "Selfcare",
    "parlor": "Selfcare",
    "sanitary pads": "Selfcare",
    "sanitary pad": "Selfcare",
    "whisper pad": "Selfcare",

    # Household collectives
    "household": "Household",
    "cleaning": "Household",
    "cleaning supplies": "Household",
    "home stuff": "Household",
    "ghar ka saman": "Household",
    "pooja samagri": "Household",
    "pooja items": "Household",
    "puja samagri": "Household",
    "detergent": "Household",
    "utensils": "Household",
    "bartan": "Household",

    # Utilities collectives
    "bills": "Utilities",
    "bill": "Utilities",
    "recharge": "Utilities",
    "top up": "Utilities",
    "topup": "Utilities",
    "subscription": "Utilities",      # overridden by entertainment brands below
    "maintenance": "Utilities",

    # Travel collectives
    "travel": "Travel",
    "trip": "Travel",
    "tour": "Travel",
    "cab": "Travel",
    "ride": "Travel",
    "petrol": "Travel",
    "diesel": "Travel",
    "fuel": "Travel",
    "ticket": "Travel",
    "tickets": "Travel",
    "toll": "Travel",
    "parking": "Travel",

    # Entertainment collectives
    "entertainment": "Entertainment",
    "movie": "Entertainment",
    "movies": "Entertainment",
    "film": "Entertainment",
    "concert": "Entertainment",
    "game": "Entertainment",
    "games": "Entertainment",
    "gaming": "Entertainment",
    "outing": "Entertainment",
    "ipl ticket": "Entertainment",
    "cricket ticket": "Entertainment",
    "concert ticket": "Entertainment",
    "event ticket": "Entertainment",
    "zoo ticket": "Entertainment",
    "movie ticket": "Entertainment",
    "film ticket": "Entertainment",
    "museum ticket": "Entertainment",
    "amusement park ticket": "Entertainment",
    "ott subscription": "Entertainment",
    "streaming subscription": "Entertainment",
}


# ─────────────────────────────────────────────────────────────────────────────
# CONTEXT MODIFIERS
# Compound phrases where a trailing/leading word shifts the category.
# Checked before brand/keyword so "face cream" → Selfcare, not Grocery.
# Rule: longest match wins, same as other layers.
# ─────────────────────────────────────────────────────────────────────────────

CONTEXT_OVERRIDES: list[tuple[str, str]] = [
    # ── Raw ingredient used in food context → Food ───────────────────────────
    # "<ingredient> + cooked-food-word" patterns handled by Food keywords below.
    # These explicit entries cover the most common combos.

    # Cooked rice dishes
    ("curd rice",        "Food"),
    ("tomato rice",      "Food"),
    ("dal rice",         "Food"),
    ("egg rice",         "Food"),
    ("chicken rice",     "Food"),
    ("lemon rice",       "Food"),
    ("coconut rice",     "Food"),
    ("tamarind rice",    "Food"),
    ("fried rice",       "Food"),
    ("biryani rice",     "Food"),
    ("jeera rice",       "Food"),

    # Cooked egg forms
    ("egg bhurji",       "Food"),
    ("egg curry",        "Food"),
    ("egg fry",          "Food"),
    ("boiled egg",       "Food"),
    ("fried egg",        "Food"),
    ("egg toast",        "Food"),
    ("egg sandwich",     "Food"),
    ("omelette",         "Food"),
    ("omellet",          "Food"),

    # Cooked bread/roti forms
    ("bread toast",      "Food"),
    ("butter toast",     "Food"),
    ("bread omelette",   "Food"),
    ("bread pakoda",     "Food"),
    ("french toast",     "Food"),
    ("butter naan",      "Food"),
    ("garlic naan",      "Food"),

    # Cooked paneer forms → handled already by keyword but adding a few combos
    ("paneer roll",      "Food"),
    ("paneer wrap",      "Food"),
    ("paneer paratha",   "Food"),

    # Capsicum in cooked context
    ("capsicum fry",     "Food"),
    ("capsicum rice",    "Food"),
    ("capsicum sabzi",   "Food"),

    # Cream in food context
    ("cream roll",       "Food"),
    ("cream cake",       "Food"),
    ("whipped cream",    "Food"),
    ("ice cream",        "Food"),
    ("cream biscuit",    "Grocery"),  # packaged product = grocery

    # Chocolate in food context
    ("chocolate cake",   "Food"),
    ("chocolate ice cream", "Food"),
    ("chocolate pastry", "Food"),
    ("chocolate shake",  "Food"),
    ("chocolate milk",   "Grocery"),

    # Cake in food/shop context
    ("birthday cake",    "Food"),
    ("cake shop",        "Food"),
    ("bakery cake",      "Food"),
    ("cake slice",       "Food"),
    ("cake piece",       "Food"),
    ("cake mix",         "Grocery"),   # dry mix = grocery

    # ── Oil context ──────────────────────────────────────────────────────────
    ("hair oil",          "Selfcare"),
    ("coconut oil for hair", "Selfcare"),
    ("oil for hair",      "Selfcare"),
    ("massage oil",       "Selfcare"),
    ("baby oil",          "Selfcare"),
    ("body oil",          "Selfcare"),
    ("essential oil",     "Selfcare"),
    ("oil for skin",      "Selfcare"),

    # ── Cream context ────────────────────────────────────────────────────────
    ("face cream",        "Selfcare"),
    ("cold cream",        "Selfcare"),
    ("body cream",        "Selfcare"),
    ("night cream",       "Selfcare"),
    ("fairness cream",    "Selfcare"),
    ("eye cream",         "Selfcare"),
    ("hand cream",        "Selfcare"),
    ("foot cream",        "Selfcare"),
    ("skin cream",        "Selfcare"),
    ("baby cream",        "Selfcare"),
    ("sunscreen cream",   "Selfcare"),
    ("bleach cream",      "Selfcare"),

    # ── Soap context ─────────────────────────────────────────────────────────
    ("bath soap",         "Selfcare"),
    ("toilet soap",       "Selfcare"),
    ("body soap",         "Selfcare"),
    ("hand soap",         "Selfcare"),
    ("dettol soap",       "Selfcare"),
    ("lifebuoy soap",     "Selfcare"),
    ("neem soap",         "Selfcare"),
    ("herbal soap",       "Selfcare"),
    ("bathing soap",      "Selfcare"),
    ("sabun",             "Selfcare"),
    ("naha ne wala sabun","Selfcare"),
    ("kapdon ka sabun",   "Household"),  # laundry soap
    ("laundry soap",      "Household"),
    ("washing soap",      "Household"),
    ("bartan sabun",      "Household"),  # utensil soap
    ("kapdon ka soap",    "Household"),

    # ── Tablet / strip / capsule – NON-medicine contexts ─────────────────────
    ("tablet stand",      "Household"),
    ("tablet holder",     "Household"),
    ("tablet case",       "Household"),
    ("tablet cover",      "Household"),
    ("strip light",       "Household"),
    ("led strip",         "Household"),
    ("strip lights",      "Household"),
    ("syrup bottle",      "Household"),
    ("empty bottle",      "Household"),
    ("plastic bottle",    "Household"),

    # ── Subscription context ─────────────────────────────────────────────────
    ("prime subscription",    "Entertainment"),
    ("prime video subscription","Entertainment"),
    ("ott subscription",      "Entertainment"),
    ("streaming subscription","Entertainment"),
    ("music subscription",    "Entertainment"),
    ("gym subscription",      "Selfcare"),
    ("fitness subscription",  "Selfcare"),
    ("yoga subscription",     "Selfcare"),

    # ── Expenses / bills collectives ─────────────────────────────────────────
    ("medical expenses",      "Medical"),
    ("medical bills",         "Medical"),
    ("medical cost",          "Medical"),
    ("electricity payment",   "Utilities"),
    ("electricity charges",   "Utilities"),
    ("bijli payment",         "Utilities"),
    ("water payment",         "Utilities"),
    ("gas payment",           "Utilities"),

    # ── Baby food ────────────────────────────────────────────────────────────
    ("baby food",             "Grocery"),
    ("baby formula",          "Grocery"),
    ("infant formula",        "Grocery"),
    ("cerelac",               "Grocery"),
    ("lactogen",              "Grocery"),
    ("nan pro",               "Grocery"),
    ("farex",                 "Grocery"),

    # ── Dettol context ───────────────────────────────────────────────────────
    ("dettol liquid",         "Household"),   # antiseptic/floor
    ("dettol floor",          "Household"),
    ("dettol spray",          "Household"),
    ("dettol handwash",       "Selfcare"),

    # ── Cab / auto false positives ───────────────────────────────────────────
    ("cab file",              "Other"),
    ("cab format",            "Other"),
    ("auto parts",            "Other"),
    ("auto component",        "Other"),
    ("auto ancillary",        "Other"),
    ("auto industry",         "Other"),

    # ── Hindi context phrases ─────────────────────────────────────────────────
    ("ghar ki safai",         "Household"),
    ("ghar ka saman",         "Household"),
    ("safai saman",           "Household"),
    ("ghar ke liye sabun",    "Selfcare"),
    ("naha ne",               "Selfcare"),
    ("chai piya",             "Food"),
    ("chai peena",            "Food"),

    # ── Hand wash ────────────────────────────────────────────────────────────
    ("hand wash",             "Selfcare"),
    ("handwash",              "Selfcare"),
    ("hand wash pump",        "Selfcare"),
    ("hand sanitizer",        "Selfcare"),

    # ── Glucose / supplements ────────────────────────────────────────────────
    ("glucose powder",        "Medical"),
    ("glucose biscuit",       "Grocery"),
    ("glucose drink",         "Grocery"),
    ("glucose water",         "Medical"),

    # ── Rose / aloe ──────────────────────────────────────────────────────────
    ("rose water",            "Selfcare"),
    ("gulab jal",             "Selfcare"),
    ("aloe vera gel",         "Selfcare"),
    ("aloe vera juice",       "Grocery"),
    ("aloe vera drink",       "Grocery"),

    # ── Chai / coffee standalone ─────────────────────────────────────────────
    ("chai",                  "Food"),
    ("rs 50 chai",            "Food"),
    ("1 chai",                "Food"),
    ("2 chai",                "Food"),
    ("ek chai",               "Food"),
    ("do chai",               "Food"),
    ("cold coffee",           "Food"),
    ("hot coffee",            "Food"),
    ("filter coffee",         "Food"),
]


# ─────────────────────────────────────────────────────────────────────────────
# BRAND OVERRIDES  (exact / substring → category, always high confidence)
# ─────────────────────────────────────────────────────────────────────────────

BRAND_OVERRIDES: dict[str, str] = {
    # ── Grocery brands ──────────────────────────────────────────────────────
    "aashirvaad": "Grocery", "fortune": "Grocery", "saffola": "Grocery",
    "tata salt": "Grocery", "catch spice": "Grocery", "mdh": "Grocery",
    "everest masala": "Grocery", "everest": "Grocery", "sunrise": "Grocery",
    "badshah masala": "Grocery", "ramdev": "Grocery",
    "amul": "Grocery", "mother dairy": "Grocery", "nandini": "Grocery",
    "aavin": "Grocery", "milkfed": "Grocery", "parag": "Grocery",
    "haldiram": "Grocery", "bikaji": "Grocery", "balaji wafers": "Grocery",
    "uncle chips": "Grocery", "parle g": "Grocery", "parle": "Grocery",
    "britannia": "Grocery", "sunfeast": "Grocery", "priyagold": "Grocery",
    "maggi": "Grocery", "yippee": "Grocery", "knorr": "Grocery",
    "kissan": "Grocery", "dabur honey": "Grocery", "patanjali": "Grocery",
    "tata tea": "Grocery", "red label": "Grocery", "taaza": "Grocery",
    "brooke bond": "Grocery", "lipton": "Grocery", "wagh bakri": "Grocery",
    "society tea": "Grocery", "taj mahal tea": "Grocery",
    "nescafe": "Grocery", "bru": "Grocery", "moccona": "Grocery",
    "horlicks": "Grocery", "bournvita": "Grocery", "complan": "Grocery",
    "boost": "Grocery", "milo": "Grocery", "ovaltine": "Grocery",
    "maida": "Grocery", "besan": "Grocery",
    "lays": "Grocery", "kurkure": "Grocery", "bingo": "Grocery",
    "roohafza": "Grocery", "rasna": "Grocery", "tang": "Grocery",
    "paper boat": "Grocery",

    # ── Food / delivery ──────────────────────────────────────────────────────
    "swiggy": "Food", "zomato": "Food", "eatsure": "Food",
    "mcdonald": "Food", "mcdonalds": "Food", "kfc": "Food",
    "dominos": "Food", "domino": "Food", "pizza hut": "Food",
    "subway": "Food", "burger king": "Food", "wendy": "Food",
    "barbeque nation": "Food", "barbeque": "Food",
    "cafe coffee day": "Food", "ccd": "Food", "barista": "Food",
    "starbucks": "Food", "chaayos": "Food", "chai point": "Food",
    "theobroma": "Food", "wow momo": "Food",
    "faasos": "Food", "box8": "Food", "freshmenu": "Food",

    # ── Utilities ────────────────────────────────────────────────────────────
    "msedcl": "Utilities", "bescom": "Utilities", "tneb": "Utilities",
    "cesc": "Utilities", "bses": "Utilities", "tata power": "Utilities",
    "adani electricity": "Utilities", "adani gas": "Utilities",
    "mahanagar gas": "Utilities", "mgl": "Utilities",
    "igl": "Utilities", "indane": "Utilities", "bharat gas": "Utilities",
    "hp gas": "Utilities", "hp cylinder": "Utilities",
    "jio fiber": "Utilities", "jio broadband": "Utilities",
    "airtel broadband": "Utilities", "bsnl broadband": "Utilities",
    "act fibernet": "Utilities", "hathway": "Utilities",
    "jio recharge": "Utilities", "airtel recharge": "Utilities",
    "vi recharge": "Utilities", "vodafone recharge": "Utilities",    "bsnl recharge": "Utilities", "idea recharge": "Utilities",
    "tata play": "Utilities", "tata sky": "Utilities",
    "dish tv": "Utilities", "sun direct": "Utilities", "d2h": "Utilities",
    "videocon d2h": "Utilities",

    # ── Travel ───────────────────────────────────────────────────────────────
    "ola": "Travel", "uber": "Travel", "rapido": "Travel", "meru": "Travel",
    "blablacar": "Travel",
    "irctc": "Travel", "makemytrip": "Travel", "goibibo": "Travel",
    "yatra": "Travel", "cleartrip": "Travel", "ixigo": "Travel",
    "indigo": "Travel", "air india": "Travel", "spicejet": "Travel",
    "akasa": "Travel", "vistara": "Travel", "air asia": "Travel",
    "go first": "Travel",
    "oyo": "Travel", "treebo": "Travel", "fabhotels": "Travel",
    "zostel": "Travel", "mmt": "Travel",
    "fastag": "Travel", "paytm fastag": "Travel",
    "msrtc": "Travel", "ksrtc": "Travel", "apsrtc": "Travel",
    "tsrtc": "Travel", "gsrtc": "Travel", "bmtc": "Travel",
    "best bus": "Travel",
    "iocl": "Travel", "bharat petroleum": "Travel", "indian oil": "Travel",
    "hp petrol": "Travel", "essar fuel": "Travel",

    # ── Entertainment ────────────────────────────────────────────────────────
    "netflix": "Entertainment", "hotstar": "Entertainment",
    "disney+": "Entertainment", "disney plus": "Entertainment",
    "amazon prime": "Entertainment", "prime video": "Entertainment",
    "sony liv": "Entertainment", "sonyliv": "Entertainment",
    "zee5": "Entertainment", "voot": "Entertainment",
    "alt balaji": "Entertainment", "altbalaji": "Entertainment",
    "mx player": "Entertainment", "jio cinema": "Entertainment",
    "jiocinema": "Entertainment", "hoichoi": "Entertainment",
    "aha": "Entertainment", "sun nxt": "Entertainment",
    "youtube premium": "Entertainment",
    "spotify": "Entertainment", "gaana": "Entertainment",
    "jiosaavn": "Entertainment", "wynk": "Entertainment",
    "apple music": "Entertainment", "hungama": "Entertainment",
    "pvr": "Entertainment", "inox": "Entertainment",
    "cinepolis": "Entertainment", "carnival cinemas": "Entertainment",
    "bookmyshow": "Entertainment", "book my show": "Entertainment",
    "playstation": "Entertainment", "xbox": "Entertainment",
    "steam": "Entertainment", "paytm games": "Entertainment",

    # ── Medical ──────────────────────────────────────────────────────────────
    "apollo pharmacy": "Medical", "apollo hospital": "Medical",
    "apollo": "Medical", "medplus": "Medical",
    "1mg": "Medical", "netmeds": "Medical", "pharmeasy": "Medical",
    "tata 1mg": "Medical", "healthkart": "Medical",
    "max hospital": "Medical", "fortis": "Medical",
    "manipal hospital": "Medical", "aiims": "Medical",
    "narayana health": "Medical",

    # ── Clothes ──────────────────────────────────────────────────────────────
    "myntra": "Clothes", "ajio": "Clothes", "tata cliq fashion": "Clothes",
    "zara": "Clothes", "h&m": "Clothes", "uniqlo": "Clothes",
    "fabindia": "Clothes", "biba": "Clothes", "w for woman": "Clothes",
    "global desi": "Clothes", "anouk": "Clothes",
    "pantaloons": "Clothes", "westside": "Clothes",
    "shoppers stop": "Clothes", "lifestyle": "Clothes",
    "max fashion": "Clothes", "v mart": "Clothes",
    "bata": "Clothes", "liberty shoes": "Clothes",
    "woodland": "Clothes", "red tape": "Clothes",
    "action shoes": "Clothes", "paragon": "Clothes",
    "peter england": "Clothes", "louis philippe": "Clothes",
    "van heusen": "Clothes", "allen solly": "Clothes",
    "arrow": "Clothes", "raymond": "Clothes",
    "adidas": "Clothes", "nike": "Clothes", "puma": "Clothes",
    "reebok": "Clothes", "fila": "Clothes", "skechers": "Clothes",
    "levis": "Clothes", "wrangler": "Clothes", "lee": "Clothes",
    "spykar": "Clothes", "pepe jeans": "Clothes",

    # ── Selfcare ─────────────────────────────────────────────────────────────
    "nykaa": "Selfcare", "purplle": "Selfcare", "sugar cosmetics": "Selfcare",
    "mamaearth": "Selfcare", "wow skin": "Selfcare",
    "loreal": "Selfcare", "garnier": "Selfcare", "maybelline": "Selfcare",
    "lakme": "Selfcare", "colorbar": "Selfcare", "faces canada": "Selfcare",
    "lotus herbals": "Selfcare", "biotique": "Selfcare",
    "himalaya herbals": "Selfcare", "jovees": "Selfcare",
    "forest essentials": "Selfcare", "kama ayurveda": "Selfcare",
    "gillette": "Selfcare", "veet": "Selfcare", "anne french": "Selfcare",
    "johnson": "Selfcare", "johnsons baby": "Selfcare",
    "colgate": "Selfcare", "pepsodent": "Selfcare", "closeup": "Selfcare",
    "sensodyne": "Selfcare", "oral b": "Selfcare", "hul": "Selfcare",
    "whisper": "Selfcare", "stayfree": "Selfcare", "sofy": "Selfcare",
    "carefree pad": "Selfcare",

    # ── Household ────────────────────────────────────────────────────────────
    "surf excel": "Household", "ariel": "Household", "tide": "Household",
    "rin": "Household", "nirma": "Household", "ghari": "Household",
    "wheel detergent": "Household", "fena": "Household",
    "vim": "Household", "pril": "Household", "exo": "Household",
    "harpic": "Household", "domex": "Household", "lizol": "Household",
    "dettol": "Household", "savlon": "Household",
    "godrej": "Household",
    "colin": "Household", "mr muscle": "Household",
    "good knight": "Household", "allout": "Household",
    "mortein": "Household", "hit spray": "Household",
    "baygon": "Household", "odonil": "Household",
    "ezee": "Household", "comfort fabric": "Household",
    "scotch brite": "Household", "jyoti": "Household",
}


# ─────────────────────────────────────────────────────────────────────────────
# KEYWORD DATABASE  – organised by category, very comprehensive
# ─────────────────────────────────────────────────────────────────────────────

CATEGORY_KEYWORDS: dict[str, list[str]] = {

    # ════════════════════════════════════════════════════════════════════════
    # GROCERY
    # ════════════════════════════════════════════════════════════════════════
    "Grocery": [

        # ── Dals / Pulses (all spellings + Hindi names) ──────────────────────
        "toor dal", "tuvar dal", "arhar dal", "arhar",
        "moong dal", "mung dal", "green gram",
        "urad dal", "urad", "black gram", "black lentil",
        "chana dal", "chana",
        "masoor dal", "masur dal", "red lentil",
        "rajma", "kidney bean",
        "lobia", "lobhia", "black eyed pea", "cowpea",
        "moth dal", "moth bean", "matki",
        "kulthi dal", "horse gram", "hurali",
        "val dal", "field bean",
        "chawli", "karamani",
        "green moong", "whole moong", "sabut moong",
        "sabut masoor", "whole masoor",
        "kali dal", "whole urad",
        "chhole", "kabuli chana", "chickpea",
        "peas", "matar",
        "vatana",
        "dal makhani", "panchmel dal", "mixed dal",
        "daal", "dhal",                              # alternate spellings

        # ── Rice & Grains ────────────────────────────────────────────────────
        "basmati", "sona masoori", "sona masuri", "kolam rice",
        "parboiled rice", "ponni rice", "idli rice", "raw rice",
        "brown rice", "red rice", "black rice", "surti kolam",
        "gobindobhog", "dehraduni basmati", "pusa basmati",
        "chawal", "bhat",
        "jowar", "sorghum", "bajra", "millet", "pearl millet",
        "ragi", "finger millet", "nachni",
        "makka atta", "corn flour", "maize flour",
        "poha", "beaten rice", "chivda",
        "sabudana", "sago", "tapioca",
        "quinoa", "oats", "rolled oats", "dalia", "broken wheat",
        "wheat", "gehu",
        "barley", "jau",
        "kuttu", "buckwheat", "singhada", "water chestnut",
        "amaranth", "rajgira",

        # ── Atta & Flour ─────────────────────────────────────────────────────
        "atta", "aata", "wheat flour", "chakki atta", "multigrain atta",
        "maida", "all purpose flour",
        "besan", "gram flour", "chickpea flour",
        "suji", "sooji", "semolina", "rava",
        "rice flour", "chawal ka atta",
        "corn starch", "arrowroot",
        "ragi flour", "bajra flour", "jowar flour",
        "kuttu atta", "singhara atta",

        # ── Oils & Ghee ──────────────────────────────────────────────────────
        "sunflower oil", "sarso oil", "mustard oil", "kadugu ennai",
        "groundnut oil", "moongfali oil", "peanut oil",
        "coconut oil", "copra oil", "nariyal tel",
        "refined oil", "til oil", "sesame oil", "gingelly oil",
        "soybean oil", "canola oil", "palm oil", "rice bran oil",
        "vanaspati", "dalda", "hydrogenated fat",
        "ghee", "desi ghee", "cow ghee", "buffalo ghee",
        "butter oil",

        # ── Spices & Masalas ─────────────────────────────────────────────────
        "jeera", "cumin", "zeera",
        "dhania", "coriander powder", "sukha dhania",
        "haldi", "turmeric", "pasupu",
        "mirchi", "lal mirch", "red chilli", "chilli powder", "tikha",
        "green chilli", "hari mirch", "pachcha mirchi",
        "garam masala", "chai masala",
        "pav bhaji masala", "biryani masala", "biryani mix",
        "chhole masala", "rajma masala",
        "sambar powder", "rasam powder", "bisi bele bath powder",
        "kitchen king masala", "meat masala", "fish masala",
        "egg masala", "chicken masala", "mutton masala",
        "kashmiri mirch", "deggi mirch",
        "amchur", "dry mango powder",
        "hing", "asafoetida", "perungayam",
        "methi seeds", "fenugreek", "methi dana",
        "ajwain", "carom seeds", "omam",
        "kalonji", "nigella seeds", "onion seeds",
        "saunf", "fennel seeds", "variyali",
        "elaichi", "cardamom", "ilaichi",
        "laung", "cloves", "lavang",
        "dalchini", "cinnamon", "ilayangai",
        "tejpatta", "bay leaf", "malabar leaf",
        "star anise", "chakri phool", "biryani flower",
        "jaiphal", "nutmeg",
        "javitri", "mace",
        "kesar", "saffron", "zafran",
        "kali mirch", "black pepper", "milagu",
        "white pepper",
        "tamarind", "imli", "puli",
        "kokum", "amsul",
        "curry leaves", "kadi patta", "meetha neem",
        "kasuri methi", "dried fenugreek",
        "anardana", "pomegranate seeds",
        "chaat masala",

        # ── Salt & Sugar ─────────────────────────────────────────────────────
        "namak", "salt", "iodised salt",
        "sendha namak", "rock salt", "saindha",
        "black salt", "kala namak",
        "chini", "sugar", "shakkar", "bura sugar",
        "jaggery", "gud", "gur", "bellam", "vellam",
        "mishri", "khand", "brown sugar",
        "stevia", "sugar free tablet",

        # ── Tea Coffee Beverages (packaged / raw) ────────────────────────────
        "chai patti", "tea leaves", "green tea", "black tea",
        "masala chai", "tulsi tea", "ginger tea", "lemon tea",
        "herbal tea", "chamomile",
        "coffee powder", "instant coffee", "filter coffee",
        "chicory", "coffee decoction",
        "cocoa", "drinking chocolate",

        # ── Dairy / Eggs ─────────────────────────────────────────────────────
        "milk packet", "toned milk", "full cream milk", "skimmed milk",
        "cow milk", "buffalo milk", "goat milk",
        "paneer", "cottage cheese",
        "curd", "dahi", "yogurt",
        "buttermilk", "chaas", "mattha",
        "butter", "makhan", "white butter",
        "cheese", "processed cheese", "cheese slice",
        "cream", "malai", "heavy cream",
        "condensed milk", "milkmaid",
        "khoya", "mawa", "khoa",
        "milk powder", "whole milk powder",
        "egg", "anda", "hen egg", "duck egg",

        # ── Vegetables – English ─────────────────────────────────────────────
        "tomato", "potato", "onion", "garlic", "ginger",
        "carrot", "peas", "cauliflower", "cabbage", "broccoli",
        "capsicum", "green capsicum", "red capsicum", "yellow capsicum",
        "spinach", "palak", "fenugreek leaves", "methi",
        "coriander leaves", "dhaniya patta", "mint", "pudina",
        "bottle gourd", "lauki", "dudhi",
        "ridge gourd", "turai", "torai",
        "bitter gourd", "karela",
        "pointed gourd", "parwal", "potol",
        "snake gourd", "chichinda",
        "ash gourd", "petha",
        "pumpkin", "kaddu", "kashi phal",
        "beetroot", "chukandar",
        "radish", "mooli", "mullangi",
        "turnip", "shalgam",
        "sweet potato", "shakarkandi",
        "yam", "suran", "jimikand",
        "taro", "arbi", "colocasia",
        "raw banana", "kaccha kela",
        "raw papaya", "kaccha papita",
        "raw mango", "kacchi aam",
        "jackfruit", "kathal",
        "drumstick", "sahjan", "murungai",
        "cluster beans", "gawar phali", "guar",
        "french beans", "beans", "green beans",
        "broad beans", "sem",
        "lady finger", "bhindi", "okra",
        "brinjal", "baingan", "eggplant",
        "cucumber", "kheera", "kakdi",
        "zucchini", "courgette",
        "mushroom", "khumb",
        "spring onion", "hara pyaz",
        "leek", "lotus stem", "kamal kakdi",
        "raw turmeric", "kachi haldi",
        "celery", "lettuce", "iceberg", "kale",
        "baby corn", "sweet corn",
        "avocado",
        "cherry tomato",

        # ── Vegetables – Hindi / vernacular ──────────────────────────────────
        "tamatar", "aloo", "pyaz", "lehsun", "adrak",
        "gajar", "matar", "gobhi", "phool gobhi", "band gobhi",
        "shimla mirch",
        "palak", "methi patta", "pudina", "dhania",
        "lauki", "turai", "karela", "parwal", "chichinda",
        "kaddu", "petha", "beetroot", "chukandar",
        "mooli", "shalgam", "shakarkandi",
        "arbi", "suran", "kela",
        "kathal", "sahjan",
        "gawar", "sem phali", "bhindi", "baingan",
        "kheera", "tinda",
        "hara pyaz", "kamal kakdi",

        # ── Fruits – English ─────────────────────────────────────────────────
        "mango", "banana", "apple", "orange", "papaya",
        "guava", "pomegranate", "watermelon", "muskmelon",
        "grapes", "pineapple", "strawberry",
        "litchi", "lychee", "chikoo", "sapota",
        "kiwi", "pear", "plum", "peach",
        "cherry", "apricot", "fig", "dates",
        "coconut", "tender coconut", "lime", "lemon",
        "sweet lime", "grapefruit", "passion fruit",
        "dragon fruit", "jackfruit ripe",
        "custard apple", "sitaphal",
        "wood apple", "bael",
        "gooseberry", "amla",

        # ── Fruits – Hindi / vernacular ──────────────────────────────────────
        "aam", "kela", "seb", "santra", "narangi", "papita",
        "amrood", "anaar", "tarbooj", "kharbooja",
        "angoor", "ananas", "strawberry",
        "lichi", "chiku", "nashpati", "aloo bukhara",
        "nariyal", "nimbu", "mosambi", "anar",

        # ── Packaged Staples ──────────────────────────────────────────────────
        "bread", "white bread", "whole wheat bread", "multigrain bread",
        "pav", "dinner roll",
        "toast", "rusk",
        "pasta", "macaroni", "penne", "spaghetti", "fusilli",
        "vermicelli", "sewai",
        "noodles", "ramen",
        "upma mix", "idli mix", "dosa mix", "dhokla mix",
        "gulab jamun mix", "halwa mix",
        "jam", "strawberry jam", "mixed fruit jam",
        "pickle", "achar", "murabba",
        "chutney", "tomato sauce", "tomato ketchup",
        "soy sauce", "vinegar", "mayonnaise", "mustard sauce",
        "peanut butter", "honey", "maple syrup", "chocolate spread",
        "chocolate", "dark chocolate", "milk chocolate", "chocolate bar",
        "candy", "toffee", "eclairs", "dairy milk", "kit kat",
        "cola", "soft drink", "cold drink", "aerated drink",
        "pepsi", "coca cola", "fanta", "sprite", "limca",
        "thums up", "maaza", "frooti", "slice mango",
        "energy drink", "red bull",
        "cake", "pastry", "muffin", "brownie", "cookie",
        "cupcake", "doughnut", "donut",

        # ── Dry Fruits / Nuts ─────────────────────────────────────────────────
        "kaju", "cashew", "badam", "almond", "pista", "pistachio",
        "akhrot", "walnut", "kishmish", "raisin",
        "khajoor", "dates", "dates pack",
        "anjeer", "fig", "apricot", "khumani",
        "makhana", "fox nut", "phool makhana",
        "chironji", "charoli",
        "pine nut", "chilgoza",
        "macadamia", "pecan",

        # ── Snacks ───────────────────────────────────────────────────────────
        "namkeen", "chakli", "sev", "bhujia", "mixture", "farsan",
        "mathri", "popcorn", "chips",
        "roasted chana", "murmura", "puffed rice",
        "papad", "pappad", "appalam", "fryums",
        "moong dal namkeen", "aloo bhujia",
        "instant mix",

        # ── Baking ───────────────────────────────────────────────────────────
        "baking powder", "baking soda", "yeast", "vanilla essence",
        "vanilla extract", "cocoa powder", "chocolate chips",
        "icing sugar", "powdered sugar", "food colour", "edible colour",
        "gelatin", "agar agar",
        # Health foods / baby foods
        "cerelac", "farex", "lactogen", "nan pro", "baby formula",
        "aloe vera juice", "aloe juice",
        "glucose biscuit", "glucose drink",
        "protein bar", "granola bar", "energy bar",
        "sports drink", "electrolyte drink",
    ],

    # ════════════════════════════════════════════════════════════════════════
    # FOOD  (cooked, restaurants, delivered, street food)
    # ════════════════════════════════════════════════════════════════════════
    "Food": [
        # Delivery apps (handled by brand overrides too)
        "food delivery", "order placed", "online order", "food app",

        # Restaurant / place types
        "restaurant", "dhaba", "udupi", "mess",
        "cafe", "cafeteria", "canteen", "tapri",
        "tiffin centre", "tiffin service", "home delivery",
        "fast food", "food court", "food stall",
        "mithai shop", "bakery", "confectionery",

        # Cooked / prepared food – North Indian
        "dal fry", "dal tadka", "dal makhani",
        "paneer butter masala", "shahi paneer", "palak paneer",
        "matar paneer", "kadhai paneer", "paneer tikka",
        "butter chicken", "chicken curry", "mutton curry",
        "chicken tikka", "chicken masala", "keema",
        "seekh kebab", "tandoori chicken", "reshmi kebab",
        "biryani", "pulao", "jeera rice", "veg biryani",
        "korma", "nihari", "haleem",
        "chole bhature", "pindi chole", "rajma chawal",
        "kadhi chawal", "baingan bharta", "dum aloo",
        "aloo gobi", "aloo matar", "mix veg",
        "naan", "tandoori roti", "laccha paratha", "missi roti",
        "roti", "chapati", "phulka", "puri", "bhatura", "paratha",
        "stuffed paratha", "aloo paratha", "gobi paratha",

        # South Indian
        "dosa", "masala dosa", "plain dosa", "rava dosa",
        "idli", "vada", "medu vada", "sambhar", "rasam",
        "uttapam", "pesarattu", "appam", "puttu",
        "pongal", "bisibelebath", "curd rice", "lemon rice",
        "tamarind rice", "coconut rice",
        "fish curry", "fish fry", "prawn curry",

        # West Indian / Maharashtra
        "pav bhaji", "vada pav", "misal pav", "usal",
        "poha", "upma", "sheera", "sabudana khichdi",
        "modak", "puran poli", "shrikhand",
        "kanda poha", "dadpe pohe",

        # Gujarati
        "dhokla", "khandvi", "thepla", "undhiyu",
        "dal dhokli", "kadhi", "fafda",

        # Street food / chaat
        "chaat", "pani puri", "golgappa", "puchka",
        "bhel puri", "sev puri", "dahi puri",
        "ragda pattice", "aloo tikki", "samosa",
        "kachori", "samosa chaat",
        "papdi chaat", "dahi bhalla", "dahi vada",
        "raj kachori", "tikki",

        # Sweets / Mithai
        "halwa", "gajar halwa", "suji halwa",
        "kheer", "payasam", "phirni",
        "ladoo", "motichoor ladoo", "besan ladoo",
        "barfi", "kaju barfi", "milk cake",
        "gulab jamun", "jalebi", "imarti",
        "rasgulla", "rasmalai", "cham cham",
        "kalakand", "peda", "churma",
        "mysore pak", "soan papdi",
        "gajar pak", "til chikki", "peanut chikki",

        # Ice cream / desserts
        "ice cream", "kulfi", "falooda", "mango kulfi",
        "sundae", "scoop",

        # Beverages (served / café)
        "cold coffee", "cappuccino", "latte", "espresso",
        "milkshake", "smoothie",
        "nimbu pani", "shikanji", "sugarcane juice", "cane juice",
        "coconut water", "jaljeera", "aam panna",
        "lassi", "buttermilk", "mattha",
        "masala chaas",

        # Meal types
        "thali", "meals", "full meals",
        "takeaway", "parcel", "packed food",
    ],

    # ════════════════════════════════════════════════════════════════════════
    # UTILITIES
    # ════════════════════════════════════════════════════════════════════════
    "Utilities": [
        # Electricity
        "electricity bill", "light bill", "bijli bill", "current bill",
        "electric bill", "power bill",
        "electricity payment", "bijli payment", "electricity charges",
        "electricity charges paid",
        # Water
        "water bill", "jal board", "water tax", "water charge", "pani bill",
        # Gas
        "gas bill", "cylinder", "gas cylinder", "lpg cylinder",
        "piped gas", "gas booking", "gas refill",
        # Mobile / internet
        "broadband", "internet bill", "wifi bill",
        "mobile recharge", "prepaid recharge", "postpaid bill",
        "mobile bill", "phone recharge", "data recharge",
        "jio", "airtel", "vodafone", "bsnl", "idea",
        # DTH / cable
        "dth recharge", "cable tv", "cable bill",
        # Society
        "maintenance charge", "society maintenance",
        "housing society", "flat maintenance",
        "property tax", "house tax", "municipal tax", "nagar palika",
        # Other
        "telephone bill", "landline", "bsnl landline",
    ],

    # ════════════════════════════════════════════════════════════════════════
    # TRAVEL
    # ════════════════════════════════════════════════════════════════════════
    "Travel": [
        # Road
        "taxi", "auto", "rickshaw", "autorickshaw", "tuk tuk",
        "cab ride", "pool ride", "bike taxi",
        "oil change", "engine oil change",
        # Bus
        "bus ticket", "bus pass", "bus stop", "volvo bus", "sleeper bus",
        "ac bus", "city bus",
        # Train
        "train ticket", "rail ticket", "railway booking",
        "platform ticket", "tatkal", "sleeper class", "ac coach",
        # Metro
        "metro card", "metro token", "smart card recharge",
        "metro pass",
        # Flight
        "flight ticket", "air ticket", "boarding pass",
        "airline ticket", "domestic flight", "international flight",
        # Hotel
        "hotel booking", "room booking", "lodge",
        # Fuel
        "cng fill", "cng charge",
        "petrol bhar", "diesel bhar",
        # Toll / parking
        "toll charge", "highway toll", "expressway toll",
        "parking fee", "parking charge", "valet",
        # Vehicle maintenance
        "car service", "bike service", "vehicle repair",
        "tyre change", "tyre puncture", "wheel alignment",
        "oil change", "engine oil", "coolant",
        "brake pad", "clutch plate",
        "vehicle insurance", "car insurance", "bike insurance",
        # Travel related
        "travel insurance", "visa fee", "visa charge",
        "passport fee", "passport renewal",
        "holiday package", "tour package",
    ],

    # ════════════════════════════════════════════════════════════════════════
    # ENTERTAINMENT
    # ════════════════════════════════════════════════════════════════════════
    "Entertainment": [
        # OTT
        "ott subscription", "ott plan",
        "streaming", "web series",
        # Cinema
        "cinema ticket", "movie ticket", "film ticket",
        "multiplex", "single screen",
        # Events
        "concert ticket", "event ticket",
        "festival ticket", "mela",
        "comedy show", "standup", "live show",
        # Gaming
        "video game", "console game", "mobile game",
        "in-app purchase", "game credit",
        "play store purchase", "app store purchase",
        # Amusement
        "amusement park", "water park", "theme park",
        "zoo ticket", "museum ticket", "aquarium",
        "laser tag", "bowling", "escape room",
        "trampoline park",
        # Music / reading
        "music subscription", "podcast subscription",
        "newspaper", "magazine subscription",
        "ebook", "audiobook",
        # Sports
        "cricket ticket", "ipl ticket", "football match",
        "sports ticket", "stadium ticket",
        # Other
        "club membership", "gym entertainment",
    ],

    # ════════════════════════════════════════════════════════════════════════
    # MEDICAL
    # ════════════════════════════════════════════════════════════════════════
    "Medical": [
        # ── Pain / Fever (very common Indian brands & generics) ──────────────
        "paracetamol", "crocin", "dolo", "dolo 650",
        "combiflam", "ibuprofen", "brufen",
        "aspirin", "disprin", "ecosprin",
        "metacin", "calpol", "p 500",
        "meftal", "mefenamic",
        "diclofenac", "voveran",
        "nimesulide", "nimulid", "nice tablet",

        # ── Antibiotics ──────────────────────────────────────────────────────
        "amoxicillin", "amoxyclav", "augmentin",
        "azithromycin", "azee", "zithromax",
        "ciprofloxacin", "cipro", "ciplox",
        "metronidazole", "flagyl", "metrogyl",
        "doxycycline", "ofloxacin",
        "cefixime", "taxim", "suprax",
        "cefpodoxime", "ceftriaxone",
        "levofloxacin", "levaquin",
        "erythromycin", "tetracycline",
        "norfloxacin", "norflox",

        # ── Allergy / Cold ───────────────────────────────────────────────────
        "cetirizine", "cetrizine", "cetzine", "alerid", "zyrtec",
        "loratadine", "clarityn",
        "fexofenadine", "allegra",
        "chlorpheniramine", "avil",
        "montelukast", "montek lc",
        "levocetrizine",
        "nasal spray", "nasivion", "otrivin", "sinarest",
        "vicks vaporub", "vicks",
        "koflet", "benadryl", "honitus",
        "alex cough", "corex",
        "d cold", "coldact",

        # ── Stomach / Digestive ──────────────────────────────────────────────
        "omeprazole", "omez", "pan d", "pantoprazole",
        "rabeprazole", "razo",
        "gelusil", "digene", "eno",
        "ranitidine", "rantac",
        "domperidone", "domstal", "motilium",
        "metoclopramide", "perinorm",
        "loperamide", "imodium",
        "syrup lactulose", "cremaffin",
        "isabgol", "psyllium husk",
        "ors", "electral", "pedialyte",
        "sucralfate", "sucral",
        "probiotics", "sporlac", "vibact",
        "antacid",

        # ── Diabetes ─────────────────────────────────────────────────────────
        "metformin", "glycomet", "glucophage",
        "glipizide", "glimperide", "amaryl",
        "sitagliptin", "januvia", "istavel",
        "dapagliflozin", "farxiga",
        "insulin", "actrapid", "humulin",
        "glucometer strip", "glucometer",
        "diabetic", "blood sugar",

        # ── BP / Heart ───────────────────────────────────────────────────────
        "amlodipine", "amlovas", "amlong",
        "atenolol", "tenormin",
        "telma", "telmisartan",
        "ramipril", "ramipres",
        "losartan", "losium",
        "enalapril", "vasotec",
        "aspirin low dose", "ecosprin 75",
        "nitroglycerin", "sorbitrate",
        "clopidogrel", "plavix",

        # ── Cholesterol ──────────────────────────────────────────────────────
        "atorvastatin", "atorva", "lipitor",
        "rosuvastatin", "rosuvas", "crestor",
        "simvastatin",
        "fenofibrate",

        # ── Thyroid ──────────────────────────────────────────────────────────
        "thyronorm", "eltroxin", "thyroxine", "levothyroxine",

        # ── Vitamins / Supplements ───────────────────────────────────────────
        "vitamin d", "vitamin d3", "calcirol",
        "vitamin c", "limcee", "celin",
        "vitamin b12", "methylcobalamin",
        "calcium tablet", "shelcal", "calcigard",
        "iron tablet", "ferrous sulphate", "autrin",
        "folic acid", "folvite",
        "zinc tablet", "zincovit",
        "multivitamin", "supradyn", "becosules", "revital",
        "omega 3", "fish oil", "flaxseed oil",
        "protein powder", "whey protein",
        "glucose powder", "dextrose powder",

        # ── Respiratory ──
        "asthalin", "salbutamol", "ventolin",
        "budesonide", "budecort",
        "montelukast",
        "theophylline",
        "levolin",

        # ── Skin / Topical ───────────────────────────────────────────────────
        "betamethasone", "betnovate",
        "clotrimazole", "candid", "candid b",
        "mupirocin", "bactroban",
        "soframycin", "neosporin",
        "calamine lotion",
        "hydrocortisone cream",

        # ── Eye / Ear ────────────────────────────────────────────────────────
        "eye drop", "genteal", "systane",
        "ear drop", "waxolve",
        "ciprofloxacin eye drop", "moxifloxacin eye",

        # ── Medical consumables ──────────────────────────────────────────────
        "bandage", "crepe bandage", "band aid", "plaster",
        "surgical tape", "cotton wool", "gauze pad",
        "antiseptic", "betadine", "savlon", "dettol liquid",
        "hydrogen peroxide",
        "thermometer", "bp machine", "nebuliser",
        "pulse oximeter", "oximeter",
        "glucometer",

        # ── Healthcare services ──────────────────────────────────────────────
        "consultation fee", "opd charges", "ipd charges",
        "doctor charges",
        "diagnostic test", "pathology test",
        "urine test", "stool test",
        "x ray", "xray", "ct scan", "mri scan",
        "ultrasound", "sonography",
        "ecg", "echo test",
        "vaccination", "vaccine", "booster dose",
        "physiotherapy", "rehab",
        "ayurveda", "ayurvedic medicine",
        "homeopathy", "homoeopathy",
        "dental", "dentist", "tooth extraction", "root canal",
        "eye test", "spectacle", "glasses", "contact lens",
        "ambulance",
        "health insurance", "mediclaim", "insurance premium",

        # ── Feminine / Baby ──────────────────────────────────────────────────
        "sanitary pad", "menstrual pad", "tampon", "menstrual cup",
        "diaper", "baby diaper",

        # ── Generic medicine phrases ──────────────────────────────────────────
        "medicine for", "tablet for", "syrup for",
        "prescribed medicine", "prescription drug",
        "strip of tablet", "tablet strip",
        "mg tablet", "ml syrup",
        "ointment", "gel tube", "cream tube",
        "capsule strip",
    ],

    # ════════════════════════════════════════════════════════════════════════
    # STATIONARY
    # ════════════════════════════════════════════════════════════════════════
    "Stationary": [
        # Writing instruments
        "pen", "ball pen", "ballpoint", "gel pen",
        "pilot pen", "click pen", "ink pen", "fountain pen",
        "pencil", "mechanical pencil",
        "sketch pen", "marker", "permanent marker", "whiteboard marker",
        "highlighter", "crayons", "oil pastel",
        "colour pencil", "watercolour",
        # Erasers / correction
        "eraser", "rubber", "sharpener", "whitener", "correction pen",
        # Paper / notebooks
        "notebook", "long book", "register", "spiral notebook",
        "exercise book", "ruled notebook", "plain notebook",
        "drawing book", "drawing sheet", "chart paper",
        "graph paper", "a4 paper", "letter paper", "envelope",
        "sticky note", "post it",
        # Office supplies
        "stapler", "staple pin", "staple refill",
        "punch machine", "hole punch",
        "paper clip", "binder clip", "bulldog clip",
        "file folder", "file cover", "plastic cover",
        "binder", "ring binder", "arch file",
        # Adhesives / tape
        "glue stick", "fevicol", "fevistick", "adhesive",
        "cello tape", "sellotape", "masking tape", "double sided tape",
        "scissors", "cutter", "paper cutter", "blade",
        # Printer
        "printer ink", "toner cartridge", "ink cartridge",
        "photo paper", "glossy paper",
        # Geometry / math
        "geometry box", "compass", "divider", "protractor",
        "set square", "ruler", "scale",
        "calculator",
        # Misc
        "label sticker", "name sticker", "index tab",
        "rubber band",
        "chalk", "whiteboard duster", "whiteboard",
        "stamp pad", "ink stamp",
    ],

    # ════════════════════════════════════════════════════════════════════════
    # HOUSEHOLD
    # ════════════════════════════════════════════════════════════════════════
    "Household": [
        # Cleaning tools
        "broom", "jhadu", "mop", "mop stick", "floor wiper",
        "scrubber", "scrub pad", "sponge",
        "dustpan", "brush",
        "toilet brush", "bathroom brush",
        # Floor / surface cleaners
        "floor cleaner", "phenyl", "phynyl",
        "glass cleaner", "surface cleaner",
        "bathroom cleaner", "toilet cleaner",
        "kitchen cleaner", "drain cleaner",
        "disinfectant",
        # Dish washing
        "dish wash bar", "dish wash liquid",
        "utensil cleaner", "bartan soap",
        # Laundry
        "washing powder", "washing liquid",
        "fabric softener", "stain remover",
        # Kitchen items
        "pressure cooker", "cooker gasket", "cooker weight",
        "kadai", "tawa", "frying pan", "saucepan",
        "non stick pan",
        "steel plate", "thali", "katori", "bowl",
        "glass tumbler", "cup", "mug",
        "spatula", "ladle", "karchi", "jhara", "strainer",
        "colander",
        "storage container", "airtight container", "dabba",
        "casserole",
        "mixer jar", "grinder jar",
        "rolling pin", "chakla belan",
        "knife", "chopping board", "peeler",
        # Electrical / lighting
        "rice cooker", "slow cooker", "instant pot",
        "washing machine", "refrigerator", "fridge", "microwave",
        "led bulb", "cfl bulb", "tubelight", "batten",
        "extension cord", "extension board", "power strip",
        "switch board", "socket",
        # Furniture / soft furnishing
        "curtain", "parda", "bedsheet", "bed cover",
        "pillow cover", "blanket", "razai", "quilt",
        "mattress", "pillow", "cushion cover",
        "towel", "face towel", "bath towel",
        "bath mat", "doormat", "floor mat",
        # Bathroom
        "bucket", "mug", "bathtub accessory",
        "soap dish", "toothbrush holder",
        "shower curtain", "shower mat",
        # Pest control
        "mosquito coil", "mosquito repellent",
        "cockroach gel", "cockroach spray",
        "rat trap", "rat poison",
        "ant powder", "ant killer",
        # Air freshener / fragrance
        "room freshener", "air freshener", "car freshener",
        "agarbatti", "incense stick", "dhoop",
        "camphor", "kapoor",
        "odonil sachet",
        # Pooja items
        "pooja samagri", "puja items",
        "diyas", "diya", "clay diya",
        "candle", "wax candle",
        "kumkum", "sindoor", "bindi",
        "flowers for pooja", "marigold",
        "coconut for pooja",
        # Garbage
        "garbage bag", "dustbin bag", "trash bag",
        "dustbin",
        # Repair / maintenance
        "plumber", "electrician", "carpenter", "painter",
        "white wash", "wall putty", "primer",
        "wall paint",
        "screw", "nail", "hammer",
        "glue gun",
    ],

    # ════════════════════════════════════════════════════════════════════════
    # CLOTHES
    # ════════════════════════════════════════════════════════════════════════
    "Clothes": [
        # Tops / shirts
        "shirt", "formal shirt", "casual shirt",
        "t-shirt", "tshirt", "half sleeve", "full sleeve",
        "polo shirt", "half t shirt",
        "kurta", "kurti", "kurta pajama",
        "top", "crop top", "spaghetti top",
        "blouse", "saree blouse",
        # Ethnic
        "salwar", "salwar kameez", "churidar", "dupatta",
        "saree", "sari", "lehenga", "choli", "ghaghra",
        "anarkali", "sharara", "palazzo",
        "sherwani", "bandhgala", "indo western",
        "dhoti", "lungi", "mundu", "gamcha", "veshti",
        # Bottoms
        "trouser", "pant", "formal pant", "casual pant",
        "jeans", "chinos", "track pant",
        "shorts", "bermuda", "boxer shorts",
        "skirt", "midi skirt", "maxi skirt",
        "leggings", "jeggings", "tights",
        "petticoat", "inskirt",
        # Dresses / full outfits
        "gown", "frock", "midi dress", "maxi dress",
        "jumpsuit", "romper",
        # Outerwear
        "jacket", "blazer", "coat", "overcoat",
        "sweater", "pullover", "sweatshirt", "hoodie",
        "cardigan", "shrug", "stole", "scarf", "shawl",
        "woolen", "muffler",
        # Innerwear
        "underwear", "innerwear", "bra", "bralette",
        "camisole", "slip", "vest", "banyan",
        "langot", "nappy cloth",
        # Socks / hosiery
        "sock", "ankle sock", "stockings", "tights",
        # Footwear
        "chappal", "sandal", "slipper", "flip flop",
        "boot", "sneaker", "sport shoe", "running shoe",
        "formal shoe", "oxford", "loafer",
        "heels", "stiletto", "wedge", "platform shoe",
        "kolhapuri", "jutti",
        # Accessories
        "belt", "tie", "bow tie", "pocket square",
        # Nightwear
        "nightwear", "pyjama", "pyjamas", "nightdress", "nightsuit",
        # Children
        "school uniform", "school shoes",
        # Sports
        "sportswear", "gym wear", "yoga wear",
        "swimwear", "swimsuit",
        # Misc
        "tailor", "stitching charge", "alteration charge",
        "dry clean", "dry cleaning",
        "ironing",    ],

    # ════════════════════════════════════════════════════════════════════════
    # SELFCARE
    # ════════════════════════════════════════════════════════════════════════
    "Selfcare": [
        # Hair care
        "shampoo", "anti dandruff shampoo", "hair fall shampoo",
        "hair conditioner", "deep conditioner", "hair mask",
        "hair serum", "hair oil", "argan oil", "amla oil",
        "hair color", "hair dye", "hair colour",
        "mehendi", "henna",
        "hair gel", "hair wax", "hair spray",
        "dry shampoo",
        # Skin care
        "face wash", "foaming face wash",
        "moisturizer", "face moisturizer",
        "body lotion", "hand cream", "foot cream",
        "sunscreen", "spf cream", "sunblock",
        "night cream", "anti ageing cream",
        "face serum", "vitamin c serum",
        "toner", "face toner", "micellar water",
        "face pack", "face mask", "peel off mask",
        "scrub", "face scrub", "body scrub",
        "under eye cream",
        # Oral care
        "toothpaste", "toothbrush", "electric toothbrush",
        "mouthwash", "dental floss", "teeth whitening",
        "tongue cleaner",
        # Body hygiene
        "bath soap", "body wash", "shower gel",
        "bath salt", "bath bomb",
        "body powder", "talcum powder", "prickly heat powder",
        # Deodorant / perfume
        "deodorant", "deo spray", "roll on deo",
        "antiperspirant",
        "perfume", "cologne", "scent", "body spray",
        "attar", "itra",
        # Shaving / grooming – men
        "shaving cream", "shaving foam", "shaving gel",
        "razor", "disposable razor", "shaving blade",
        "after shave lotion",
        "beard oil", "beard balm",
        "electric trimmer", "trimmer blade",
        # Hair removal – women
        "wax strip", "cold wax", "hot wax",
        "hair removal cream",
        "threading thread",
        "epilator",
        # Cosmetics / makeup
        "lipstick", "lip gloss", "lip liner",
        "lip balm", "chapstick",
        "kajal", "kohl", "surma",
        "eyeliner", "liquid eyeliner",
        "mascara", "eyeshadow", "eye palette",
        "foundation", "liquid foundation",
        "bb cream", "cc cream", "concealer",
        "blush", "highlighter", "bronzer", "contour",
        "setting powder", "compact powder",
        "setting spray", "primer",
        "nail polish", "nail paint", "nail art",
        "nail remover", "nail file",
        "makeup brush", "beauty blender",
        "makeup remover", "cleansing balm", "cleansing oil",
        # Feminine hygiene
        "sanitary pad", "menstrual pad",
        "panty liner", "tampon", "menstrual cup",
        "intimate wash", "feminine wash",
        # Salon services
        "haircut", "hair trim", "hair straightening",        "hair smoothening", "hair rebonding",
        "hair highlights", "balayage",
        "facial", "cleanup", "gold facial",
        "bleach", "bleaching cream",
        "threading", "eyebrow threading",
        "waxing service", "full body wax",
        "manicure", "pedicure", "gel nails", "nail extension",
        "d tan", "skin polishing",
        # Baby care
        "baby powder", "baby soap", "baby shampoo",
        "baby lotion", "baby oil",
        "baby wipes", "wet wipes",
        # Hindi / vernacular selfcare terms
        "sabun",                   # soap (generic – context overrides disambiguate)
        "hand wash", "handwash",
        "hand sanitizer", "sanitizer",
        "rose water", "gulab jal",
        "aloe vera gel", "aloe vera",
        "dettol soap", "lifebuoy soap",
        "toilet soap", "bathing soap",

    ],
}


# ─────────────────────────────────────────────────────────────────────────────
# REGEX PATTERNS  – catch phrases that don't have exact keywords
# ─────────────────────────────────────────────────────────────────────────────

CATEGORY_PATTERNS: list[tuple[str, str, str]] = [
    # (category, confidence, pattern)

    # Grocery – quantity units typically mean raw/packaged goods
    ("Grocery", "medium", r"\b\d+\s*(kg|kgs|gm|gms|gram|grams|liter|litre|ltr|ml|g|l)\b"),
    ("Grocery", "medium", r"\b(dal|daal|dhal)\b"),
    ("Grocery", "high",   r"\b(sabzi|sabziya|tarkari|bhaji)\b"),
    ("Grocery", "high",   r"\b(tamatar|aloo|pyaz|lehsun|adrak|gajar|palak)\b"),
    ("Grocery", "high",   r"\b(aam|kela|seb|santra|angoor|anaar|nimbu|tarbooj)\b"),
    ("Grocery", "medium", r"\b(packet|pouch|sachet|tin|jar)\b"),
    ("Grocery", "medium", r"\b(monthly|weekly)\s*(ration|grocery|kirana)\b"),

    # Food – phrases like "ordered from", "ate at"
    ("Food",    "medium", r"\b(order(ed)?|deliver(ed)?)\s*(food|khana|meal)\b"),
    ("Food",    "medium", r"\b(ate|eat|eating)\s*(at|from)\b"),
    ("Food",    "medium", r"\b(hotel|restaurant|dhaba|tapri|stall)\b"),

    # Medical – dosage patterns
    ("Medical", "high",   r"\b\d+\s*mg\s*(tablet|capsule|strip)\b"),
    ("Medical", "high",   r"\b\d+\s*ml\s*(syrup|drop|suspension)\b"),
    ("Medical", "medium", r"\b(tablet|capsule|syrup|ointment|cream)\s*(for|of|strip)\b"),
    ("Medical", "high",   r"\b(dawa|dawai|davaai)\b"),
    ("Medical", "medium", r"\b(strip of|pack of)\s*\d*\s*(tablet|capsule)\b"),
    ("Medical", "medium", r"\b(doctor|hospital|clinic|lab|test|scan)\b"),

    # Utilities
    ("Utilities","high",  r"\b(bijli|current|light)\s*bill\b"),
    ("Utilities","high",  r"\b(recharge|topup|top\s*up)\b"),
    ("Utilities","high",  r"\b(bill\s*(pay|payment|paid))\b"),

    # Travel
    ("Travel",  "high",   r"\b(petrol|diesel|cng)\s*(bhar|fill|pump|liya)\b"),
    ("Travel",  "medium", r"\b(to|from)\s+\w+\s+(airport|station|bus\s*stand|terminus)\b"),
    ("Travel",  "medium", r"\b\d+\s*km\s*(ride|trip|travel|journey)\b"),

    # Clothes
    ("Clothes", "medium", r"\b\d+\s*(piece|pcs|pair)\s*(of\s*)?(shirt|pant|kurta|saree|shoe)\b"),
    ("Clothes", "medium", r"\b(stitching|alteration|tailor)\b"),

    # Selfcare
    ("Selfcare","medium", r"\b(salon|parlour|parlor)\b"),
    ("Selfcare","medium", r"\b(haircut|waxing|facial|manicure|pedicure)\b"),

    # Entertainment
    ("Entertainment","high", r"\b(ott|streaming)\s*(subscription|plan|bill)\b"),
    ("Entertainment","medium",r"\b(movie|film|show)\s*(ticket|booking)\b"),
]


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

def _normalize(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[^\w\s]", " ", text)
    text = re.sub(r"\s+", " ", text)
    return text


def _wb(phrase: str) -> re.Pattern:
    """
    Word-boundary safe compiled regex for a phrase.
    Prevents 'ola' matching inside 'chocolate', 'auto' inside 'automatic', etc.
    Uses lookaround assertions so multi-word phrases work correctly too.
    """
    return re.compile(r"(?<!\w)" + re.escape(phrase) + r"(?!\w)", re.IGNORECASE)


# ── Pre-compile ALL patterns once at import time ──────────────────────────────
# This gives both correctness (word boundaries) and speed (no recompile per call)

_COLLECTIVE_COMPILED: list[tuple[re.Pattern, str, str]] = [
    (_wb(phrase), phrase, cat)
    for phrase, cat in COLLECTIVE_NOUNS.items()
]

_CONTEXT_COMPILED: list[tuple[re.Pattern, str, str]] = [
    (_wb(phrase), phrase, cat)
    for phrase, cat in CONTEXT_OVERRIDES
]

_BRAND_COMPILED: list[tuple[re.Pattern, str, str]] = [
    (_wb(brand), brand, cat)
    for brand, cat in BRAND_OVERRIDES.items()
]

_KEYWORD_COMPILED: list[tuple[re.Pattern, str, str, str]] = [
    (_wb(kw), kw, cat, "high" if len(kw) > 5 else "medium")
    for cat, kws in CATEGORY_KEYWORDS.items()
    for kw in kws
]

_PATTERN_COMPILED: list[tuple[re.Pattern, str, str, str]] = [
    (re.compile(pat, re.IGNORECASE), pat, cat, conf)
    for cat, conf, pat in CATEGORY_PATTERNS
]


def _check_collective(norm: str) -> Optional[tuple[str, str]]:
    """Word-boundary match – longest phrase wins."""
    best_cat: Optional[str] = None
    best_phrase: Optional[str] = None
    best_len = 0
    for rx, phrase, cat in _COLLECTIVE_COMPILED:
        if rx.search(norm) and len(phrase) > best_len:
            best_len = len(phrase)
            best_cat = cat
            best_phrase = phrase
    if best_cat:
        return best_cat, best_phrase
    return None


def _check_context(norm: str) -> Optional[tuple[str, str]]:
    """
    Context-override match – longest phrase wins.
    Resolves ambiguity where a word means different things in different contexts:
      'face cream' → Selfcare  (not Grocery via 'cream')
      'tablet stand' → Household (not Medical via 'tablet')
      'egg bhurji' → Food  (not Grocery via 'egg')
    """
    best_cat: Optional[str] = None
    best_phrase: Optional[str] = None
    best_len = 0
    for rx, phrase, cat in _CONTEXT_COMPILED:
        if rx.search(norm) and len(phrase) > best_len:
            best_len = len(phrase)
            best_cat = cat
            best_phrase = phrase
    if best_cat:
        return best_cat, best_phrase
    return None


def _check_brands(norm: str) -> Optional[tuple[str, str]]:
    """
    Word-boundary brand match – longest brand wins.
    Prevents 'ola' matching inside 'chocolate', 'cola', 'petroLATum', etc.
    """
    best_cat: Optional[str] = None
    best_brand: Optional[str] = None
    best_len = 0
    for rx, brand, cat in _BRAND_COMPILED:
        if rx.search(norm) and len(brand) > best_len:
            best_len = len(brand)
            best_cat = cat
            best_brand = brand
    if best_cat:
        return best_cat, best_brand
    return None


def _check_keywords(norm: str) -> Optional[tuple[str, str, str]]:
    """
    Word-boundary keyword match – longest keyword wins.
    Prevents 'vi' (Vodafone) matching inside 'vitamin', 'auto' inside 'automatic', etc.
    """
    best_cat: Optional[str] = None
    best_kw: Optional[str] = None
    best_conf = "medium"
    best_len = 0
    for rx, kw, cat, conf in _KEYWORD_COMPILED:
        if rx.search(norm) and len(kw) > best_len:
            best_len = len(kw)
            best_cat = cat
            best_kw = kw
            best_conf = conf
    if best_cat:
        return best_cat, best_kw, best_conf
    return None


def _check_patterns(norm: str) -> Optional[tuple[str, str, str]]:
    for rx, pat, cat, conf in _PATTERN_COMPILED:
        if rx.search(norm):
            return cat, conf, pat
    return None


# ─────────────────────────────────────────────────────────────────────────────
# PUBLIC API
# ─────────────────────────────────────────────────────────────────────────────

VALID_CATEGORIES = [
    "Food", "Grocery", "Utilities", "Travel", "Entertainment",
    "Medical", "Stationary", "Household", "Clothes", "Selfcare", "Other",
]


def classify(product_name: str) -> ClassifierResult:
    """
    Classify a single product / expense name.

    Priority (all layers use strict word-boundary matching):
      1. Context overrides  – compound phrases that resolve ambiguity
                              e.g. "face cream"→Selfcare, "tablet stand"→Household,
                                   "egg bhurji"→Food, "gym subscription"→Selfcare
      2. Brand overrides    – known brand names (longest match wins)
                              Prevents 'ola' matching inside 'chocolate'
      3. Collective/keyword – longest match across both pools wins
                              Prevents 'rice' collective overriding 'rice cooker' keyword
      4. Regex patterns     – unit/dosage/contextual phrase patterns
      5. Default → Other

    Parameters
    ----------
    product_name : str

    Returns
    -------
    ClassifierResult
    """
    if not product_name or not product_name.strip():
        return ClassifierResult(product_name, "Other", "low", "default")

    norm = _normalize(product_name)

    # 1. Context overrides (highest priority – resolves same-word ambiguity)
    ctx = _check_context(norm)
    if ctx:
        return ClassifierResult(product_name, ctx[0], "high", "context", ctx[1])

    # 2. Brand overrides (longest brand wins)
    br = _check_brands(norm)
    if br:
        return ClassifierResult(product_name, br[0], "high", "exact_brand", br[1])

    # 3. Collective vs keyword – whichever gives the LONGER match wins
    col = _check_collective(norm)
    kw  = _check_keywords(norm)

    col_len = len(col[1]) if col else 0
    kw_len  = len(kw[1])  if kw  else 0

    if kw_len >= col_len and kw:
        return ClassifierResult(product_name, kw[0], kw[2], "keyword", kw[1])
    elif col:
        return ClassifierResult(product_name, col[0], "high", "collective", col[1])

    # 4. Pattern
    pt = _check_patterns(norm)
    if pt:
        return ClassifierResult(product_name, pt[0], pt[1], "pattern", pt[2])

    # 5. Default
    return ClassifierResult(product_name, "Other", "low", "default")


def classify_batch(product_names: list[str]) -> list[ClassifierResult]:
    """Classify a list of product names."""
    return [classify(name) for name in product_names]


def get_category(product_name: str) -> str:
    """Return just the category string."""
    return classify(product_name).category


def classify_to_dict(product_name: str) -> dict:
    """Return classification as a plain dict (JSON-serialisable)."""
    r = classify(product_name)
    return {
        "product": r.product,
        "category": r.category,
        "confidence": r.confidence,
        "method": r.method,
        "matched_keyword": r.matched_keyword,
    }


def classify_with_ai_fallback(
    product_name: str,
    api_key: Optional[str] = None,
) -> ClassifierResult:
    """
    Classify; if confidence is 'low', escalate to Claude AI.
    Requires: pip install anthropic
    """
    result = classify(product_name)
    if result.confidence != "low":
        return result

    try:
        import os
        import anthropic

        key = api_key or os.environ.get("ANTHROPIC_API_KEY")
        if not key:
            return result

        client = anthropic.Anthropic(api_key=key)
        prompt = (
            "You are an Indian household expense categoriser. "
            "Classify the product/expense below into exactly one category.\n"
            f"Categories: {', '.join(VALID_CATEGORIES)}\n"
            f"Product: \"{product_name}\"\n"
            "Reply with ONLY the category name."
        )
        message = client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=10,
            messages=[{"role": "user", "content": prompt}],
        )
        ai_cat = message.content[0].text.strip()
        if ai_cat in VALID_CATEGORIES:
            return ClassifierResult(product_name, ai_cat, "medium", "ai")
    except Exception:
        pass

    return result


# ─────────────────────────────────────────────────────────────────────────────
# CLI demo
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    test_items = [
        # ── Colloquial grocery (how shoppers actually type) ──
        "sabzi lao",          "vegetables",        "fruits",
        "monthly ration",     "kirana saman",      "dal lao",
        "daal packet",        "dhal 1kg",          "pulses",
        "aata 10kg",          "ration",            "anaj",
        "dudh 2 packets",     "ghee 500gm",        "tel 1l",
        "masale",             "spices",

        # ── All dal varieties ──
        "toor dal 1kg",       "moong dal 500gm",   "rajma 250g",
        "masoor dal",         "chana dal packet",  "urad dal",
        "lobia",              "matki 500g",        "horse gram",
        "val dal",            "sabut masoor",      "kali dal",
        "chhole",             "panchmel dal",

        # ── Vegetables (Hindi + English) ──
        "tamatar 1kg",        "aloo 2kg",          "pyaz",
        "bhindi 250g",        "baingan",           "karela",
        "lauki",              "gajar",             "methi",
        "palak 1 bunch",      "capsicum",          "mushroom",
        "baby corn",          "tinda",             "parwal",

        # ── Fruits ──
        "aam 1 dozen",        "kela 6 pcs",        "seb 4 piece",
        "angoor 500g",        "anaar",             "nimbu",
        "papita",             "kiwi 4 pcs",

        # ── Food (cooked / restaurant) ──
        "swiggy order",       "zomato biryani",    "dominos pizza",
        "lunch at dhaba",     "chai at tapri",     "nashta",
        "dal fry plate",      "chole bhature",     "vada pav",
        "pani puri",          "gulab jamun",       "ice cream",

        # ── Utilities ──
        "bijli bill",         "recharge 299",      "jio recharge",
        "electricity bill",   "gas cylinder",      "pani bill",
        "broadband bill",     "dth recharge",      "cable bill",

        # ── Travel ──
        "ola cab",            "petrol bhar diya",  "irctc ticket",
        "metro card",         "fastag",            "parking fee",
        "indigo flight",      "oyo hotel",         "uber 8km",

        # ── Entertainment ──
        "netflix",            "hotstar subscription", "pvr movie",
        "bookmyshow",         "spotify",           "gaming",
        "ipl ticket",         "zoo ticket",

        # ── Medical (colloquial) ──
        "medicines",          "dawa",              "dawai",
        "crocin 10 tab",      "dolo 650",          "combiflam strip",
        "paracetamol",        "blood test",        "doctor visit",
        "chemist",            "metformin 500mg tablet",
        "vitamin d3",         "cough syrup",       "eye drop",
        "bandage roll",       "betadine",

        # ── Stationary ──
        "classmate notebook", "reynolds pen",      "school supplies",
        "a4 paper",           "stationery",        "crayons",

        # ── Household ──
        "surf excel 1kg",     "harpic",            "agarbatti",
        "pressure cooker",    "ghar ka saman",     "pooja samagri",
        "garbage bag",        "mosquito coil",

        # ── Clothes ──
        "myntra kurta",       "levis jeans",       "bata shoes",
        "kapde",              "stitching charge",  "dry cleaning",
        "school uniform",

        # ── Selfcare ──
        "nykaa lipstick",     "dove shampoo",      "colgate",
        "toiletries",         "salon",             "waxing",
        "whisper pads",       "baby wipes",

        # ── Edge cases ──
        "birthday gift",      "random xyz",        "misc",
        "2 kg aata",          "500gm dal",
    ]

    print(f"{'Product':<38} {'Category':<15} {'Conf':<8} {'Method':<14} {'Matched'}")
    print("─" * 100)
    for item in test_items:
        r = classify(item)
        print(
            f"{r.product:<38} {r.category:<15} {r.confidence:<8} "
            f"{r.method:<14} {r.matched_keyword or '-'}"
        )