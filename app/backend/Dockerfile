FROM python:3.10

WORKDIR /app

RUN apt-get update -y

COPY ./requirements.txt requirements.txt

RUN pip install --upgrade pip

RUN pip install --no-cache-dir -r requirements.txt

COPY . ./

EXPOSE 5000

CMD ["uvicorn", "app.app:app", "--host", "0.0.0.0", "--port", "5000", "--reload"]
