import argparse
import json
import os
from datetime import datetime
from io import BytesIO
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any

import mlflow
import mlflow.sklearn
import oci
import pandas as pd
from sklearn.datasets import load_iris
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Train a basic Iris model and log to MLflow")
    parser.add_argument("--mlflow-tracking-uri", default=os.getenv("MLFLOW_TRACKING_URI", ""))
    parser.add_argument("--experiment-name", default=os.getenv("MLFLOW_EXPERIMENT_NAME", "basic-iris-training-pipeline"))
    parser.add_argument("--registered-model-name", default=os.getenv("MLFLOW_REGISTERED_MODEL_NAME", "iris-logreg-model"))
    parser.add_argument("--object-storage-namespace", default=os.getenv("OBJECT_STORAGE_NAMESPACE", ""))
    parser.add_argument("--dataset-bucket-name", default=os.getenv("DATASET_BUCKET_NAME", ""))
    parser.add_argument("--dataset-object-name", default=os.getenv("DATASET_OBJECT_NAME", ""))
    parser.add_argument("--dataset-target-column", default=os.getenv("DATASET_TARGET_COLUMN", "target"))
    parser.add_argument("--model-backup-bucket-name", default=os.getenv("MODEL_BACKUP_BUCKET_NAME", ""))
    parser.add_argument("--model-backup-object-prefix", default=os.getenv("MODEL_BACKUP_OBJECT_PREFIX", "models"))
    parser.add_argument("--test-size", type=float, default=0.2)
    parser.add_argument("--random-state", type=int, default=42)
    parser.add_argument("--max-iter", type=int, default=200)
    return parser.parse_args()


def object_storage_client() -> oci.object_storage.ObjectStorageClient:
    signer = oci.auth.signers.get_resource_principals_signer()
    return oci.object_storage.ObjectStorageClient(config={}, signer=signer)


def resolve_namespace(client: oci.object_storage.ObjectStorageClient, provided_namespace: str) -> str:
    if provided_namespace:
        return provided_namespace
    return client.get_namespace().data


def load_dataset(args: argparse.Namespace) -> tuple[Any, Any, str]:
    if args.dataset_bucket_name and args.dataset_object_name:
        try:
            client = object_storage_client()
            namespace = resolve_namespace(client, args.object_storage_namespace)
            response = client.get_object(namespace, args.dataset_bucket_name, args.dataset_object_name)
            df = pd.read_csv(BytesIO(response.data.content))
            if args.dataset_target_column not in df.columns:
                raise ValueError(
                    f"Target column '{args.dataset_target_column}' not present in dataset columns: {list(df.columns)}"
                )

            y = df[args.dataset_target_column]
            X = df.drop(columns=[args.dataset_target_column])
            source = f"objectstorage://{namespace}/{args.dataset_bucket_name}/{args.dataset_object_name}"
            print(f"Loaded dataset from Object Storage: {source}")
            return X, y, source
        except Exception as exc:
            print(f"WARNING: Failed to load dataset from Object Storage ({exc}). Falling back to sklearn iris dataset.")

    iris = load_iris()
    return iris.data, iris.target, "sklearn.datasets.load_iris"


def backup_model_to_object_storage(
    args: argparse.Namespace,
    model: LogisticRegression,
    run_name: str,
    metrics: dict[str, float],
) -> str | None:
    if not args.model_backup_bucket_name:
        print("MODEL_BACKUP_BUCKET_NAME not set. Skipping model backup upload.")
        return None

    client = object_storage_client()
    namespace = resolve_namespace(client, args.object_storage_namespace)
    timestamp = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
    object_prefix = f"{args.model_backup_object_prefix.rstrip('/')}/{args.registered_model_name}/{timestamp}"

    with TemporaryDirectory() as tmp_dir:
        export_dir = Path(tmp_dir) / "exported_model"
        mlflow.sklearn.save_model(sk_model=model, path=str(export_dir))

        metadata = {
            "run_name": run_name,
            "registered_model_name": args.registered_model_name,
            "mlflow_tracking_uri": args.mlflow_tracking_uri,
            "experiment_name": args.experiment_name,
            "metrics": metrics,
            "timestamp_utc": timestamp,
        }
        metadata_path = Path(tmp_dir) / "metadata.json"
        metadata_path.write_text(json.dumps(metadata, indent=2), encoding="utf-8")

        for file_path in export_dir.rglob("*"):
            if not file_path.is_file():
                continue
            relative = file_path.relative_to(export_dir).as_posix()
            object_name = f"{object_prefix}/model/{relative}"
            with file_path.open("rb") as fh:
                client.put_object(namespace, args.model_backup_bucket_name, object_name, fh)

        with metadata_path.open("rb") as fh:
            client.put_object(namespace, args.model_backup_bucket_name, f"{object_prefix}/metadata.json", fh)

    backup_uri = f"objectstorage://{namespace}/{args.model_backup_bucket_name}/{object_prefix}"
    print(f"Uploaded model backup to: {backup_uri}")
    return backup_uri


def main() -> None:
    args = parse_args()
    if not args.mlflow_tracking_uri:
        raise ValueError("MLFLOW_TRACKING_URI is required. Set it explicitly or via Data Science job environment variables.")

    mlflow.set_tracking_uri(args.mlflow_tracking_uri)
    mlflow.set_experiment(args.experiment_name)

    X, y, dataset_source = load_dataset(args)

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=args.test_size,
        random_state=args.random_state,
        stratify=y,
    )

    model = LogisticRegression(max_iter=args.max_iter)
    model.fit(X_train, y_train)
    preds = model.predict(X_test)
    accuracy = accuracy_score(y_test, preds)

    run_name = f"ds-job-train-{datetime.utcnow().strftime('%Y%m%d-%H%M%S')}"

    with mlflow.start_run(run_name=run_name):
        mlflow.log_param("dataset", dataset_source)
        mlflow.log_param("dataset_source", dataset_source)
        mlflow.log_param("model_type", "LogisticRegression")
        mlflow.log_param("max_iter", args.max_iter)
        mlflow.log_param("test_size", args.test_size)
        mlflow.log_param("random_state", args.random_state)

        mlflow.log_metric("test_accuracy", float(accuracy))

        mlflow.sklearn.log_model(
            sk_model=model,
            artifact_path="model",
            registered_model_name=args.registered_model_name,
        )

        mlflow.log_text(
            f"accuracy={accuracy:.6f}\nexperiment={args.experiment_name}\n",
            "training_summary.txt",
        )

        backup_uri = backup_model_to_object_storage(
            args=args,
            model=model,
            run_name=run_name,
            metrics={"test_accuracy": float(accuracy)},
        )
        if backup_uri:
            mlflow.log_param("model_backup_uri", backup_uri)

        print(f"Run logged to MLflow. Accuracy={accuracy:.4f}")
        print(f"Tracking URI: {args.mlflow_tracking_uri}")
        print(f"Experiment: {args.experiment_name}")
        print(f"Registered model name: {args.registered_model_name}")


if __name__ == "__main__":
    main()
