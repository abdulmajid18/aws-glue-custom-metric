variable "aws_access_key" {
  type        = string
  description = "AWS Access key"
  sensitive   = true
}

variable "aws_secret_key" {
  type        = string
  description = "AWS Secret key"
  sensitive   = true
}

variable "aws_region" {
  type        = string
  description = "AWS region to use for resource"
  default     = "us-east-1"
}