import boto3
from botocore.exceptions import ClientError
AWS_SES_REGION = "us-east-1"
#
# Templated by Terraform
#
SENDER = "Email Sender <sender@yourdomain.com>"
RECIPIENT = "recipient@yourdomain.com"
SUBJECT = "New S3 Object Created"
	
def send_email(data):		
	print("Sending email...")
	BODY_TEXT = ("New Object Created:\r\n %s" % (str(data)))
	BODY_HTML = """<html>
	<head></head>
	<body>
	  <h1>New S3 Object Created</h1>
	  <p>New Object Created:</p>
	  <table border="1" cellpadding="10">
		<tbody>
			<tr>
				<td><b>Event Time</b></td>
				<td>%s</td>
			</tr>
			<tr>
				<td><b>Bucket</b></td>
				<td>%s</td>
			</tr>
			<tr>
				<td><b>Key</b></td>
				<td>%s</td>
			</tr>
			<tr>
				<td><b>Event Name</b></td>
				<td>%s</td>
			</tr>
			<tr>
				<td><b>AWS Region</b></td>
				<td>%s</td>
			</tr>
		</tbody>
		</table>
	</body>
	</html>
	""" % (data["eventTime"], data["s3"]["bucket"]["name"], data["s3"]["object"]["key"], data["eventName"], data["awsRegion"])            
	CHARSET = "UTF-8"
	client = boto3.client('ses',region_name=AWS_SES_REGION)
	try:
		response = client.send_email(
			Destination={
				'ToAddresses': [
					RECIPIENT,
				],
			},
			Message={
				'Body': {
					'Html': {
						'Charset': CHARSET,
						'Data': BODY_HTML,
					},
					'Text': {
						'Charset': CHARSET,
						'Data': BODY_TEXT,
					},
				},
				'Subject': {
					'Charset': CHARSET,
					'Data': SUBJECT,
				},
			},
			Source=SENDER
		)
	except ClientError as e:
		print(e.response['Error']['Message'])
	else:
		print("Email sent! Message ID:"),
		print(response['MessageId'])

def lambda_handler(event, context):
	data = event["Records"][0]
	send_email(data)