FROM python:3.11.4-alpine3.18

# Diretório padrão onde o container vai iniciar
WORKDIR /app

COPY requirements.txt .
COPY app.py .
COPY templates templates/
COPY static static/

# Instala os requisitos
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 5000

CMD ["flask", "run", "--host=0.0.0.0"]

