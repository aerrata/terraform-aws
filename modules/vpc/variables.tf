variable "environment" {
  type = string
}

variable "project_name" {
  type    = string
  default = "chatbot-app"
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
  description = "Map of public subnets with their CIDR blocks and AZs"
}

variable "private_subnets" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
  description = "Map of private subnets with their CIDR blocks and AZs"
}

variable "tags" {
  type    = map(string)
  default = {}
}
