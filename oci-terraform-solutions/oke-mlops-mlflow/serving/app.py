import os
from typing import Any
import logging

import mlflow
import pandas as pd
from fastapi import FastAPI, HTTPException
from mlflow import MlflowClient
from pydantic import BaseModel, Field


MLFLOW_TRACKING_URI = os.getenv("MLFLOW_TRACKING_URI", "http://129.80.216.101")
MODEL_NAME = os.getenv("MLFLOW_MODEL_NAME", "iris-logreg-model")
MODEL_STAGE = os.getenv("MLFLOW_MODEL_STAGE", "Production")
logger = logging.getLogger(__name__)


class PredictRequest(BaseModel):
    inputs: list[list[float]] = Field(
        ...,
        description="2D feature array. Example: [[5.1, 3.5, 1.4, 0.2]]",
    )


class PredictResponse(BaseModel):
    model_uri: str
    predictions: list[Any]


def load_latest_production_model() -> tuple[Any, str]:
    mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)
    client = MlflowClient()

    versions = client.get_latest_versions(MODEL_NAME, stages=[MODEL_STAGE])
    if versions:
        latest = max(versions, key=lambda v: int(v.version))
    else:
        all_versions = list(client.search_model_versions(f"name='{MODEL_NAME}'"))
        if not all_versions:
            raise RuntimeError(f"No versions found for model '{MODEL_NAME}'")
        latest = max(all_versions, key=lambda v: int(v.version))
        logger.warning(
            "No versions in stage '%s' for model '%s'. Falling back to latest version: %s",
            MODEL_STAGE,
            MODEL_NAME,
            latest.version,
        )

    model_uri = f"models:/{MODEL_NAME}/{latest.version}"
    model = mlflow.pyfunc.load_model(model_uri)
    return model, model_uri


app = FastAPI(title="MLflow Serving API", version="1.0.0")
app.state.model = None
app.state.model_uri = None


@app.on_event("startup")
def startup_event() -> None:
    try:
        model, model_uri = load_latest_production_model()
        app.state.model = model
        app.state.model_uri = model_uri
    except Exception:
        logger.exception("Model load failed during startup. Service will start but /predict returns 503 until model is available.")
        app.state.model = None
        app.state.model_uri = None


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "tracking_uri": MLFLOW_TRACKING_URI,
        "model_name": MODEL_NAME,
        "model_stage": MODEL_STAGE,
        "model_uri": app.state.model_uri or "not_loaded",
    }


@app.post("/predict", response_model=PredictResponse)
def predict(request: PredictRequest) -> PredictResponse:
    if app.state.model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    if not request.inputs:
        raise HTTPException(status_code=400, detail="inputs cannot be empty")

    features = pd.DataFrame(request.inputs)
    predictions = app.state.model.predict(features)

    return PredictResponse(
        model_uri=app.state.model_uri,
        predictions=[p.item() if hasattr(p, "item") else p for p in predictions],
    )
