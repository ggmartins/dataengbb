#!/usr/bin/env python
import os, sys, dotenv
import pika
import ssl
import certifi
import traceback
from os.path import join, dirname
from dotenv import load_dotenv

#based on https://github.com/rabbitmq/rabbitmq-tutorials/blob/master/python/receive.py

def main():
    connection = None
    credentials = pika.PlainCredentials(USER, PASS)

    context = ssl.create_default_context(cafile=certifi.where());
    context.load_cert_chain("tls-gen/basic/result/client_certificate.pem", "tls-gen/basic/result/client_key.pem", CLIENT_KEY_PASS)

    ssl_options = pika.SSLOptions(context, HOST)
    try:
      connection = pika.BlockingConnection(pika.ConnectionParameters(host=HOST,
        port=PORT,
        ssl_options = ssl_options,
        virtual_host='/',
        credentials=credentials))
    except Exception as e:
      exc_type, _, exc_tb = sys.exc_info()
      fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
      print("receive: ({0}) {1} {2} {3}".format(str(e), exc_type, fname, exc_tb.tb_lineno))
      traceback.print_exc()
      sys.exit(1)
    channel = connection.channel()

    channel.queue_declare(queue='hello')

    def callback(ch, method, properties, body):
        print(" [x] Received %r" % body)

    channel.basic_consume(queue='hello', on_message_callback=callback, auto_ack=True)

    print(' [*] Waiting for messages. To exit press CTRL+C')
    channel.start_consuming()

if __name__ == '__main__':
   load_dotenv(verbose=True)

   HOST = os.getenv('RABBITMQ_PIKA_SSL_HOST')
   PORT = os.getenv('RABBITMQ_PIKA_SSL_PORT')
   USER = os.getenv('RABBITMQ_PIKA_SSL_USER')
   PASS = os.getenv('RABBITMQ_PIKA_SSL_PASS')
   CLIENT_KEY_PASS = os.getenv('RABBITMQ_PIKA_SSL_CLIENT_KEY_PASS')

   try:
        main()
   except KeyboardInterrupt:
        print('Interrupted')
        try:
            sys.exit(0)
        except SystemExit:
            os._exit(0)
