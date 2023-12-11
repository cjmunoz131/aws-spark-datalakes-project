variable "vpc_cidr_block" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "datasync_agent_name" {
  type    = string
  default = "STEDI-datasync-agent"
}

variable "instance_type" {
  type    = string
  default = "m5.2xlarge"
}

variable "public_key" {
  type = string
}

variable "ds_instance_subnet_id" {
  type = string
}