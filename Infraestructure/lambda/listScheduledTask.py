import boto3
import json

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('tasks')

def handler(event, context):
    # Query all tasks from DynamoDB
    response = table.scan()
    items = response['Items']
    
    # Prepare response
    response_body = {
        'tasks': items
    }
    
    return {
        'statusCode': 200,
        'body': json.dumps(response_body)
    }
