import boto3
from PIL import Image
import io

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    object_key = event['Records'][0]['s3']['object']['key']
    
    # Download image from S3
    response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
    image = Image.open(io.BytesIO(response['Body'].read()))

    # Resize Image
    image = image.resize((500, 500))

    # Upload processed image to destination bucket
    output_key = f"processed/{object_key}"
    buffer = io.BytesIO()
    image.save(buffer, format='JPEG')
    buffer.seek(0)

    s3_client.put_object(
        Bucket="processed-images-bucket",
        Key=output_key,
        Body=buffer,
        ContentType="image/jpeg"
    )
    
    return {"status": "Success", "message": f"Image processed and saved as {output_key}"}
