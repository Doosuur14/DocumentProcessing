#!/bin/bash
# Destroy all resources
set -e

echo "=== Destroying Document Processing System ==="
echo "Student: Факи Доосууур Дорис"
echo "Prefix: faki"
echo ""

cd terraform

echo "1. Planning destruction..."
terraform plan -destroy

echo ""
echo "2. Destroying resources..."
read -p "Are you sure you want to destroy ALL resources? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Destroying..."
    terraform destroy -auto-approve
    echo ""
    echo "✅ All resources destroyed"
    echo ""
    echo "=== REMEMBER ==="
    echo "1. Push your code to GitHub/GitLab"
    echo "2. Record and upload screencast to Yandex Disk"
    echo "3. Submit the report form by 14.12.2025 23:59:59"
else
    echo "❌ Destruction cancelled"
fi