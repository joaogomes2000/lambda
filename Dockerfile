FROM python:3.11-slim

WORKDIR /app
COPY lambda_function.py .

CMD ["python", "lambda_function.py"]
