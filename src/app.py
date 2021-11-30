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

@app.route('/')
def index():
    return jsonify(status=200, message='OK')

@app.route('/api/christmas-list', methods=['POST'])
def create_list():
    data = request.json
    data['id'] = str(uuid.uuid4())
    data['created_at'] = str(datetime.utcnow())
    table = db.Table('ChristmasLists')
    table.put_item(Item=data)
    app.logger.info('created new christmas list')
    return jsonify(data)

def lambda_handler(event, context):
    return awsgi.response(app, event, context, base64_content_types={"image/png"})