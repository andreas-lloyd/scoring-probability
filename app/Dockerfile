FROM python:3.6

WORKDIR /app

ADD main.py main.py
ADD base-query.sql base-query.sql
ADD requirements.txt requirements.txt

RUN pip install -r requirements.txt

EXPOSE 5000

CMD [ "gunicorn", "--bind", "0.0.0.0:5000", "main:app" ]
