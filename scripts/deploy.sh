#!/bin/bash
# Deployment script for Факи Доосууур Дорис

set -e

echo "=== Document Processing System Deployment ==="
echo "Student: Факи Доосууур Дорис"
echo "Group: 11-200"
echo "Email: DFaki@stud.kpfu.ru"
echo "Student Prefix: faki"
echo "============================================"

echo ""
echo "1. Preparing Cloud Function package..."
cd src/function
echo "Installing dependencies..."
pip install -r requirements.txt -t . --quiet
echo "Creating function.zip..."
zip -r function.zip . -x "*.git*" "*.pyc" "__pycache__/*" "*.zip" --quiet
cd ../..

echo ""
echo "2. Initializing Terraform..."
cd terraform
terraform init

echo ""
echo "3. Planning deployment..."
terraform plan

echo ""
echo "4. Applying Terraform configuration..."
read -p "Continue with deployment? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deploying..."
    terraform apply -auto-approve
    echo ""
    echo "=== DEPLOYMENT COMPLETE ==="
    echo ""
    terraform output
    echo ""
else
    echo "Deployment cancelled."
fi