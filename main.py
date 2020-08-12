#!/usr/bin/env python

from flask import Flask
from flask import jsonify
from kafka import KafkaProducer
import pika
import os
import json

app = Flask(__name__)

@app.route('/')
def hello_world():
	return jsonify(
        message='Hello, World!'
    )

@app.route('/add-job/<cmd>')
def add(cmd):
    return message(cmd)

def message(cmd):
    if 'MESSAGING_TYPE' in os.environ and os.environ['MESSAGING_TYPE'] == "kafka":
        return kafkaMessage(cmd)
    else:
        return rabbitMessage(cmd)

def rabbitMessage(cmd):
    connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
    channel = connection.channel()
    # channel.queue_declare(queue='output', durable=True)
    channel.basic_publish(
        # exchange='output',
        # routing_key='#',
        exchange='output',
        routing_key='#',
        body=cmd,
        properties=pika.BasicProperties(
            delivery_mode=2,  # make message persistent
        ))
    connection.close()
    return " [x] Sent via Rabbit: %s" % cmd

def kafkaMessage(cmd):
    producer = KafkaProducer(bootstrap_servers='localhost:9092', value_serializer=lambda v: json.dumps(v).encode('utf-8'))
    producer.send('output', cmd)
    return " [x] Sent via Kafka: %s" % cmd

if 'CONTRACT_TEST' in os.environ:
    # This should be ran in a profile (shouldn't be publicly available)
    @app.route('/springcloudcontract/<label>', methods=['POST'])
    def springcloudcontract(label):
        if label == "ping_pong":
            return rabbitMessage('{"message":"pong"}')
        elif label == "kafka_ping_pong":
            return kafkaMessage({"message":"pong"})
        else:
            raise ValueError('No such label expected.') 
        
