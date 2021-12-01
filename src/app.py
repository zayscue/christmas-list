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
from inputs.create_list_inputs import CreateListInputs

logging.getLogger().setLevel(logging.INFO)
db = boto3.resource("dynamodb")
app = Flask(__name__)

TABLE_NAME = "ChristmasLists"


@app.route("/")
def index():
    return jsonify(status=200, message="OK")


@app.route("/api/christmas-list", methods=["POST"])
def create_list():
    inputs = CreateListInputs(request)
    if not inputs.validate():
        app.logger.error("Invalid Create Christmas List Request")
        return jsonify(errors=inputs.errors), 400
    data = request.get_json()
    item = {
        "name": data["name"],
        "id": str(uuid.uuid4()),
        "created_at": str(datetime.utcnow()),
    }
    table = db.Table(TABLE_NAME)
    table.put_item(Item=item)
    app.logger.info("Created New Christmas List")
    return jsonify(item), 201


@app.route("/api/christmas-list/<id>", methods=["GET"])
def get_list(id):
    table = db.Table(TABLE_NAME)
    get_item_response = table.get_item(Key={"id": id})
    if "Item" not in get_item_response:
        app.logger.error("Christmas List Not Found")
        return '', 404
    return jsonify(get_item_response["Item"])


def lambda_handler(event, context):
    return awsgi.response(app, event, context, base64_content_types={"image/png"})
