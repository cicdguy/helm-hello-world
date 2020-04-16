FROM python:3-alpine
RUN pip install flask && \
    mkdir -p /app
COPY app.py /app
WORKDIR /app
ENTRYPOINT ["python3", "/app/app.py"]
