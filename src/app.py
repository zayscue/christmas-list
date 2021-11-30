import uuid
import boto3
import logging
from datetime import datetime
import awsgi
from flask import (
    Flask,
    request,
    jsonify,
)

logging.getLogger().setLevel(logging.INFO)
db = boto3.resource('dynamodb')
app = Flask(__name__)

TABLE_NAME = 'ChristmasLists'

@app.route('/')
def index():
    return jsonify(status=200, message='OK')

@app.route('/api/christmas-list', methods=['POST'])
def create_list():
    data = request.json
    item = {}
    if 'name' in data:
        item['name'] = data['name']
    item['id'] = str(uuid.uuid4())
    item['created_at'] = str(datetime.utcnow())
    table = db.Table(TABLE_NAME)
    table.put_item(Item=item)
    app.logger.info('created new christmas list')
    return jsonify(item)

@app.route('/api/christmas-list/<id>', methods=['GET'])
def get_list(id):
    table = db.Table(TABLE_NAME)
    item = table.get_item(Key={'id': id})
    return jsonify(item['Item'])

def lambda_handler(event, context):
    return awsgi.response(app, event, context, base64_content_types={"image/png"})