#!/bin/bash

# === Configurable Variables ===
AWS_REGION="us-west-2"
BUCKET_NAME="log-platform-tf-state"
DYNAMO_TABLE_NAME="log-platform-tf-locks"

# === Create S3 Bucket ===
echo "🚀 Creating S3 bucket: $BUCKET_NAME in region $AWS_REGION..."
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$AWS_REGION" \
    --create-bucket-configuration LocationConstraint="$AWS_REGION" \
    2>/dev/null || echo "✅ S3 bucket already exists."

# === Enable Versioning ===
echo "🔄 Enabling versioning on bucket..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# === Create DynamoDB Table ===
echo "📦 Creating DynamoDB table for state locking: $DYNAMO_TABLE_NAME..."
aws dynamodb create-table \
    --table-name "$DYNAMO_TABLE_NAME" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAYPERREQUEST \
    --region "$AWS_REGION" \
    2>/dev/null || echo "✅ DynamoDB table already exists."

echo "✅ Backend bootstrap complete."
echo ""
echo "Next Step: Run 'terraform init' in your main Terraform directory."
