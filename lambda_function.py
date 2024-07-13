import base64
import io
import json
import os

from flask import Flask, send_file
import segno
from fpdf import FPDF
import boto3

from pymongo.mongo_client import MongoClient
from pymongo.server_api import ServerApi

uri = "mongodb+srv://jonybigude100:P9zlPB2aYSDxgEye@cluster0.m36npri.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"
client = MongoClient(uri, server_api=ServerApi('1'))
db = client.teste
coll = db.teste
app = Flask(__name__)

@app.route('/generate', methods=['GET'])
def generate_pdf():
    mydict = {"name": "John", "address": "Highway 38"}
    x = coll.insert_one(mydict)
    a = coll.find_one(sort=[('$natural', -1)])

    qrcode = segno.make_qr(f'{x.inserted_id}')
    qrcode_file = "/tmp/teste.png"  # Save to /tmp directory
    qrcode.save(qrcode_file, scale=5, light="red")

    return send_file(qrcode_file, as_attachment=True)



@app.route('/', methods=['GET'])
def lambda_handler(event, context):
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
    pdf_file = "/tmp/sample.pdf"
    pdf.output(pdf_file, 'F')
    s3 = boto3.client('s3')
    print('tem')
    try:
        s3.upload_file('/tmp/teste.png', 'testejoaogomes2024', '/pdf/teste.png')
    except Exception as err:
        print(err)

    return {
        'statusCode': 200
    }
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=4000)