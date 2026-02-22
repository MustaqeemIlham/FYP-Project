import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import pickle
import re

with open("rf_growth_cycle_weekly_english.pkl", "rb") as f:
    artifacts = pickle.load(f)

rf_final = artifacts["model"]
crop_mapping = artifacts["crop_mapping"]
month_mapping = artifacts["month_mapping"]
X_test = artifacts["X_test"]
y_test = artifacts["y_test"]

print("Model and test set loaded successfully!\n")


test_preds = rf_final.predict(X_test)

def rmse(y_true, y_pred):
    return np.sqrt(np.mean((y_true - y_pred) ** 2))

def r2_score(y_true, y_pred):
    ss_res = np.sum((y_true - y_pred) ** 2)
    ss_tot = np.sum((y_true - np.mean(y_true)) ** 2)
    return 1 - ss_res / ss_tot

def mse(y_true, y_pred):
    return np.mean((y_true - y_pred) ** 2)

def mae(y_true, y_pred):
    return np.mean(np.abs(y_true - y_pred))

print("=== TEST SET PERFORMANCE ===")
print(f"Test R²:   {r2_score(y_test, test_preds):.4f}")
print(f"Test MSE:  {mse(y_test, test_preds):.4f}")
print(f"Test MAE:  {mae(y_test, test_preds):.4f}")
print(f"Test RMSE: {rmse(y_test, test_preds):.4f}\n")


feature_names = ["Year", "Week", "Crop Type", "Month"] 
crop_col_index = feature_names.index("Crop Type")

best_idx = np.argmax(test_preds)
best_crop_code = int(X_test[best_idx][crop_col_index])
best_crop = crop_mapping.get(best_crop_code, "Unknown Crop")
best_price = test_preds[best_idx]

print("=== RECOMMENDATION (TEST SET) ===")
print(f"Recommended Crop: {best_crop}")
print(f"Predicted Harvest Price: RM {best_price:.2f} per KG\n")


best_crop_test_idx = X_test[:, crop_col_index] == best_crop_code
X_best = X_test[best_crop_test_idx]
y_best_actual = y_test[best_crop_test_idx]
y_best_pred = test_preds[best_crop_test_idx]

weeks_best = X_best[:, feature_names.index("Week")]
years_best = X_best[:, feature_names.index("Year")]


save_root = r"D:\GRAPH"  
best_crop_folder = os.path.join(save_root, "best_crop_test")
os.makedirs(best_crop_folder, exist_ok=True)


unique_years = sorted(np.unique(years_best))

for year in unique_years:
    year_mask = years_best == year
    weeks_year = weeks_best[year_mask]
    actual_year = y_best_actual[year_mask]
    pred_year = y_best_pred[year_mask]

    # Sort by week
    order = np.argsort(weeks_year)
    weeks_year = weeks_year[order]
    actual_year = actual_year[order]
    pred_year = pred_year[order]

    plt.figure(figsize=(12, 6))
    plt.plot(weeks_year, actual_year, marker="o", linewidth=2, label="Actual Price (RM/KG)")
    plt.plot(weeks_year, pred_year, marker="s", linestyle="--", linewidth=2, label="Predicted Price (Model Output)")

    plt.xlabel("Week")
    plt.ylabel("Price (RM/KG)")
    plt.title(f"Weekly Actual vs Predicted Price (TEST)\n{best_crop} - Year {int(year)}")
    plt.legend()
    plt.grid(alpha=0.3)
    plt.xticks(range(1, 53), rotation=90)
    plt.xlim(1, 53)

    table_data = [[f"{a:.2f} (W{int(w)})", f"{p:.2f}"] for w, a, p in zip(weeks_year, actual_year, pred_year)]
    table = plt.table(
        cellText=table_data,
        colLabels=["Actual Price (RM)", "Predicted Price (RM)"],
        colLoc="center",
        cellLoc="center",
        bbox=[1.02, 0.0, 0.35, 1.0]
    )
    table.auto_set_font_size(False)
    table.set_fontsize(8)
    table.scale(0.9, 1.2)

    plt.tight_layout()


    safe_crop_name = re.sub(r'[\\/*?:"<>|]', "_", best_crop)
    filename = f"{safe_crop_name}_TEST_Year{int(year)}.png"
    filepath = os.path.join(best_crop_folder, filename)
    plt.savefig(filepath, dpi=300)
    plt.close()

print(f"All weekly plots for {best_crop} (Test Set) saved in {best_crop_folder}")


