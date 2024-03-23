import boto3
import uuid
import json

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('tasks')

def handler(event, context):
    # Parse request body
    body = json.loads(event['body'])
    
    # Generate task_id
    task_id = str(uuid.uuid4())
    
    # Extract task details from request body
    task_name = body.get('task_name')
    cron_expression = body.get('cron_expression')
    
    # Insert task into DynamoDB
    response = table.put_item(
        Item={
            'task_id': task_id,
            'task_name': task_name,
            'cron_expression': cron_expression
        }
    )
    
    # Prepare response
    response_body = {
        'message': 'Task created successfully',
        'task_id': task_id
    }
    
    return {
        'statusCode': 200,
        'body': json.dumps(response_body)
    }
