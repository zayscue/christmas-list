import requests

def create_list(event, context):
  res = requests.get('https://w3schools.com/python/demopage.htm')
  return {
    'statusCode': 200,
    'body': res.text
  }