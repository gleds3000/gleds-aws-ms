
FROM python:2.7-slim

RUN mkdir /code
WORKDIR /code
ADD requirements.txt /code/
COPY main.py /code/main.py
RUN pip install -r requirements.txt

EXPOSE 80

ENV NAME desafio-globo

CMD ["python", "/code/main.py", "-p 80"]