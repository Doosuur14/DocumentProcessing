# API Gateway domain
output "api_gateway_domain" {
  description = "API Gateway domain"
  value       = yandex_api_gateway.gateway.domain
}

# Cloud Function ID
output "cloud_function_id" {
  description = "Cloud Function ID"
  value       = yandex_function.processor.id
}

# Storage bucket URL
output "storage_bucket_url" {
  description = "Storage bucket URL"
  value       = "https://storage.yandexcloud.net/${yandex_storage_bucket.bucket.bucket}"
}

# Message Queue URL
output "message_queue_url" {
  description = "Message Queue URL"
  value       = yandex_message_queue.queue.arn
}

# YDB endpoint
output "ydb_endpoint" {
  description = "YDB serverless connection string"
  value       = yandex_ydb_database_serverless.database.ydb_full_endpoint
}

# YDB database path
output "ydb_database" {
  description = "YDB database path"
  value       = yandex_ydb_database_serverless.database.database_path
}


output "debug_spec_length" {
  value = length(<<-EOF
openapi: 3.0.0
info:
  title: Document Processing API
  description: "API for document processing system. Student: Факи Доосууур Дорис (${var.student_prefix})"
  version: 1.0.0

paths:
  /upload:
    post:
      x-yc-apigateway-integration:
        type: cloud_ymq
        action: SendMessage
        queue_id: "${yandex_message_queue.queue.id}"
        folder_id: "${var.folder_id}"
        service_account_id: "${yandex_iam_service_account.sa.id}"

  /documents:
    get:
      x-yc-apigateway-integration:
        type: cloud_ydb
        action: Scan
        database: "/ru-central1/b1g71e95h51okii30p25/etnultd398bl0e7ckm9q"
        table: "documents"
        service_account_id: "${yandex_iam_service_account.sa.id}"

  /document/{key}:
    get:
      parameters:
        - name: key
          in: path
          required: true
          schema:
            type: string
      x-yc-apigateway-integration:
        type: object_storage
        bucket: "${yandex_storage_bucket.bucket.id}"
        object: '{key}'
        service_account_id: "${yandex_iam_service_account.sa.id}"
EOF
  )
}
