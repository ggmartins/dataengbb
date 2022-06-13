#!/usr/bin/env python3

from kafka import KafkaConsumer
import json

consumer = KafkaConsumer(
  "registered_user",
  bootstrap_servers="192.168.1.183:9092",
  auto_offset_reset="earliest",
  group_id="consumer_group_A"
)
for msg in consumer:
  print(f"Registered User = {json.loads(msg.value)}")
