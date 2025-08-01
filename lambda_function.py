'''import json
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
from datetime import datetime


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
                    })}
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
        
        query_params = event['queryStringParameters']
        client_name = query_params.get('name')
        employee_name = query_params.get('employeeName')
        bucket_name = os.getenv('Bucket_Name')
        
        logger.info(f'bucket_name = {bucket_name}')
        price = '20'
        mydict = { "name": client_name, "employeeName": employee_name, 'price': price ,'used': False }

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
            f'name: {client_name}',
            f'Price: {price}€',
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
        pdf.drawInlineImage(image, 100, 450)
        pdf.save()

        s3 = boto3.client('s3',  aws_access_key_id = aws_access_key_id, aws_secret_access_key = aws_secret_access_key)
        current_date_str = datetime.now().strftime("%Y%m%d%H%M%S")
        file_path = f'pdf/{str(current_date_str)}{str(x.inserted_id)}_{client_name.replace(' ', '_')}_ticket.pdf'
        try:
            s3.upload_file(fileName, bucket_name, file_path)
        except Exception as err:
            return {
            'statusCode': 500,
            'body': json.dumps({
                'Message': f'{str(err)}'
            })}
        url = s3.generate_presigned_url(
            ClientMethod='get_object',
            Params={'Bucket': bucket_name, 'Key': file_path},
            ExpiresIn=3600
        )
        return {
            'statusCode': 200,
            'body': json.dumps({
                'Message': 'Success!!',
                'file_name': file_path.split('/')[-1],
                'url': url
            })}
        
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
        return verify_qrcode(_id)
'''
from fastapi import FastAPI
#from sqlalchemy import create_engine, Column, Integer, String
#from sqlalchemy.orm import declarative_base, sessionmaker
from mangum import Mangum  # Adiciona o adaptador

app = FastAPI()

#Base = declarative_base()

#class User(Base):
#    __tablename__ = "users"
#    id = Column(Integer, primary_key=True)
#    name = Column(String)
    

#class Applications(Base):
#    __tablename__ = "applications"
#    id = Column(Integer, primary_key=True)
#    app_name = Column(String)

#engine = create_engine(
#    "postgresql+psycopg2://postgres:JpMg_2000@db.qlomonqglusxhrbhdezx.supabase.co:5432/postgres"
#)
#Session = sessionmaker(bind=engine)
#session = Session()
#Base.metadata.create_all(engine)


    
@app.get("/")
def root(name: str = "world"):
   
#    new_user = User(name=name)
#    session.add(new_user)
#    session.commit()
    return {"message": f"Hello {name}"}

handler = Mangum(app)

