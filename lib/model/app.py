# app.py
from flask import Flask, request, jsonify
import pickle
import numpy as np

app = Flask(__name__)

# ------------------------------
# Load Models
# ------------------------------

# 1. Classification model
with open("rf_classifier_model.pkl", "rb") as f:
    rf_classifier, label_mapping, _, _ = pickle.load(f)

# 2. Regression model (growth cycle weekly)
with open("rf_growth_cycle_weekly.pkl", "rb") as f:
    artifacts = pickle.load(f)

rf_regressor = artifacts["model"]
crop_mapping = artifacts["crop_mapping"]
month_mapping = artifacts["month_mapping"]

# 3. Crop descriptions
description_mapping = {
    0: "Bayam - Spinach-like leafy vegetable, short cycle, popular in local dishes.",
    1: "Cili Hijau - Green chili, medium cycle, used in stir-fries and sambal.",
    2: "Cili Merah Kulai/Hibrid - Red chili hybrid, widely used, longer growth cycle.",
    3: "Cili Merah Minyak - Red chili variety for chili paste, higher demand.",
    4: "Cili Padi - Small bird’s eye chili, very spicy, high market price.",
    5: "Daun Sup (Tanah Tinggi) - Celery leaves, garnish, grows in highlands.",
    6: "Halia Muda - Young ginger, aromatic spice root, longer cycle crop.",
    7: "Kacang Bendi - Okra, popular vegetable, medium cycle.",
    8: "Kacang Buncis - French beans, nutritious, moderate cycle.",
    9: "Kacang Panjang Hijau - Long beans, quick harvest, high demand.",
    10: "Kailan - Chinese broccoli, crunchy leafy veg, medium cycle.",
    11: "Kangkung - Water spinach, very fast harvest, widely consumed.",
    12: "Kubis Bulat (Tanah Tinggi) - Cabbage, cool climate crop, medium cycle.",
    13: "Labu Manis - Pumpkin, sweet flesh, longer cycle crop.",
    14: "Lada Benggala/Capsicum Hijau - Bell pepper, medium cycle, highland crop.",
    15: "Limau Kasturi - Calamansi lime, fruit crop, long cycle.",
    16: "Limau Nipis - Key lime, sour citrus fruit, long cycle.",
    17: "Peria - Bitter gourd, unique taste, medium cycle.",
    18: "Salad Bulat Tanah Tinggi - Head lettuce, quick cycle highland crop.",
    19: "Sawi Hijau (Tanah Rendah) - Mustard green, fast cycle leafy veg.",
    20: "Terung Bulat - Round eggplant, medium cycle, local dishes.",
    21: "Terung Panjang/Peparu - Long eggplant, medium cycle.",
    22: "Timun Hijau - Cucumber, refreshing veg, short cycle.",
    23: "Tomato (Tanah Tinggi) - Highland tomato, versatile in cooking."
}

# ------------------------------
# API Endpoint
# ------------------------------
@app.route("/recommend", methods=["POST"])
def recommend():
    data = request.get_json()

    # === Step 1: Get classifier inputs ===
    ph = data["ph"]
    nitrogen = data["nitrogen"]
    phosphorus = data["phosphorus"]
    potassium = data["potassium"]
    avg_temp = data["avg_temp"]
    humidity = data["humidity"]
    rainfall = data["rainfall"]

    # === Step 2: Crop classification ===
    features = [[ph, nitrogen, phosphorus, potassium, avg_temp, humidity, rainfall]]
    crop_idx = rf_classifier.predict(features)[0]
    crop_name = label_mapping[crop_idx]

    # === Step 3: Price prediction ===
    year = data["year"]
    month_encoded = data["month_encoded"]
    week_of_month = data["week_of_month"]

    price_features = [[year, month_encoded, week_of_month, crop_idx]]
    predicted_price = rf_regressor.predict(price_features)[0]

    # === Step 4: Wrap response to match Flutter ===
    response = {
        "recommendation": {
            "cropname": crop_name,
            "price": float(predicted_price),
            "description": description_mapping.get(crop_idx, "No description available.")
        }
    }
    return jsonify(response)

