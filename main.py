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
    channel.queue_declare(queue='task_queue', durable=True)
    channel.basic_publish(
        exchange='',
        routing_key='task_queue',
        body=cmd,
        properties=pika.BasicProperties(
            delivery_mode=2,  # make message persistent
        ))
    connection.close()
    return " [x] Sent: %s" % cmd


# This should be ran in a profile (shouldn't be publicly available)
@app.route('/springcloudcontract/<label>')
def springcloudcontract(label):
    if label == "foo":
        return message("BLA")
    else:
        raise ValueError('No such label expected.') 
    
