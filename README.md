# Really Simple Terraform Script to Configure Formatted Email Notifications for Newly Created S3 Objects

This module is used to package and deploy a Lambda function which is triggered by the creation of object(s) in a specified S3 bucket, when triggered the lambda function sends a formatted email message via SES.    

The following variables are required, these will either rendered in the lambda function code before it is packaged and uploaded, or will be used in the Terraform script (`main.tf`).  

| variable     | description                                   |
|--------------|-----------------------------------------------|
| s3_bucket    | Bucket being monitored                        |
| sender_email | Email address of the sender (verified by SES) |
| sender_name  | Name of the sender                            |
| recipient    | Recipient's email address (verified by SES)   |
| subject      | Email subject                                 |

> NOTE: The *sender_email* and *recipient* email addresses must be registered and verified with SES.  SES is not available in every AWS region, pick one that is generally closest to your particular reason (but it really doesn't matter for this purpose).