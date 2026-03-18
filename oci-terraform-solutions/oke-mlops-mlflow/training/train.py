import argparse
import os
from datetime import datetime

import mlflow
import mlflow.sklearn
from sklearn.datasets import load_iris
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Train a basic Iris model and log to MLflow")
    parser.add_argument("--mlflow-tracking-uri", default=os.getenv("MLFLOW_TRACKING_URI", "http://129.80.216.101"))
    parser.add_argument("--experiment-name", default=os.getenv("MLFLOW_EXPERIMENT_NAME", "basic-iris-training-pipeline"))
    parser.add_argument("--registered-model-name", default=os.getenv("MLFLOW_REGISTERED_MODEL_NAME", "iris-logreg-model"))
    parser.add_argument("--test-size", type=float, default=0.2)
    parser.add_argument("--random-state", type=int, default=42)
    parser.add_argument("--max-iter", type=int, default=200)
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    mlflow.set_tracking_uri(args.mlflow_tracking_uri)
    mlflow.set_experiment(args.experiment_name)

    iris = load_iris()
    X, y = iris.data, iris.target

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
        mlflow.log_param("dataset", "iris")
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

        print(f"Run logged to MLflow. Accuracy={accuracy:.4f}")
        print(f"Tracking URI: {args.mlflow_tracking_uri}")
        print(f"Experiment: {args.experiment_name}")
        print(f"Registered model name: {args.registered_model_name}")


if __name__ == "__main__":
    main()
