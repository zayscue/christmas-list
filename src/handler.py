import pandas as pd
import numpy as np


def create_list(event, context):
  df = pd.DataFrame(np.random.randint(0,100,size=(15, 4)), columns=list('ABCD'))
  return {
    'statusCode': 200,
    'body': df.to_json(orient='records')
  }