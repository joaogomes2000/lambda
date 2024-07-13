import json
import os
import logging
import segno
from fpdf import FPDF
import boto3
logger = logging.getLogger()
logger.setLevel("INFO")
from pymongo.mongo_client import MongoClient
from pymongo.server_api import ServerApi
from bson.objectid import ObjectId

# Load environment variables from .env file

uri = os.getenv('CONN')
client = MongoClient(uri, server_api=ServerApi('1'))
db = client.teste
coll = db.teste

def verify_qrcode(_id):
    res = coll.find_one({'_id': ObjectId(str(_id))})
    if res:
        query = {"_id": ObjectId(str(_id))}
        new_val = {"$set": {"used": True}}
        result = coll.update_one(query, new_val)
        if result.modified_count > 0:
            logger.info("Document updated successfully.")
        else:
            logger.info("No document found matching the query.")
        return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'Message': f'Success!! for _id {_id}'
                    })
                }
    else:
        return {
                    'statusCode': 500,
                    'body': json.dumps({
                        'Message': f'No values updates for _id {_id}!!'
                    })
                }
    

def lambda_handler(event, context):
    http_method = event['requestContext']['http']['method']
    if http_method == "GET":
        bucket_name = os.getenv('Bucket_Name')
        file_path = os.getenv('FILE_PATH')
        logger.info(f'bucket_name = {bucket_name}')
        logger.info(f'file_path = {file_path}')
        mydict = { "name": "John", "address": "Highway 38", 'used': False }

        logger.info('Getting the secret key and the access key')
        aws_access_key_id = os.getenv('ACCESSKEY')
        aws_secret_access_key = os.getenv('SECRETKEY')
        x = coll.insert_one(mydict)
    
        qrcode = segno.make_qr(f'{x.inserted_id}')
        qrcode.save("/tmp/teste.png", scale=5, light="red")

        pdf = FPDF()
        pdf.set_title('Sample PDF')
        pdf.add_page()
        pdf.set_font("Arial", '', size=12)

        # Add text to PDF
        pdf.cell(200, 10, txt='Purchase completed successfully', ln=True)
        pdf.cell(200, 10, txt='Price 20', ln=True)
        pdf.image('/tmp/teste.png', x=10, y=30, w=50, h=50)
        pdf_file = f"/tmp/{str(x.inserted_id)}sample.pdf"
        pdf.output(pdf_file, 'F')
        s3 = boto3.client('s3',  aws_access_key_id = aws_access_key_id, aws_secret_access_key = aws_secret_access_key)
        try:
            s3.upload_file(pdf_file, bucket_name, file_path)
        except Exception as err:
            return {
            'statusCode': 500,
            'body': json.dumps({
                'Message': f'{str(err)}'
            })}

        return {
            'statusCode': 200,
            'body': json.dumps({
                'Message': 'Success!!'
            })
        }
    if http_method == 'POST':
        try:
            body = json.loads(event.get('body', '{}'))
        except json.JSONDecodeError:
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Invalid JSON'})
            }
        _id = body.get('id')
        logger.info(f'id: {_id}')
        verify_qrcode(_id)
        
    return {
        'statusCode': 200,
        'body': json.dumps('Success')
    }
