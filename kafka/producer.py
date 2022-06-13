#!/usr/bin/env python3
from kafka import KafkaProducer
import json
import time
from faker import Faker

fake = Faker()

def get_registered_user():
  return {
    "name": fake.name(),
    "address": fake.address(),
    "created_at": fake.year()
  }

def json_serializer(data):
  return json.dumps(data).encode("utf-8")


producer = KafkaProducer(bootstrap_servers="192.168.1.183:9092", value_serializer=json_serializer)


while True:
  registered_user = get_registered_user()
  print(registered_user)
  producer.send("registered_user", registered_user)
  time.sleep(4)
