FROM python:3.10-slim

# Instalar dependencias del sistema necesarias para Aeneas y FFmpeg
RUN apt-get update && apt-get install -y \
    ffmpeg \
    espeak \
    libespeak-dev \
    python3-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Instalar dependencias de Python
RUN pip install --no-cache-dir fastapi uvicorn python-multipart requests

# Instalar Aeneas (puede requerir compilación)
RUN pip install --no-cache-dir aeneas

# Copiar el código del backend
COPY main.py .

EXPOSE 8000

CMD ["uvicorn", "main.py:app", "--host", "0.0.0.0", "--port", "8000"]
