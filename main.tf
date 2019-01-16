#
# Module Provider
#

provider "aws" {
	region = "ap-southeast-2"
	shared_credentials_file = "~/.aws/credentials"
	profile                 = "default"
}

#
# Create IAM Role and Policy for Lambda Function
#

resource "aws_iam_role" "lambda_s3_object_notification" {
  name = "lambda_s3_object_notification"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_s3_object_notification_policy" {
  name = "lambda_s3_object_notification_policy"
  role = "${aws_iam_role.lambda_s3_object_notification.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "ses:SendEmail",
                "ses:SendRawEmail"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

#
# Substitute Variables in the Lambda Function Template
#

data "template_file" "lambda_function" {
	template = "${file("${path.module}/template/lambda_s3_object_notification.py")}"
	vars {
		sender_email    = "${var.sender_email}"
		sender_name 	= "${var.sender_name}"
		recipient 		= "${var.recipient}"
		subject 		= "${var.subject}"
	}
}

#
# Render Templated Python Function
#

resource "local_file" "rendered_template" {
    content     = "${data.template_file.lambda_function.rendered}"
    filename 	= "${path.module}/rendered/lambda_s3_object_notification.py"
}

#
# Package Lambda Function Source Code in a ZIP Archive
#

data "archive_file" "lambda_s3_object_notification_zip" {
  type = "zip"
  output_path = "${path.module}/lambda_s3_object_notification.zip"
  source_dir = "${path.module}/rendered/"
  depends_on = ["local_file.rendered_template"]
}

locals {
  zip_file_name = "${substr(data.archive_file.lambda_s3_object_notification_zip.output_path, length(path.cwd) + 1, -1)}"
  depends_on = ["data.archive_file.lambda_s3_object_notification_zip"]
}

#
# Create Lambda Function
#

resource "aws_lambda_function" "lambda_s3_object_notification" {
  filename = "${local.zip_file_name}"
  source_code_hash = "${base64sha256(file("${local.zip_file_name}"))}"
  function_name    = "s3_object_notifications_via_ses"
  timeout		   = 10  
  role             = "${aws_iam_role.lambda_s3_object_notification.arn}"
  handler          = "lambda_s3_object_notification.lambda_handler"
  runtime          = "python2.7"
}

#
# Configure S3 Object Notifications
#

data "aws_s3_bucket" "s3_bucket" {
  bucket = "${var.s3_bucket}"
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_s3_object_notification.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${data.aws_s3_bucket.s3_bucket.arn}"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "${var.s3_bucket}"
  lambda_function {
    lambda_function_arn = "${aws_lambda_function.lambda_s3_object_notification.arn}"
    events              = ["s3:ObjectCreated:Put"]
  }
}