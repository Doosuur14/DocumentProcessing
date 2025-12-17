

variable "cloud_id" {
  description = "Cloud ID for ITIS Cloud Lab"
  type        = string
  default     = "b1g71e95h51okii30p25"
}

variable "folder_id" {
  description = "Folder ID for vvot23"
  type        = string
  default     = "b1gdjscug7mlgo3ggsf5"
}

variable "zone" {
  description = "Yandex Cloud zone"
  type        = string
  default     = "ru-central1-d"
}

variable "student_prefix" {
  description = "Your unique student prefix"
  type        = string
  default     = "faki"
}

variable "bucket_name" {
  description = "Cloud Storage bucket name"
  type        = string
  default     = "faki-doc-bucket"
}

variable "queue_name" {
  description = "Message Queue name"
  type        = string
  default     = "faki-doc-queue"
}

variable "function_name" {
  description = "Cloud Function name"
  type        = string
  default     = "faki-doc-processor"
}

variable "api_gateway_name" {
  description = "API Gateway name"
  type        = string
  default     = "faki-doc-api"
}

variable "ydb_name" {
  description = "YDB database name"
  type        = string
  default     = "faki-doc-db"
}