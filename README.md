# Integrated vegetable Crop Type Recommendation Using Rule-Based and Random Forest
This project aims to assist Malaysian farmers in selecting the most suitable and profitable vegetable crop based on environmental factors (soil, weather) and market trends (weekly price data).
The system uses Random Forest Machine Learning and is integrated into a Flutter-based mobile application that provides real-time recommendations.

This project supports national sustainability goals and contributes to digital transformation in agriculture.

Objectives
1) Identify key environmental and market factors that influence vegetable crop selection.

2) Develop a predictive ML model (Random Forest) that recommends suitable vegetable crops.

3) Build a mobile application prototype that integrates real-time data and delivers recommendations to farmers.

Dataset Components:
Environmental Data

- Nitrogen (N)
- Phosphorus (P)
- Potassium (K)
- Soil pH
- Temperature
- Humidity
- Rainfall
- Crop label

Market Price Data
- Week
- Month
- Year
- Crop type
- Average market price (RM/kg).

Sources:
Kaggle dataset (environmental data)
FAMA (weekly market price)
OpenWeatherMap API


Machine Learning Model
Algorithm Used: Random Forest Regression

Model Process:
Rule-Based Filtering
Filters crops by environmental suitability (pH, rainfall, NPK, etc.).
Random Forest Prediction:
Predicts profitability using market price data.
Final Recommendation:
Most suitable crop = environmentally suitable + highest predicted market return.

