import json
import os
import logging
import segno
from reportlab.pdfgen import canvas
from reportlab.lib import colors
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
    if res and res.get('used') is False:
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
                    }),
                'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            }}
    else:
        return {
                    'statusCode': 500,
                    'body': json.dumps({
                        'Message': f'No values updates for _id {_id}!!'
                    }),
                'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            }}
    

def lambda_handler(event, context):
    http_method = event['requestContext']['http']['method']
    if http_method == "GET":
        headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        }
        bucket_name = os.getenv('Bucket_Name')
        
        logger.info(f'bucket_name = {bucket_name}')
        mydict = { "name": "John", "address": "Highway 38", 'used': False }

        logger.info('Getting the secret key and the access key')
        aws_access_key_id = os.getenv('ACCESSKEY')
        aws_secret_access_key = os.getenv('SECRETKEY')
        x = coll.insert_one(mydict)
    
        qrcode = segno.make_qr(f'{x.inserted_id}')
        qrcode.save("/tmp/teste.png", scale=5, light="red")

        fileName = '/tmp/sample.pdf'
        documentTitle = 'sample'
        subTitle = 'Purchase'
        textLines = [
            'Purchase completed successfully',
            'Price: 20€',
        ]
        image = '/tmp/teste.png'

        pdf = canvas.Canvas(fileName)
        pdf.setTitle(documentTitle)
        pdf.setFillColorRGB(0, 0, 255)
        pdf.setFont("Courier-Bold", 24)
        pdf.drawCentredString(300, 770, subTitle)
        pdf.line(30, 750, 550, 750)
        text = pdf.beginText(40, 720)
        text.setFont("Courier", 18)
        text.setFillColor(colors.red)
        
        for line in textLines:
            text.textLine(line)
            
        pdf.drawText(text)
        pdf.drawInlineImage(image, 120, 400)
        pdf.save()

        s3 = boto3.client('s3',  aws_access_key_id = aws_access_key_id, aws_secret_access_key = aws_secret_access_key)
        file_path = f'pdf/{str(x.inserted_id)}_sample.pdf'
        try:
            s3.upload_file(fileName, bucket_name, file_path)
        except Exception as err:
            return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({
                'headers': headers,
                'Message': f'{str(err)}'
            })}

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'headers': headers,
                'Message': 'Success!!',
                'file_name': file_path.split('/')[-1]
            })}
        
    if http_method == 'POST':
        try:
            body = json.loads(event.get('body', '{}'))
        except json.JSONDecodeError:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'headers': headers,'message': 'Invalid JSON'})
                }
        _id = body.get('id')
        logger.info(f'id: {_id}')  
        return verify_qrcode(_id)
