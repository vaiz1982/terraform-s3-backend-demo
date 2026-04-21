# Terraform AWS Infrastructure with S3 Backend and DynamoDB Locking

## 📋 Project Overview

This Terraform project deploys an AWS EC2 instance with a web server, configured with:
- **S3 Backend** for remote state storage
- **DynamoDB** for state locking
- **EC2 instance** with tag `Type: Demo`
- **Auto-healing web server** (Apache/httpd)
- **Elastic IP** for persistent public access

## 🏗️ Architecture
┌─────────────────────────────────────────────────────────┐
│ AWS Account │
├─────────────────────────────────────────────────────────┤
│ ┌──────────────┐ ┌──────────────┐ │
│ │ S3 Bucket │ │ DynamoDB │ │
│ │ (State) │────▶│ (Locking) │ │
│ └──────────────┘ └──────────────┘ │
│ │
│ ┌──────────────────────────────────────┐ │
│ │ VPC (Default) │ │
│ │ ┌────────────────────────────────┐ │ │
│ │ │ Security Group │ │ │
│ │ │ ✅ SSH (22) │ │ │
│ │ │ ✅ HTTP (80) │ │ │
│ │ └────────────────────────────────┘ │ │
│ │ │ │
│ │ ┌────────────────────────────────┐ │ │
│ │ │ EC2 Instance │ │ │
│ │ │ 📦 Amazon Linux 2 │ │ │
│ │ │ 🏷️ Type: Demo │ │ │
│ │ │ 🌐 Apache Web Server │ │ │
│ │ └────────────────────────────────┘ │ │
│ │ │ │
│ │ ┌────────────────────────────────┐ │ │
│ │ │ Elastic IP (EIP) │ │ │
│ │ │ 🔗 Static Public IP │ │ │
│ │ └────────────────────────────────┘ │ │
│ └──────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘

text

## 📁 Project Structure
.
├── main.tf # Main infrastructure configuration
├── outputs.tf # Output variables
├── backend.tf # S3 backend configuration
├── variables.tf # Input variables (optional)
├── terraform.tfvars # Variable values (gitignored)
├── .gitignore # Git ignore rules
└── README.md # This file

text

## 🚀 Prerequisites

- **AWS Account** with appropriate permissions
- **Terraform** >= 1.0 installed
- **AWS CLI** configured with credentials
- **SSH key pair** for EC2 access

## 🔧 Installation

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd terraform-s3-demo
2. Configure AWS credentials
bash
# Method 1: AWS CLI
aws configure
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name: us-east-1

# Method 2: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
3. Import or create SSH key pair
bash
# Check if key exists
aws ec2 describe-key-pairs --key-names my-key-pair

# If not, create new key
aws ec2 create-key-pair \
    --key-name my-key-pair \
    --query 'KeyMaterial' \
    --output text > my-key-pair.pem
chmod 400 my-key-pair.pem
4. Create S3 bucket and DynamoDB table (first time only)
bash
# Create S3 bucket with unique name
BUCKET_NAME="myapp-terraform-state-dev-$(openssl rand -hex 4)"
aws s3 mb s3://${BUCKET_NAME} --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket ${BUCKET_NAME} \
    --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
    --table-name myapp-terraform-locks-dev \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1
5. Update backend configuration
Edit backend.tf with your actual bucket name:

hcl
terraform {
  backend "s3" {
    bucket         = "your-actual-bucket-name"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "myapp-terraform-locks-dev"
  }
}
6. Initialize Terraform
bash
terraform init
7. Review the plan
bash
terraform plan
8. Apply the configuration
bash
terraform apply -auto-approve








📊 Outputs

terraform output

instance_id          = "i-08bc070fe8b95a87b"
instance_public_ip   = "54.xxx.xxx.xxx"
instance_private_ip  = "172.31.xx.xx"
instance_public_dns  = "ec2-54-xxx-xxx-xxx.compute-1.amazonaws.com"
web_url              = "http://54.xxx.xxx.xxx"
elastic_ip           = "54.xxx.xxx.xxx"







🌐 Access the Web Server

# Via curl
curl $(terraform output -raw web_url)

# Open in browser
echo "Open in browser: $(terraform output -raw web_url)"








🧹 Clean Up Resources


terraform destroy -auto-approve






📝 Important Notes
Security Considerations
🔒 S3 bucket has public access blocked

🔐 Bucket versioning is enabled for state recovery

📦 State is encrypted at rest (AES-256)

🔑 SSH access is open to all IPs (restrict in production)

🌐 HTTP is open to all (for demo purposes)

Production Improvements
Restrict SSH to specific CIDR blocks

Use KMS encryption for S3

Enable S3 bucket logging

Use IAM roles instead of access keys

Implement tagging strategy

Add CloudWatch monitoring

Configure auto-scaling










Troubleshooting
Error: BucketAlreadyExists
# Solution: Use unique bucket name
BUCKET_NAME="myapp-terraform-state-dev-$(date +%s)"






Error: AccessDeniedException (DynamoDB)
# Add DynamoDB permissions to your IAM user
aws iam attach-user-policy \
    --user-name TerraformUser \
    --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess




Error: InvalidKeyPair.NotFound
# Create and import SSH key
ssh-keygen -t rsa -b 2048 -f my-key-pair -N ""
aws ec2 import-key-pair --key-name my-key-pair --public-key-material fileb://my-key-pair.pub






📚 Resources Created
Resource	Type	Purpose
S3 Bucket	aws_s3_bucket	Terraform state storage
DynamoDB Table	aws_dynamodb_table	State locking
Security Group	aws_security_group	Firewall rules (SSH, HTTP)
EC2 Instance	aws_instance	Web server (Apache)
Elastic IP	aws_eip	Static public IP






📖 Related Commands

# List all resources
terraform state list

# Show specific resource
terraform state show aws_instance.demo

# Refresh state
terraform refresh

# Validate configuration
terraform validate

# Format code
terraform fmt

# Generate documentation
terraform-docs markdown . > README.md














🤝 Contributing
Fork the repository

Create feature branch (git checkout -b feature/amazing-feature)

Commit changes (git commit -m 'Add amazing feature')

Push to branch (git push origin feature/amazing-feature)

Open Pull Request

📄 License
This project is licensed under the MIT License.

👤 Author
Created for Terraform AWS Infrastructure Demo

🙏 Acknowledgments
HashiCorp Terraform Documentation

AWS Provider Documentation

Community Best Practices

✅ Project Status: Production Ready
EOF









Добавьте файлы в Git (если используете):
# Инициализируйте Git репозиторий
git init

# Добавьте файлы
git add .gitignore README.md main.tf outputs.tf backend.tf

# Сделайте коммит
git commit -m "Initial commit: Terraform AWS infrastructure with S3 backend and DynamoDB locking"

# Добавьте remote (замените на ваш URL)
# git remote add origin https://github.com/your-username/your-repo.git

# Отправьте на GitHub
# git push -u origin main






Ваша полная конфигурация сейчас:
✅ main.tf - EC2 инстанс, Security Group, Elastic IP
✅ outputs.tf - Выходные данные (IP, DNS, URL)
✅ backend.tf - S3 + DynamoDB для хранения state
✅ terraform.tfvars - Переменные (если есть)

Всё готово! Ваше задание выполнено:
✅ Создан S3 бакет для tfstate

✅ Настроено хранение tfstate в S3

✅ Добавлена блокировка через DynamoDB

✅ Создан EC2 инстанс с тэгом Type: Demo

Можете сдавать задание! 🎉
