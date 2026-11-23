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
            logger.error(
                f"Model file not found at '{self.model_path}'. "
                "Random Forest model is required for inference."
            )
            self._is_loaded = False
            self.model = None
            return False

        try:
            artifact = joblib.load(self.model_path)

            # Unpackage the model estimator if artifact is saved as a dictionary
            if isinstance(artifact, dict):
                self.model = artifact.get("model")
            else:
                self.model = artifact

            if (
                self.model is not None
                and hasattr(self.model, "predict")
                and hasattr(self.model, "predict_proba")
            ):
                self._is_loaded = True
                logger.info(f"Successfully loaded Random Forest model from '{self.model_path}'")
                return True
            else:
                logger.error(
                    f"Model in '{self.model_path}' is invalid: must have '.predict()' and '.predict_proba()'"
                )
                self._is_loaded = False
                self.model = None
                return False

        except Exception as e:
            logger.error(f"Failed to deserialize ML model from '{self.model_path}': {str(e)}")
            self._is_loaded = False
            self.model = None
            return False

    def predict(
        self,
        temperature: float,
        ph: float,
        electrical_conductivity: float
    ) -> PredictionResult:
        """
        Executes prediction exclusively using the loaded Random Forest model.
        Features follow the exact 3-feature order:
        [Milk_Temperature, Milk_pH, Milk_Conductivity]

        Classification and confidence score are derived strictly from the Random Forest model:
        - Classification ('Mastitis Present' or 'Mastitis Absent') is determined by the winning class.
        - Confidence score is computed exclusively from the model's class probability (predict_proba)
          for the winning class, scaled to a percentage (0.0 - 100.0) rounded to 1 decimal place.

        Raises:
            RuntimeError: If the model is not loaded, unavailable, or does not support predict_proba.
        """
        if not self._is_loaded or self.model is None:
            raise RuntimeError(
                f"Random Forest model is unavailable at '{self.model_path}'. "
                "Prediction cannot be performed without the loaded model."
            )

        features = pd.DataFrame(
            [{
                "Milk_Temperature": float(temperature),
                "Milk_pH": float(ph),
                "Milk_Conductivity": float(electrical_conductivity)
            }]
        )

        if not hasattr(self.model, "predict_proba"):
            raise RuntimeError(
                "Loaded Random Forest model does not support 'predict_proba'. "
                "Confidence score must be derived strictly from model class probabilities."
            )

        # Pure Random Forest prediction and probability inference
        probs = self.model.predict_proba(features)[0]  # [prob_class_0, prob_class_1]
        classes = getattr(self.model, "classes_", [0, 1])

        raw_pred = self.model.predict(features)[0]
        winning_class = int(raw_pred)

        winning_idx = list(classes).index(winning_class)
        winning_prob = float(probs[winning_idx])

        prediction_label = "Mastitis Present" if winning_class == 1 else "Mastitis Absent"
        confidence_score = round(winning_prob * 100.0, 1)

        return PredictionResult(prediction_label, confidence_score)


# Global singleton instance
ml_service = MastitisMLService()
