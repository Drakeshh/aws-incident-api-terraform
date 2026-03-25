import json
import boto3
import uuid
from datetime import datetime, timezone

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('incidents')

def lambda_handler(event, context):
    http_method = event.get('httpMethod')
    path_parameters = event.get('pathParameters') or {}
    incident_id = path_parameters.get('id')

    try:
        if http_method == 'POST':
            return create_incident(event)
        elif http_method == 'GET' and incident_id:
            return get_incident(incident_id)
        elif http_method == 'GET':
            return list_incidents()
        elif http_method == 'PUT' and incident_id:
            return update_incident(incident_id, event)
        elif http_method == 'DELETE' and incident_id:
            return delete_incident(incident_id)
        else:
            return response(400, {'error': 'Invalid request'})

    except Exception as e:
        return response(500, {'error': str(e)})


def create_incident(event):
    body = json.loads(event.get('body', '{}'))

    if not body.get('title'):
        return response(400, {'error': 'title is required'})
    if not body.get('severity'):
        return response(400, {'error': 'severity is required'})

    now = datetime.now(timezone.utc).isoformat()
    incident = {
        'id':          str(uuid.uuid4()),
        'title':       body['title'],
        'severity':    body['severity'],
        'status':      body.get('status', 'open'),
        'description': body.get('description', ''),
        'created_at':  now,
        'updated_at':  now
    }

    table.put_item(Item=incident)
    return response(201, incident)


def get_incident(incident_id):
    result = table.get_item(Key={'id': incident_id})
    item = result.get('Item')

    if not item:
        return response(404, {'error': 'Incident not found'})

    return response(200, item)


def list_incidents():
    result = table.scan()
    items = result.get('Items', [])
    items.sort(key=lambda x: x.get('created_at', ''), reverse=True)
    return response(200, {'incidents': items, 'count': len(items)})


def update_incident(incident_id, event):
    body = json.loads(event.get('body', '{}'))

    result = table.get_item(Key={'id': incident_id})
    if not result.get('Item'):
        return response(404, {'error': 'Incident not found'})

    allowed_fields = ['title', 'severity', 'status', 'description']
    update_expressions = []
    expression_values = {}
    expression_names = {}

    for field in allowed_fields:
        if field in body:
            update_expressions.append(f'#{field} = :{field}')
            expression_values[f':{field}'] = body[field]
            expression_names[f'#{field}'] = field

    if not update_expressions:
        return response(400, {'error': 'No valid fields to update'})

    update_expressions.append('#updated_at = :updated_at')
    expression_values[':updated_at'] = datetime.now(timezone.utc).isoformat()
    expression_names['#updated_at'] = 'updated_at'

    table.update_item(
        Key={'id': incident_id},
        UpdateExpression='SET ' + ', '.join(update_expressions),
        ExpressionAttributeValues=expression_values,
        ExpressionAttributeNames=expression_names
    )

    updated = table.get_item(Key={'id': incident_id})
    return response(200, updated['Item'])


def delete_incident(incident_id):
    result = table.get_item(Key={'id': incident_id})
    if not result.get('Item'):
        return response(404, {'error': 'Incident not found'})

    table.delete_item(Key={'id': incident_id})
    return response(200, {'message': f'Incident {incident_id} deleted successfully'})


def response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body, default=str)
    }