variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-north-1"


}
variable "your_Ip" {
  description = "Your current public ip for ssh access(e.g 102.89.23.73/32)"
  type        = string
  sensitive   = true

}
variable "key_name" {
  description = "Name of existing EC2 key pair for ssh access(optional but Recommended)"
  type        = string
  default     = "tech_corpkey"

}

variable "instance_type_bastion" {
  type        = string
  description = "The size of the bastion instance"
  default     = "t3.micro"
}
variable "instance_type_web" {
  type        = string
  description = "The size of the webserver instance"
  default     = "t3.micro"
}
variable "instance_type_db" {
  type        = string
  description = "The size of the database instance"
  default     = "t3.small"
}


