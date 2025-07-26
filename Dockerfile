FROM python:3.11-slim

WORKDIR /app

COPY . .

RUN pip install fastapi uvicorn
RUN pip install sqlalchemy psycopg2

CMD ["uvicorn", "lambda_function:app", "--host", "0.0.0.0", "--port", "80"]
