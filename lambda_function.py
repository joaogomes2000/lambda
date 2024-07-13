import base64
import io
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

uri = os.getenv('CONN')
client = MongoClient(uri, server_api=ServerApi('1'))
db = client.teste
coll = db.teste

def lambda_handler(event, context):
    bucket_name = os.getenv('Bucket_Name')
    file_path = os.getenv('FILE_PATH')
    logger.info(f'bucket_name = {bucket_name}')
    logger.info(f'file_path = {file_path}')
    mydict = { "name": "John", "address": "Highway 38" }

    x = coll.insert_one(mydict)
    a = coll.find_one(sort=[('$natural', -1)])

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
    pdf_file = "/tmp/sample.pdf"
    pdf.output(pdf_file, 'F')
    s3 = boto3.client('s3')
    print('tem')
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
