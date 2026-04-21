#!/bin/bash

echo "Creating S3 bucket and DynamoDB table..."

# Создание S3 бакета
aws s3 mb s3://myapp-terraform-state-dev --region us-east-1

# Включение версионирования
aws s3api put-bucket-versioning \
    --bucket myapp-terraform-state-dev \
    --versioning-configuration Status=Enabled

# Включение шифрования
aws s3api put-bucket-encryption \
    --bucket myapp-terraform-state-dev \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# Создание DynamoDB таблицы
aws dynamodb create-table \
    --table-name myapp-terraform-locks-dev \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1

echo "Waiting for table to be created..."
sleep 10

# Проверка
aws s3 ls | grep myapp-terraform-state-dev
aws dynamodb list-tables --region us-east-1 | grep myapp-terraform-locks-dev

echo "✅ S3 bucket and DynamoDB table created successfully!"

# Теперь запустите terraform init
terraform init
