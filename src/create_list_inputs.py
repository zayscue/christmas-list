from flask_inputs import Inputs
from flask_inputs.validators import JsonSchema

schema = {
    "type": "object",
    "properties": {"name": {"type": "string"}},
    "required": ["name"],
}


class CreateListInputs(Inputs):
    json = [JsonSchema(schema=schema)]
