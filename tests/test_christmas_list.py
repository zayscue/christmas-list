import json
import pytest

from src.app import app as flask_app

@pytest.fixture
def app():
  yield flask_app

@pytest.fixture
def client(app):
  return app.test_client()

def test_index(app, client):
    res = client.get('/')
    assert res.status_code == 200
    expected = {"status": 200, "message": "OK"}
    assert expected == json.loads(res.get_data(as_text=True))