FROM python:3.11-slim

WORKDIR /app

COPY training/requirements.txt /app/training/requirements.txt
RUN python -m pip install --upgrade pip && \
    pip install --no-cache-dir -r /app/training/requirements.txt

COPY training /app/training
COPY scripts /app/scripts

RUN chmod +x /app/training/run_training.sh /app/scripts/trigger_datascience_job_run.sh

ENTRYPOINT ["bash", "/app/training/run_training.sh"]
