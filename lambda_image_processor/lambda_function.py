import boto3
from PIL import Image
import io

def lambda_handler(event, context):
    print("Lambda triggered")
    return {
        "statusCode": 200,
        "body": "Image processing done!"
    }
