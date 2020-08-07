#!/usr/bin/env python

from flask import Flask
from flask import jsonify
import pika

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
    connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
    channel = connection.channel()
    # channel.queue_declare(queue='output', durable=True)
    channel.basic_publish(
        # exchange='output',
        # routing_key='#',
        exchange='',
        routing_key='output',
        body=cmd,
        properties=pika.BasicProperties(
            delivery_mode=2,  # make message persistent
        ))
    connection.close()
    return " [x] Sent: %s" % cmd


# This should be ran in a profile (shouldn't be publicly available)
@app.route('/springcloudcontract/<label>', methods=['POST'])
def springcloudcontract(label):
    if label == "ping_pong":
        return message("pong")
    else:
        raise ValueError('No such label expected.') 
    
