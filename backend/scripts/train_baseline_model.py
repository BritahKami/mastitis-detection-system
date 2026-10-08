"""
Baseline Random Forest Model Generator for Mastitis Detection.
Generates synthetic milk composition data grounded in veterinary clinical literature,
trains a Random Forest Classifier, and serializes the artifact to 'models/mastitis_rf_model.joblib'.

Veterinary Ranges:
Healthy Milk:
  - Temperature: 38.0 - 39.0 °C
  - pH: 6.4 - 6.7
  - Electrical Conductivity: 4.0 - 5.5 mS/cm

Mastitic Milk:
  - Temperature: 39.2 - 41.5 °C (inflammatory fever)
  - pH: 6.8 - 7.6 (increased blood-milk permeability, sodium/bicarbonate influx)
  - Electrical Conductivity: 6.0 - 10.5 mS/cm (elevated Na+ and Cl- ion concentration)
"""

import os
import numpy as np

def generate_and_train():
    try:
        from sklearn.ensemble import RandomForestClassifier
        import joblib
    except ImportError:
        print("scikit-learn and joblib are required to train and serialize the model.")
        print("Please run: pip install scikit-learn joblib numpy")
        return

    np.random.seed(42)
    n_samples_per_class = 1000

    # Class 0: Healthy Milk
    temp_healthy = np.random.normal(loc=38.6, scale=0.3, size=n_samples_per_class)
    ph_healthy = np.random.normal(loc=6.55, scale=0.08, size=n_samples_per_class)
    ec_healthy = np.random.normal(loc=4.8, scale=0.35, size=n_samples_per_class)
    X_healthy = np.column_stack([temp_healthy, ph_healthy, ec_healthy])
    y_healthy = np.zeros(n_samples_per_class, dtype=int)

    # Class 1: Mastitic Milk
    temp_mastitis = np.random.normal(loc=39.8, scale=0.5, size=n_samples_per_class)
    ph_mastitis = np.random.normal(loc=7.1, scale=0.2, size=n_samples_per_class)
    ec_mastitis = np.random.normal(loc=7.2, scale=0.8, size=n_samples_per_class)
    X_mastitis = np.column_stack([temp_mastitis, ph_mastitis, ec_mastitis])
    y_mastitis = np.ones(n_samples_per_class, dtype=int)

    # Combine & Shuffle
    X = np.vstack([X_healthy, X_mastitis])
    y = np.concatenate([y_healthy, y_mastitis])
    indices = np.random.permutation(len(y))
    X = X[indices]
    y = y[indices]

    # Train Random Forest
    rf = RandomForestClassifier(n_estimators=100, max_depth=6, random_state=42)
    rf.fit(X, y)

    # Save artifact
    output_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "models")
    os.makedirs(output_dir, exist_ok=True)
    model_path = os.path.join(output_dir, "mastitis_rf_model.joblib")

    joblib.dump(rf, model_path)
    print(f"Successfully trained and saved model to: {model_path}")

    # Validate predictions on test points
    test_healthy = np.array([[38.5, 6.5, 4.5]])
    test_mastitic = np.array([[40.1, 7.2, 7.5]])
    pred_h = rf.predict(test_healthy)[0]
    pred_m = rf.predict(test_mastitic)[0]
    print(f"Validation: Healthy sample -> Class {pred_h} (Expected: 0)")
    print(f"Validation: Mastitic sample -> Class {pred_m} (Expected: 1)")

if __name__ == "__main__":
    generate_and_train()
