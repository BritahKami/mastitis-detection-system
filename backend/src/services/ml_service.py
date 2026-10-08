import os
import logging
from typing import Optional
import numpy as np
import joblib

logger = logging.getLogger("mds.ml_service")


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
        If the file does not exist, logs a warning and falls back to veterinary heuristics.
        """
        if not os.path.exists(self.model_path):
            logger.warning(
                f"Model file not found at '{self.model_path}'. "
                f"ML service will operate in validated veterinary heuristic fallback mode."
            )
            self._is_loaded = False
            return False

        try:
            self.model = joblib.load(self.model_path)
            self._is_loaded = True
            logger.info(f"Successfully loaded Random Forest model from '{self.model_path}'")
            return True
        except Exception as e:
            logger.error(f"Failed to deserialize ML model from '{self.model_path}': {str(e)}")
            self._is_loaded = False
            return False

    def predict(
        self,
        temperature: float,
        ph: float,
        electrical_conductivity: float
    ) -> str:
        """
        Executes prediction using the exact 3-feature order:
        [temperature, pH, electrical_conductivity]

        Returns:
            'Mastitis Present' (class 1) or 'Mastitis Absent' (class 0)
        """
        # If model is loaded, run scikit-learn Random Forest inference
        if self._is_loaded and self.model is not None:
            try:
                # Shape features as 2D array [1, 3] with exact feature order
                features = np.array(
                    [[float(temperature), float(ph), float(electrical_conductivity)]],
                    dtype=np.float64
                )
                raw_pred = self.model.predict(features)[0]
                prediction_class = int(raw_pred)

                if prediction_class == 1:
                    return "Mastitis Present"
                else:
                    return "Mastitis Absent"
            except Exception as e:
                logger.error(f"In-memory model inference error: {str(e)}. Falling back to veterinary threshold.")

        # Veterinary Rule-Based Fallback:
        # Normal bovine milk: Temperature ~ 38.5-39.0°C, pH ~ 6.5-6.7, Conductivity ~ 4.0-5.5 mS/cm.
        # Mastitis manifests as: Elevated temp (>= 39.2°C), alkaline pH (>= 6.8), or elevated conductivity (>= 6.0 mS/cm).
        if temperature >= 39.2 or ph >= 6.8 or electrical_conductivity >= 6.0:
            return "Mastitis Present"
        return "Mastitis Absent"


# Global singleton instance
ml_service = MastitisMLService()
