from flask import Flask, request, jsonify, json
import pickle
import numpy as np
from datetime import datetime, timedelta

app = Flask(__name__)



with open("rf_growth_cycle_weekly_english.pkl", "rb") as f:
    artifacts = pickle.load(f)

rf_regressor = artifacts["model"]
crop_mapping = artifacts["crop_mapping"]
month_mapping = artifacts["month_mapping"]



with open("rulebased_english_2.json", "r") as f:
    rules_from_file = json.load(f)

def calculate_crop_suitability_score(env_data, crop_rules):
    """
    Calculate a suitability score (0-100) for a crop based on environmental conditions.
    Higher score = better match.
    """
    total_score = 0
    max_possible_score = len(crop_rules) * 100  
    
    for feature, limits in crop_rules.items():
        value = env_data[feature]
        min_val = limits["min"]
        max_val = limits["max"]
        range_width = max_val - min_val
        
        if range_width == 0: 
            range_width = 1
            
      
        if min_val <= value <= max_val:
            score = 100
        else:
            if value < min_val:
                distance = min_val - value
            else:  
                distance = value - max_val
            
            normalized_distance = distance / range_width
            

            score = max(0, 100 * (1 - min(normalized_distance, 2.0)))
        
        total_score += score
    

    final_score = (total_score / max_possible_score) * 100
    
    return final_score

def get_top_suitable_crops(env_data, rules, threshold=50.0, top_n=5):
    """
    Get top N suitable crops based on fuzzy matching score.
    threshold: Minimum score to consider (0-100)
    top_n: Number of top crops to return
    """
    crop_scores = []
    
    for crop, conditions in rules.items():
        score = calculate_crop_suitability_score(env_data, conditions)
        
        if score >= threshold:
            crop_scores.append({
                "crop": crop.upper(),
                "score": score
            })
    
    # Sort by score (highest first)
    crop_scores.sort(key=lambda x: x["score"], reverse=True)
    
    # Return top N crops
    return [item["crop"] for item in crop_scores[:top_n]]

# ------------------------------
# Crop descriptions
# ------------------------------
description_mapping = {
    0: "Birds Eye Chili – Small, very spicy chili with high market value.",
    1: "Bitter Gourd (Bitter Melon) – Distinctive bitter-tasting vegetable, medium growth cycle.",
    2: "Calamansi Lime – Citrus fruit crop with a long growth cycle.",
    3: "Celery Leaves (Highland) – Used as garnish, grown in cooler highland areas.",
    4: "Chinese Broccoli (Kai-lan) – Crunchy leafy vegetable, medium growth cycle.",
    5: "Cucumber – Refreshing vegetable, short growth cycle.",
    6: "French Beans – Nutritious legume, moderate growth cycle.",
    7: "Green Bell Pepper (Capsicum) – Medium growth cycle, mainly grown in highlands.",
    8: "Green Chili – Medium growth cycle, commonly used in stir-fries and sambal.",
    9: "Green Mustard (Lowland) – Fast growth cycle leafy vegetable.",
    10: "Head Lettuce (Highland) – Fast-growing leafy vegetable cultivated in highlands.",
    11: "Key Lime – Sour citrus fruit, long growth cycle.",
    12: "Long Beans (Green) – Fast-harvesting crop with high demand.",
    13: "Long Eggplant (Lowland) – Medium growth cycle vegetable.",
    14: "Oil Red Chili – Used for chili paste, high market demand.",
    15: "Okra (Lady's Finger) – Popular vegetable, medium growth cycle.",
    16: "Pumpkin – Sweet-fleshed fruit vegetable, long growth cycle.",
    17: "Red Chili (Kulai / Hybrid) – Hybrid red chili, widely used, longer growth cycle.",
    18: "Round Cabbage (Highland) – Cool-climate crop, medium growth cycle.",
    19: "Round Eggplant – Medium growth cycle, commonly used in local dishes.",
    20: "Spinach – Leafy green vegetable, short growth cycle, popular in local dishes.",
    21: "Tomato (Highland) – Highland-grown tomato, versatile for cooking.",
    22: "Water Spinach – Very fast-growing leafy vegetable, widely consumed.",
    23: "Young Ginger – Aromatic spice root, long growth cycle crop."
}


growth_cycles = {
    "SPINACH": 4,
    "GREEN CHILI": 16,
    "RED CHILI (KULAI / HYBRID)": 16,
    "OIL RED CHILI": 16,
    "BIRDS EYE CHILI": 14,
    "CELERY LEAVES (HIGHLAND)": 8,
    "YOUNG GINGER": 20,
    "OKRA (LADY'S FINGER)": 8,
    "FRENCH BEANS": 10,
    "LONG BEANS (GREEN)": 8,
    "CHINESE BROCCOLI (KAI-LAN)": 6,
    "WATER SPINACH": 4,
    "ROUND CABBAGE (HIGHLAND)": 12,
    "PUMPKIN": 14,
    "GREEN BELL PEPPER (CAPSICUM)": 16,
    "CALAMANSI LIME": 20,
    "KEY LIME": 20,
    "BITTER GOURD (BITTER MELON)": 12,
    "HEAD LETTUCE (HIGHLAND)": 6,
    "GREEN MUSTARD (LOWLAND)": 5,
    "ROUND EGGPLANT": 12,
    "LONG EGGPLANT (LOWLAND)": 12,
    "CUCUMBER": 6,
    "TOMATO (HIGHLAND)": 12
}


def get_week_of_year(date):
    """
    Get ISO week number from date.
    Same calculation as Flutter's _getWeekOfYear function.
    """
    return date.isocalendar()[1]

def get_week_of_month(date):
    """
    Get week number within month (1-5).
    Same calculation as Flutter's ((day - 1) // 7) + 1
    """
    return ((date.day - 1) // 7) + 1

def estimate_date_from_week(year, month, week_of_month):
    """
    Estimate a date from year, month, and week of month.
    Used when exact planting_date is not provided.
    """
    estimated_day = (week_of_month - 1) * 7 + 4  # Use middle of week (day 4)
    try:
        return datetime(year, month, min(estimated_day, 28))
    except ValueError:
        return datetime(year, month, 28)

# ------------------------------
# API Endpoint
# ------------------------------
@app.route("/recommend", methods=["POST"])
def recommend():
    data = request.get_json()

    planting_date = None
    
    if "planting_date" in data and data["planting_date"]:
        try:
            planting_date = datetime.strptime(data["planting_date"], "%Y-%m-%d")
            print(f"Using exact planting date: {planting_date}")
        except ValueError as e:
            print(f"Error parsing planting_date: {e}")
    
    if planting_date is None:
        year = int(data["year"])
        month = int(data["month"])
        week_of_month = int(data["week_of_month"])
        planting_date = estimate_date_from_week(year, month, week_of_month)
        print(f"Estimated planting date from week: {planting_date}")
    
    planting_year = planting_date.year
    planting_month = planting_date.month
    planting_week_of_month = get_week_of_month(planting_date)
    planting_week_of_year = get_week_of_year(planting_date)
    
    year = planting_year
    month_input = planting_month
    week_of_month_input = planting_week_of_month

    sample_env = {
        "N": data["nitrogen"],
        "P": data["phosphorus"],
        "K": data["potassium"],
        "temperature": data["avg_temp"],
        "humidity": data["humidity"],
        "ph": data["ph"],
        "rainfall": data["rainfall"]
    }

    print(f"Input values: {sample_env}")
    print(f"Planting Date: {planting_date.strftime('%Y-%m-%d')}")
    print(f"Planting Week: {planting_week_of_year} of year, {planting_week_of_month} of month")

    shortlisted_crops = get_top_suitable_crops(
        sample_env, 
        rules_from_file,
        threshold=40.0, 
        top_n=5  
    )

    if not shortlisted_crops:
        shortlisted_crops = get_top_suitable_crops(
            sample_env, 
            rules_from_file,
            threshold=30.0,
            top_n=3
        )
        
        if not shortlisted_crops:
            crop_scores = []
            for crop, conditions in rules_from_file.items():
                score = calculate_crop_suitability_score(sample_env, conditions)
                crop_scores.append({
                    "crop": crop.upper(),
                    "score": score
                })
            
            if crop_scores:
                crop_scores.sort(key=lambda x: x["score"], reverse=True)
                shortlisted_crops = [crop_scores[0]["crop"]]
                print(f"Using best available crop with score {crop_scores[0]['score']:.1f}%: {shortlisted_crops[0]}")
            else:
                print("No crops match at all")
                return jsonify({
                    "recommendation": None,
                    "message": "No suitable crops found for the given environmental conditions.",
                    "debug_info": {
                        "input_values": sample_env,
                        "reason": "No crop matched the minimum suitability threshold"
                    }
                }), 200

    print(f"Shortlisted crops (top {len(shortlisted_crops)}): {shortlisted_crops}")

    if isinstance(list(month_mapping.values())[0], str):
        reverse_month_mapping = {k: v for v, k in month_mapping.items()}
        month_code = reverse_month_mapping.get(month_input, 0)
    else:
        month_code = month_mapping.get(month_input, month_input)

    best_crop = None
    best_price = -float("inf")
    all_predictions = []

    for crop in shortlisted_crops:
        crop_code = None
        for k, v in crop_mapping.items():
            if v.upper() == crop:
                crop_code = int(k)
                break

        if crop_code is None:
            print(f"Warning: No mapping found for crop {crop}")
            continue
        
        price_features = np.array([[year, planting_week_of_year, crop_code, month_code]], dtype=np.float64)
        predicted_price = rf_regressor.predict(price_features)[0]
        current_price = 1.0
        predicted_price = current_price * (1 + predicted_price)

        cycle = growth_cycles.get(crop, 12)
        
        print(f"Crop: {crop}, Code: {crop_code}, Predicted Price: {predicted_price:.2f}, Cycle: {cycle} weeks")
        
        all_predictions.append({
            "crop": crop,
            "crop_code": crop_code,
            "predicted_price": predicted_price,
            "growth_cycle": cycle
        })

        if predicted_price > best_price:
            best_price = predicted_price
            
            harvest_date = planting_date + timedelta(weeks=cycle)
            harvest_year = harvest_date.year
            harvest_month = harvest_date.month
            harvest_week_of_month = get_week_of_month(harvest_date)
            harvest_week_of_year = get_week_of_year(harvest_date)
            
            harvest_week = ((planting_week_of_year + cycle - 1) % 52)
            if harvest_week == 0:
                harvest_week = 52
            
            best_crop = {
                "cropname": crop,
                "price": float(predicted_price),
                "growth_cycle_weeks": cycle,
                "description": description_mapping.get(crop_code, "No description available."),
                
                "planting_date": planting_date.strftime("%Y-%m-%d"),
                "planting_year": planting_year,
                "planting_month": planting_month,
                "planting_week_of_month": planting_week_of_month,
                "planting_week_of_year": planting_week_of_year,
                
                "harvest_date": harvest_date.strftime("%Y-%m-%d"),
                "harvest_year": harvest_year,
                "harvest_month": harvest_month,
                "harvest_week_of_month": harvest_week_of_month,
                "harvest_week_of_year": harvest_week_of_year,
                
                "recommended_planting_week": planting_week_of_year,
                "expected_harvest_week": harvest_week_of_year,
            }

    if not best_crop:
        print(f"All predictions: {all_predictions}")
        return jsonify({
            "recommendation": None,
            "message": "Suitable crops found, but no valid price prediction available.",
            "debug_info": {
                "input_values": sample_env,
                "shortlisted_crops": shortlisted_crops,
                "all_predictions": all_predictions
            }
        }), 200

    print(f"\nBest Crop Selected: {best_crop['cropname']}")
    print(f"   Price: RM{best_crop['price']:.2f}")
    print(f"   Growth Cycle: {best_crop['growth_cycle_weeks']} weeks")
    print(f"   Planting: {best_crop['planting_date']} (Week {best_crop['planting_week_of_year']})")
    print(f"   Harvest: {best_crop['harvest_date']} (Week {best_crop['harvest_week_of_year']})")
    
    return jsonify({
        "recommendation": best_crop,
        "debug_info": {
            "total_crops_considered": len(all_predictions),
            "selected_crop_price": best_price,
            "planting_date_used": planting_date.strftime("%Y-%m-%d"),
            "calculation_method": "exact_date_calculation"
        }
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True, use_reloader=False)

