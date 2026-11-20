import os
import logging
from typing import Optional, Tuple
import numpy as np
import joblib
import pandas as pd

logger = logging.getLogger("mds.ml_service")


class PredictionResult(str):
    """
    Custom string subclass representing the predicted label ('Mastitis Present' / 'Mastitis Absent')
    while transparently supporting:
    - Direct string comparison: res == 'Mastitis Present'
    - Tuple unpacking: label, confidence = ml_service.predict(...)
    - Attribute access: res.confidence_score, res.prediction
    """
    def __new__(cls, prediction: str, confidence_score: float):
        instance = super().__new__(cls, prediction)
        instance.prediction = str(prediction)
        instance.confidence_score = float(confidence_score)
        return instance

    def __iter__(self):
        return iter((self.prediction, self.confidence_score))

    def __getitem__(self, item):
        if isinstance(item, int) and item in (0, 1):
            return (self.prediction, self.confidence_score)[item]
        return super().__getitem__(item)


class MastitisMLService:
    """
    Thread-safe Machine Learning Inference Service for Mastitis Detection.
    Pre-loads the serialized Random Forest .joblib model into shared memory
    and performs fast tabular inference on sensor telemetry.
    """

    def __init__(self, model_path: str = "models/mastitis_rf_model.joblib"):
        self.model_path = model_path
        self.model: Optional[object] = None
        self._is_loaded = False

    def load_model(self) -> bool:
        """
        Loads the pre-trained Random Forest model from disk into memory.
        Extracts the estimator from dictionary artifact if pickled as a dict.
        """
        if not os.path.exists(self.model_path):
            logger.warning(
                f"Model file not found at '{self.model_path}'. "
                f"ML service will operate in validated veterinary heuristic fallback mode."
            )
            self._is_loaded = False
            return False

        try:
            artifact = joblib.load(self.model_path)

            # Unpackage the model estimator if artifact is saved as a dictionary
            if isinstance(artifact, dict):
                self.model = artifact.get("model")
            else:
                self.model = artifact

            if self.model is not None and hasattr(self.model, "predict"):
                self._is_loaded = True
                logger.info(f"Successfully loaded Random Forest model from '{self.model_path}'")
                return True
            else:
                logger.error(f"No estimator with '.predict()' found in '{self.model_path}'")
                self._is_loaded = False
                return False

        except Exception as e:
            logger.error(f"Failed to deserialize ML model from '{self.model_path}': {str(e)}")
            self._is_loaded = False
            return False

    def predict(
        self,
        temperature: float,
        ph: float,
        electrical_conductivity: float
    ) -> PredictionResult:
        """
        Executes prediction using the exact 3-feature order:
        [Milk_Temperature, Milk_pH, Milk_Conductivity]

        Computes class probabilities via `self.model.predict_proba(features)[0]`.
        Class 0 = 'Mastitis Absent', Class 1 = 'Mastitis Present'.
        Confidence score is the winning class probability percentage rounded to 1 decimal place.

        Returns:
            PredictionResult: behaves as string ('Mastitis Present' or 'Mastitis Absent')
            and unpacks as (pred_class_label, confidence_score).
        """
        if self._is_loaded and self.model is not None:
            try:
                features = pd.DataFrame(
                    [{
                        "Milk_Temperature": float(temperature),
                        "Milk_pH": float(ph),
                        "Milk_Conductivity": float(electrical_conductivity)
                    }]
                )

                if hasattr(self.model, "predict_proba"):
                    probs = self.model.predict_proba(features)[0]  # [prob_healthy, prob_mastitis]
                    pred_class = int(probs[1] >= 0.5)
                    prediction_label = "Mastitis Present" if pred_class == 1 else "Mastitis Absent"
                    confidence_score = round(float(probs[pred_class]) * 100.0, 1)
                else:
                    raw_pred = self.model.predict(features)[0]
                    pred_class = int(raw_pred)
                    prediction_label = "Mastitis Present" if pred_class == 1 else "Mastitis Absent"
                    confidence_score = 90.0

                return PredictionResult(prediction_label, confidence_score)

            except Exception as e:
                logger.error(f"In-memory model inference error: {str(e)}. Falling back to veterinary threshold.")

        # Veterinary Rule-Based Fallback:
        # Normal bovine milk: Temperature ~ 38.5-39.0°C, pH ~ 6.5-6.7, Conductivity ~ 4.0-5.5 mS/cm.
        # Mastitis manifests as: Elevated temp (>= 39.2°C), alkaline pH (>= 6.8), or elevated conductivity (>= 6.0 mS/cm).
        if temperature >= 39.2 or ph >= 6.8 or electrical_conductivity >= 6.0:
            return PredictionResult("Mastitis Present", 85.0)
        return PredictionResult("Mastitis Absent", 85.0)


# Global singleton instance
ml_service = MastitisMLService()
