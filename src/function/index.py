import json
import os
import uuid
import urllib.request
from datetime import datetime
import boto3
import ydb


def handler(event, context):
    """
    Handles:
    1. API Gateway GET /documents
    2. Message Queue events (document uploads)
    """
    print(f"Event received: {json.dumps(event, default=str)[:500]}...")

   
    if isinstance(event, dict) and event.get('httpMethod') == 'GET':
       
        path = event.get('path') or event.get('resource')
        if path == '/documents':
            return get_documents_list()
        else:
            return {
                'statusCode': 404,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': 'Not found'})
            }

   
    elif isinstance(event, dict) and 'messages' in event:
        return process_document(event)

   
    else:
        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': 'Unknown event type'})
        }


def get_documents_list():
    try:
        driver_config = ydb.DriverConfig(
            endpoint=os.environ['YDB_ENDPOINT'],
            database=os.environ['YDB_DATABASE'],
            credentials=ydb.iam.MetadataUrlCredentials()
        )
        driver = ydb.Driver(driver_config)
        driver.wait(timeout=5)

        session = driver.table_client.session().create()

        query = "SELECT * FROM documents ORDER BY created_at DESC LIMIT 20"
        result_sets = session.transaction().execute(
            query, commit_tx=True, settings=ydb.BaseRequestSettings().with_timeout(5)
        )

        documents = []
        for row in result_sets[0].rows:
            documents.append({
                'id': str(row.id) if hasattr(row, 'id') else '',
                'name': str(row.name) if hasattr(row, 'name') else '',
                'key': str(row.key) if hasattr(row, 'key') else '',
                'original_url': str(row.original_url) if hasattr(row, 'original_url') else '',
                'created_at': str(row.created_at) if hasattr(row, 'created_at') else '',
                'size': int(row.size) if hasattr(row, 'size') else 0
            })

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(documents, default=str)
        }

    except Exception as e:
        print(f"YDB Query Error: {e}")
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps([])
        }


def process_document(event):
    try:
        message = event['messages'][0]
        body = json.loads(message['details']['message']['body'])

        name = body['name']
        url = body['url']
        doc_id = str(uuid.uuid4())

        print(f"Processing document: {name} from {url}")

       
        response = urllib.request.urlopen(url)
        file_content = response.read()
        file_size = len(file_content)

     
        s3 = boto3.client(
            's3',
            endpoint_url='https://storage.yandexcloud.net',
            aws_access_key_id=os.environ['AWS_ACCESS_KEY_ID'],
            aws_secret_access_key=os.environ['AWS_SECRET_ACCESS_KEY']
        )
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
        file_key = f"documents/{name}_{timestamp}.pdf"

        s3.put_object(
            Bucket=os.environ['BUCKET_NAME'],
            Key=file_key,
            Body=file_content,
            ContentType='application/pdf'
        )
        print(f"Saved to storage: {file_key} ({file_size} bytes)")

      
        save_to_ydb(doc_id, name, file_key, url, file_size)

        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'status': 'processed',
                'key': file_key,
                'name': name,
                'size': file_size,
                'id': doc_id
            })
        }

    except Exception as e:
        print(f"Process Error: {e}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': str(e)})
        }


def save_to_ydb(doc_id, name, key, url, size):
    try:
        driver_config = ydb.DriverConfig(
            endpoint=os.environ['YDB_ENDPOINT'],
            database=os.environ['YDB_DATABASE'],
            credentials=ydb.iam.MetadataUrlCredentials()
        )
        driver = ydb.Driver(driver_config)
        driver.wait(timeout=5)

        session = driver.table_client.session().create()

        insert_query = f"""
        INSERT INTO documents (id, name, key, original_url, created_at, size)
        VALUES ("{doc_id}", "{name}", "{key}", "{url}", CurrentUtcTimestamp(), {size})
        """

        session.transaction().execute(insert_query, commit_tx=True)
        print(f"Saved to YDB: {doc_id}")

    except Exception as e:
        print(f"YDB Save Error: {e}")


