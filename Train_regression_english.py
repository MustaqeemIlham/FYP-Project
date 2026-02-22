import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg") 
import matplotlib.pyplot as plt
import pickle
import os
import itertools
from sklearn.model_selection import KFold
from sklearn.ensemble import RandomForestRegressor
import re

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

def log_to_txt(file, text):
    with open(file, "a", encoding="utf-8") as f:
        f.write(text + "\n")

def label_points(x, y, offset=0.02):
    for xi, yi in zip(x, y):
        plt.text(
            xi,
            yi + offset,
            f"{yi:.2f}",
            ha="center",
            va="bottom",
            fontsize=8
        )

def sanitize_filename(name):
    return re.sub(r'[\\/*?:"<>|]', "_", name)

def build_prediction_text(weeks, preds, max_rows=10):
    lines = ["Predicted Price (RM/KG):"]
    for w, p in zip(weeks[:max_rows], preds[:max_rows]):
        lines.append(f"Week {int(w):>2}: {p:.2f}")
    if len(weeks) > max_rows:
        lines.append("...")
    return "\n".join(lines)



def prepare_growth_cycle_dataset_crossyear(df, growth_cycles):
    df_prepared = df.copy()
    df_prepared = df_prepared.sort_values(["Crop Type", "Year", "Week"]).reset_index(drop=True)
    df_prepared["TargetPrice"] = pd.NA

    for crop, cycle in growth_cycles.items():
        crop_mask = df_prepared["Crop Type"] == crop
        crop_rows = df_prepared[crop_mask].reset_index()
        target_prices = []

        for idx, row in crop_rows.iterrows():
            start_week = row["Week"]
            start_year = row["Year"]
            target_week = start_week + cycle
            target_year = start_year

            while target_week > 52:
                target_week -= 52
                target_year += 1

            target_row = crop_rows[
                (crop_rows["Year"] == target_year) & (crop_rows["Week"] == target_week)
            ]
            if not target_row.empty:
                target_prices.append(target_row.iloc[0]["Avg Market Price (RM/KG)"])
            else:
                target_prices.append(np.nan)

        df_prepared.loc[crop_rows["index"], "TargetPrice"] = target_prices

    df_prepared = df_prepared.dropna(subset=["TargetPrice"]).reset_index(drop=True)
    return df_prepared


def cross_validate_rf(X, y, param_dict, n_splits=5):
    if len(X) < n_splits:
        n_splits = max(2, len(X))

    kf = KFold(n_splits=n_splits, shuffle=True, random_state=42)
    r2_scores, mse_scores, mae_scores, rmse_scores = [], [], [], []

    for train_idx, test_idx in kf.split(X):
        X_train, X_test = X[train_idx], X[test_idx]
        y_train, y_test = y[train_idx], y[test_idx]

        rf = RandomForestRegressor(
            n_estimators=param_dict["n_estimators"],
            max_depth=param_dict["max_depth"],
            min_samples_split=param_dict["min_samples_split"],
            min_samples_leaf=param_dict["min_samples_leaf"],
            max_features=param_dict["max_features"],
            random_state=42,
            oob_score=True,
            n_jobs=-1
        )
        rf.fit(X_train, y_train)
        preds = rf.predict(X_test)

        r2_scores.append(r2_score(y_test, preds))
        mse_scores.append(mse(y_test, preds))
        mae_scores.append(mae(y_test, preds))
        rmse_scores.append(rmse(y_test, preds))

    return {
        "r2_mean": np.mean(r2_scores),
        "r2_std": np.std(r2_scores),
        "mse_mean": np.mean(mse_scores),
        "mae_mean": np.mean(mae_scores),
        "rmse_mean": np.mean(rmse_scores)
    }


if __name__ == "__main__":
    df = pd.read_csv("clean_crop_prices_actual_new.csv")

    # Fill missing values
    num_cols = df.select_dtypes(include=[np.number]).columns
    for col in num_cols:
        df[col] = df[col].fillna(df[col].median())

    cat_cols = df.select_dtypes(include=["object"]).columns
    for col in cat_cols:
        if df[col].isnull().any():
            df[col] = df[col].mode()[0]

    df = df.rename(columns={"Price": "Avg Market Price (RM/KG)"})

    # Growth Cycles
    growth_cycles = {
        "Spinach": 4, "Green Chili": 16, "Red Chili (Kulai / Hybrid)": 16,
        "Oil Red Chili": 16, "Bird’s Eye Chili": 14, "Celery Leaves (Highland)": 8,
        "Young Ginger": 20, "Okra (Lady’s Finger)": 8, "French Beans": 10, "Long Beans (Green)": 8,
        "Chinese Broccoli (Kai-lan)": 6, "Water Spinach": 4, "Round Cabbage (Highland)": 12, "Pumpkin": 14,
        "Green Bell Pepper (Capsicum)": 16, "Calamansi Lime": 20, "Key Lime": 20,
        "Bitter Gourd (Bitter Melon)": 12, "Head Lettuce (Highland)": 6, "Green Mustard (Lowland)": 5,
        "Round Eggplant": 12, "Long Eggplant (Lowland)": 12,
        "Cucumber": 6, "Tomato (Highland)": 12
    }

    df_prepared = prepare_growth_cycle_dataset_crossyear(df, growth_cycles)

    # Encode categorical features
    df_encoded = df_prepared.copy()
    df_encoded["Month"] = df_encoded["Month"].astype("category").cat.codes
    df_encoded["Crop Type"] = df_encoded["Crop Type"].astype("category").cat.codes

    crop_type_mapping = dict(enumerate(df_prepared["Crop Type"].astype("category").cat.categories))
    month_mapping = dict(enumerate(df_prepared["Month"].astype("category").cat.categories))

    # Features / Target
    X = df_encoded.drop(["Avg Market Price (RM/KG)", "TargetPrice"], axis=1).values
    y = df_encoded["TargetPrice"].values

    # Train-Test Split
    np.random.seed(42)
    indices = np.arange(len(X))
    np.random.shuffle(indices)
    split = int(0.8 * len(X))
    train_idx, test_idx = indices[:split], indices[split:]
    X_train, X_test = X[train_idx], X[test_idx]
    y_train, y_test = y[train_idx], y[test_idx]

    # Hyperparameter tuning
    # param_grid = {
    #     "n_estimators": [100],
    #     "max_depth": [10],
    #     "min_samples_split": [2],
    #     "min_samples_leaf": [1],
    #     "max_features": [None]
    # }
    param_grid = {
        "n_estimators": [100, 150, 200, 300, 400, 500], 
        "max_depth": [6, 10, 15, 20, None],          
        "min_samples_split": [2, 5, 10],               
        "min_samples_leaf": [1, 2, 4],               
        "max_features": ["sqrt", "log2", None],       
    }

    results_file = "cv_train_results.txt"
    r2_file = "r2_results.txt"
    rmse_file = "rmse_results.txt"
    mse_file = "mse_results.txt"
    mae_file = "mae_results.txt"

    for file in [r2_file, rmse_file, mse_file, mae_file, results_file]:
        with open(file, "w", encoding="utf-8") as f:
            f.write("=== CROSS-VALIDATION RESULTS (TRAIN SET) ===\n\n")


    best_params, best_score = None, -float("inf")

    print("\n=== CROSS-VALIDATION RESULTS (on TRAIN set) ===")

    for i, params in enumerate(itertools.product(*param_grid.values()), start=1):
        param_dict = dict(zip(param_grid.keys(), params))
        cv_results = cross_validate_rf(X_train, y_train, param_dict, n_splits=5)

        output = (
            f"Combination {i}\n"
            f"Params: {param_dict}\n"
            f"R² Mean ± Std : {cv_results['r2_mean']:.4f} ± {cv_results['r2_std']:.4f}\n"
            f"MSE Mean     : {cv_results['mse_mean']:.4f}\n"
            f"MAE Mean     : {cv_results['mae_mean']:.4f}\n"
            f"RMSE Mean    : {cv_results['rmse_mean']:.4f}\n"
            f"{'-'*60}\n"
        )

        print(output)
        

        # Save to txt
        #log_to_txt(results_file, output)

        r2_output = f"Combination {i}\nParams: {param_dict}\nR² Mean ± Std : {cv_results['r2_mean']:.4f} ± {cv_results['r2_std']:.4f}\n{'-'*60}\n"
        mse_output = f"Combination {i}\nParams: {param_dict}\nMSE Mean     : {cv_results['mse_mean']:.4f}\n{'-'*60}\n"
        mae_output = f"Combination {i}\nParams: {param_dict}\nMAE Mean     : {cv_results['mae_mean']:.4f}\n{'-'*60}\n"
        rmse_output = f"Combination {i}\nParams: {param_dict}\nRMSE Mean    : {cv_results['rmse_mean']:.4f}\n{'-'*60}\n"


        if cv_results["r2_mean"] > best_score:
            best_score = cv_results["r2_mean"]
            best_params = param_dict
            best_rmse = cv_results["rmse_mean"]
            best_mae = cv_results["mae_mean"]
            best_mse = cv_results["mse_mean"]
        
        best_summary = (
            "\n=== BEST HYPERPARAMETERS (CROSS-VALIDATION) ===\n"
            f"Best Params : {best_params}\n"
            f"Best R²     : {best_score:.4f}\n"
            f"Best MSE    : {best_mse:.4f}\n"
            f"Best MAE    : {best_mae:.4f}\n"
            f"Best RMSE   : {best_rmse:.4f}\n"
        )

    print(best_summary)


    rf_final = RandomForestRegressor(
        **best_params, random_state=42, oob_score=True, n_jobs=-1
    )
    rf_final.fit(X_train, y_train)
    print("OOB Score:", rf_final.oob_score_)

    # Save model + mappings
    artifacts = {
        "model": rf_final,
        "crop_mapping": crop_type_mapping,
        "month_mapping": month_mapping,
        "X_test": X_test,
        "y_test": y_test
    }

    with open("rf_growth_cycle_weekly_english.pkl", "wb") as f:
        pickle.dump(artifacts, f)

    print("\n Model + mappings + test set saved as rf_growth_cycle_weekly.pkl")

    # Evaluate
    train_preds = rf_final.predict(X_train)
    test_preds = rf_final.predict(X_test)

    print("\n=== FINAL MODEL PERFORMANCE ===")
    print("Train RMSE:", rmse(y_train, train_preds))
    print("Train R²:", r2_score(y_train, train_preds))
    print("Train MSE:", mse(y_train, train_preds))
    print("Train MAE:", mae(y_train, train_preds))
    print("Test R²:", r2_score(y_test, test_preds))

    crop_col_index = list(df_encoded.drop(["Avg Market Price (RM/KG)", "TargetPrice"], axis=1).columns).index("Crop Type")
    best_idx = np.argmax(train_preds)
    best_crop_code = int(X_train[best_idx][crop_col_index])
    best_crop = crop_type_mapping.get(best_crop_code, "Unknown Crop")
    best_price = train_preds[best_idx]

    print("\n=== RECOMMENDATION ===")
    print(f"Recommended Crop: {best_crop} (Predicted Harvest Price: RM {best_price:.2f} per KG)")



    save_root = r"D:\GRAPH"  
    # best_crop_folder = os.path.join(save_root, "best_crop")
    # all_crops_folder = os.path.join(save_root, "all_crops")
    best_crop_folder = os.path.join(save_root, "best_crop_tuning")
    best_crop_folder_barchat = os.path.join(save_root, "best_crop_tuning_error")
    all_crops_folder = os.path.join(save_root, "all_crops_tuning")
    

    for folder in [save_root, best_crop_folder, all_crops_folder]:
        os.makedirs(folder, exist_ok=True)

    crop_mask = df_prepared["Crop Type"] == best_crop
    crop_df = df_prepared[crop_mask].copy()
    crop_encoded = df_encoded[crop_mask].copy()

    features = crop_encoded.drop(
        ["Avg Market Price (RM/KG)", "TargetPrice"], axis=1
    ).values
    crop_df["PredictedPrice"] = rf_final.predict(features)

    years = sorted(crop_df["Year"].unique())

    for year in years:
        year_df = crop_df[crop_df["Year"] == year].sort_values("Week")

        plt.figure(figsize=(12, 6))

        # Actual price
        plt.plot(
            year_df["Week"],
            year_df["TargetPrice"],
            marker="o",
            linewidth=2,
            label="Actual Price (RM/KG)"
        )

        plt.plot(
            year_df["Week"],
            year_df["PredictedPrice"],
            marker="s",
            linestyle="--",
            linewidth=2,
            label="Predicted Price (Model Output)"
        )

        

        plt.xlabel("Week")
        plt.ylabel("Price (RM/KG)")
        plt.title(f"Weekly Actual vs Predicted Price\n{best_crop} - Year {year}")
        plt.legend()
        plt.grid(alpha=0.3)


        table_data = [
            [f"{a:.2f} (W{int(w)})", f"{p:.2f}"]
            for w, a, p in zip(year_df["Week"], year_df["TargetPrice"], year_df["PredictedPrice"])
        ]

        table = plt.table(
            cellText=table_data,
            colLabels=["Actual Price (RM)", "Predicted Price (RM)"],
            colLoc="center",
            cellLoc="center",
           bbox=[1.02, 0.0, 0.35, 1.0] 
        )


        table.auto_set_font_size(False)
        table.set_fontsize(8)
        table.scale(0.6, 0.6)      

        plt.xticks(range(1, 53), rotation=90)
        plt.xlim(1, 53)

        plt.tight_layout()
        plt.show()

        safe_crop_name = sanitize_filename(best_crop)
        filename = f"{safe_crop_name}_{year}.png"
        filepath = os.path.join(best_crop_folder, filename)
        plt.savefig(filepath, dpi=300)
        plt.close() 


    crop_df["Error"] = crop_df["PredictedPrice"] - crop_df["TargetPrice"]

    year_rmse = {}

    for year in years:
        year_df = crop_df[crop_df["Year"] == year]
        year_rmse[year] = rmse(
            year_df["TargetPrice"].values,
            year_df["PredictedPrice"].values
        )

    best_year = min(year_rmse, key=year_rmse.get)

    print("\n=== BEST YEAR ANALYSIS (Best Crop) ===")
    for y, v in year_rmse.items():
        print(f"Year {y}: RMSE = {v:.4f}")

    print(f"\n🏆 Best Year for {best_crop}: {best_year} (Lowest RMSE)")

    for year in years:
        year_df = crop_df[crop_df["Year"] == year]

        plt.figure(figsize=(8, 5))

        plt.hist(
            year_df["Error"],
            bins=15,
            alpha=0.7
        )

        plt.axvline(0, linestyle="--", linewidth=2)

        plt.xlabel("Prediction Error (RM/KG)")
        plt.ylabel("Frequency")
        plt.title(
            f"Error Distribution\n{best_crop} - Year {year}\n"
            f"RMSE = {year_rmse[year]:.3f}"
        )

        plt.grid(alpha=0.3)
        plt.tight_layout()

        # Save
        filename = f"{sanitize_filename(best_crop)}_ErrorDist_{year}.png"
        filepath = os.path.join(best_crop_folder_barchat, filename)
        plt.savefig(filepath, dpi=300)
        plt.close()


    all_crops = df_prepared["Crop Type"].unique()
    print(f"\nGenerating weekly plots per year for {len(all_crops)} crops...")

    for crop in all_crops:
        crop_mask = df_prepared["Crop Type"] == crop
        crop_df = df_prepared[crop_mask].copy()
        crop_encoded = df_encoded[crop_mask].copy()

        features = crop_encoded.drop(
            ["Avg Market Price (RM/KG)", "TargetPrice"], axis=1
        ).values
        crop_df["PredictedPrice"] = rf_final.predict(features)

        years = sorted(crop_df["Year"].unique())

        for year in years:
            year_df = crop_df[crop_df["Year"] == year].sort_values("Week")

            plt.figure(figsize=(12, 6))

            plt.plot(
                year_df["Week"],
                year_df["TargetPrice"],
                marker="o",
                linewidth=2,
                label="Actual Price"
            )
            plt.plot(
                year_df["Week"],
                year_df["PredictedPrice"],
                marker="s",
                linestyle="--",
                linewidth=2,
                label="Predicted Price"
            )

            plt.xlabel("Week")
            plt.ylabel("Price (RM/KG)")
            plt.title(
                f"Weekly Actual vs Predicted Price\n"
                f"{crop} - Year {year}"
            )

            table_data = [
                [f"{a:.2f} (W{int(w)})", f"{p:.2f}"]
                for w, a, p in zip(year_df["Week"], year_df["TargetPrice"], year_df["PredictedPrice"])
            ]

            table = plt.table(
                cellText=table_data,
                colLabels=["Actual Price (RM)", "Predicted Price (RM)"],
                colLoc="center",
                cellLoc="center",
            bbox=[1.02, 0.0, 0.35, 1.0] 
            )

            table.auto_set_font_size(False)
            table.set_fontsize(8)
            table.scale(0.6, 0.6)  

            plt.xticks(range(1, 53), rotation=90)
            plt.xlim(1, 53)

            plt.legend()
            plt.grid(alpha=0.3)
            plt.tight_layout()
            plt.show()

            filename = f"{sanitize_filename(crop)}_{year}.png"
            filepath = os.path.join(all_crops_folder, filename)
            plt.savefig(filepath, dpi=300)
            plt.close()


