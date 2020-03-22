#!/usr/bin/env python
import pika
import requests

class Caller:

	_api_base_url = None

	def __init__(self, api_base_url) -> None:
		super().__init__()
		self._api_base_url = api_base_url

	connection = pika.BlockingConnection(
		pika.ConnectionParameters(host='localhost'))
	channel = connection.channel()

	channel.queue_declare(queue='hello')


	def callback(ch, method, properties, body):
		print(" [x] Received %r" % body)
		requests.get(url="{}/add-job/<cmd>".format(self._api_base_url))


	channel.basic_consume(
		queue='hello', on_message_callback=callback, auto_ack=True)

	print(' [*] Waiting for messages. To exit press CTRL+C')
	channel.start_consuming()