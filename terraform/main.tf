# 1. Service Account
resource "yandex_iam_service_account" "sa" {
  name        = "${var.student_prefix}-doc-sa"
  description = "Service Account for ${var.student_prefix}'s document processing"
}

# 2. Static access key for Service Account
resource "yandex_iam_service_account_static_access_key" "sa_static_key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "Static access key for ${var.student_prefix}'s Cloud Function"
}

# 3. IAM roles
resource "yandex_resourcemanager_folder_iam_member" "ymq_admin" {
  folder_id = var.folder_id
  role      = "ymq.admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "ymq_reader" {
  folder_id = var.folder_id
  role      = "ymq.reader"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "storage_admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "ydb_admin" {
  folder_id = var.folder_id
  role      = "ydb.admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

# 4. Storage Bucket
resource "yandex_storage_bucket" "bucket" {
  bucket = var.bucket_name
  acl    = "private"

  access_key = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_static_key.secret_key

  depends_on = [
    yandex_iam_service_account_static_access_key.sa_static_key
  ]
}

# 5. Message Queue
resource "yandex_message_queue" "queue" {
  name                       = var.queue_name
  visibility_timeout_seconds = 600
  receive_wait_time_seconds  = 20
  message_retention_seconds  = 1209600

  access_key = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_static_key.secret_key

  depends_on = [
    yandex_iam_service_account_static_access_key.sa_static_key
  ]
}

# 6. YDB Serverless
resource "yandex_ydb_database_serverless" "database" {
  name = var.ydb_name
}

# 7. Upload Cloud Function code
resource "yandex_storage_object" "function_code" {
  bucket = yandex_storage_bucket.bucket.id
  key    = "function-${var.student_prefix}.zip"
  source = "${path.module}/../src/function/function.zip"

  access_key = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_static_key.secret_key

  # depends_on to make sure bucket exists
  depends_on = [yandex_storage_bucket.bucket]

  # REMOVE THIS if exists: object_lock_legal_hold_status
  # object_lock_legal_hold_status = "OFF"
}


# 8. Cloud Function
resource "yandex_function" "processor" {
  name               = var.function_name
  description        = "Document processor for ${var.student_prefix}"
  runtime            = "python39"
  entrypoint         = "index.handler"
  memory             = "128"
  execution_timeout  = "60"
  service_account_id = yandex_iam_service_account.sa.id

  user_hash = filebase64sha256("${path.module}/../src/function/function.zip")

  package {
    bucket_name = yandex_storage_bucket.bucket.id
    object_name = yandex_storage_object.function_code.key
  }

  environment = {
    BUCKET_NAME   = yandex_storage_bucket.bucket.bucket
    YDB_ENDPOINT  = yandex_ydb_database_serverless.database.ydb_api_endpoint
    YDB_DATABASE  = yandex_ydb_database_serverless.database.database_path
    YDB_AUTH_MODE = "service_account"

    AWS_ACCESS_KEY_ID     = yandex_iam_service_account_static_access_key.sa_static_key.access_key
    AWS_SECRET_ACCESS_KEY = yandex_iam_service_account_static_access_key.sa_static_key.secret_key

    QUEUE_URL      = yandex_message_queue.queue.id
    REGION         = "ru-central1"
    STUDENT_PREFIX = var.student_prefix
    STUDENT_NAME   = "Факи Доосууур Дорис"
    STUDENT_EMAIL  = "DFaki@stud.kpfu.ru"
  }

  depends_on = [
    yandex_storage_bucket.bucket,
    yandex_message_queue.queue,
    yandex_ydb_database_serverless.database,
    yandex_storage_object.function_code
  ]
}

# 9. Trigger: Queue → Function
resource "yandex_function_trigger" "doc_processor" {
  name = "doc-queue-trigger"

  message_queue {
    queue_id           = yandex_message_queue.queue.arn
    service_account_id = yandex_iam_service_account.sa.id
    batch_cutoff       = 1
    batch_size         = 1
  }

  function {
    id                 = yandex_function.processor.id
    service_account_id = yandex_iam_service_account.sa.id
  }
}



# 10. API Gateway
resource "yandex_api_gateway" "gateway" {
  name        = "${var.student_prefix}-working-api"
  description = "API Gateway for ${var.student_prefix}'s document system"

  spec = <<-EOF
openapi: 3.0.0
info:
  title: Document Processing API
  description: "Student: Факи Доосууур Дорис (${var.student_prefix})"
  version: 1.0.0

paths:
  /upload:
    post:
      x-yc-apigateway-integration:
        type: cloud_ymq
        action: SendMessage
        queue_url: "${yandex_message_queue.queue.id}"
        folder_id: "${var.folder_id}"
        service_account_id: "${yandex_iam_service_account.sa.id}"

  /documents:
    get:
      x-yc-apigateway-integration:
        type: cloud_functions
        function_id: "${yandex_function.processor.id}"
        service_account_id: "${yandex_iam_service_account.sa.id}"
        tag: "$latest"

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
}

# 11. Outputs
output "api_gateway_url" {
  value = yandex_api_gateway.gateway.domain
}


output "resources_created" {
  value = [
    yandex_storage_bucket.bucket.bucket,
    yandex_message_queue.queue.name,
    yandex_ydb_database_serverless.database.name,
    yandex_function.processor.name,
    yandex_api_gateway.gateway.name
  ]
}


