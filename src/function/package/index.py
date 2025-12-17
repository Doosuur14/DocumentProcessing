import json
import os
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    Simple handler that processes messages from queue
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Log all environment variables (for debugging)
    env_vars = {
        'BUCKET_NAME': os.environ.get('BUCKET_NAME'),
        'QUEUE_URL': os.environ.get('QUEUE_URL'),
        'YDB_ENDPOINT': os.environ.get('YDB_ENDPOINT'),
        'STUDENT_NAME': os.environ.get('STUDENT_NAME'),
        'STUDENT_PREFIX': os.environ.get('STUDENT_PREFIX')
    }
    logger.info(f"Environment variables: {json.dumps(env_vars)}")
    
    try:
        # Parse the message from event
        messages = event.get('messages', [])
        
        if not messages:
            logger.warning("No messages in event")
            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'No messages to process'})
            }
        
        for message in messages:
            message_body = message.get('details', {}).get('message', {}).get('body', '{}')
            logger.info(f"Processing message: {message_body}")
            
            # Try to parse JSON message
            try:
                data = json.loads(message_body)
                doc_name = data.get('name', 'unknown')
                doc_url = data.get('url', '')
                
                logger.info(f"Document: {doc_name}, URL: {doc_url}")
                
                # Store in YDB (simplified)
                # For now, just log
                logger.info(f"Would store document {doc_name} in database")
                
            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse message as JSON: {e}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Message processed successfully',
                'student': os.environ.get('STUDENT_NAME'),
                'prefix': os.environ.get('STUDENT_PREFIX'),
                'processed_count': len(messages)
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing message: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
