from flask import Flask
from redis import Redis
import os
import sys
import logging
import configparser

parser = configparser.ConfigParser()
parser.read("config/mars.config")

app = Flask(__name__)

redis = Redis(host=os.environ.get('REDIS_HOST', parser.get("config", "redis_address")), port=6379)
logFileName = '/mnt/logs/' + os.environ.get('hostname') + '-info.log'

@app.route('/')
def hello():
    redis.incr('hits')
    
    logging.basicConfig(filename=logFileName,level=logging.DEBUG)
    return 'Hello Container World! I have been seen %s times.\n' % redis.get('hits')

if __name__ == "__main__":
    app.run(host=parser.get("config", "server_address"), port=5000, debug=True)



