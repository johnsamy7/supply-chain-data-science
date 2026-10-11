FROM python:3.12-slim

# MLflow server + the PostgreSQL driver it needs to talk to the database
RUN pip install --no-cache-dir "mlflow==3.17.0" "psycopg2-binary>=2.9"

# SQLAlchemy now defaults to psycopg v3 for postgresql:// URLs
RUN pip install --no-cache-dir "psycopg[binary]>=3.2"

EXPOSE 5000