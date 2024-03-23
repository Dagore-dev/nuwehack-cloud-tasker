import boto3
import json

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('tasks')
s3 = boto3.client('s3')

def fetch_task_from_dynamodb():
    # Query a task item from DynamoDB
    response = table.scan()
    items = response['Items']
    
    if not items:
        return None
    
    return items[0]

def handler(event, context):
    # Fetch a task from DynamoDB
    task = fetch_task_from_dynamodb()
    
    if not task:
        return {
            'statusCode': 404,
            'body': json.dumps({'message': 'No tasks found'})
        }
    
    # Store the task in the 'taskstorage' S3 bucket
    s3.put_object(
        Bucket='taskstorage',
        Key=f"{task['task_id']}.json",
        Body=json.dumps(task),
        ContentType='application/json'
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Task stored successfully'})
    }
