# resource "aws_datasync_location_azure_blob" "example" {
#   agent_arns          = [aws_datasync_agent.example.arn]
#   authentication_type = "SAS"
#   container_url       = "https://example.com/path"

#   sas_configuration {
#     token = "sp=r&st=2023-12-20T14:54:52Z&se=2023-12-20T22:54:52Z&spr=https&sv=2021-06-08&sr=c&sig=aBBKDWQvyuVcTPH9EBp%2FXTI9E%2F%2Fmq171%2BZU178wcwqU%3D"
#   }
# }

# ### Instance Profile for EC2 datasync agent
# resource "aws_iam_instance_profile" "datasync-instance-profile" {
#   name = "datasync-instance-profile"
#   role = aws_iam_role.datasync-instance-role.name

#   lifecycle {
#     create_before_destroy = false
#   }
# }

# data "aws_ami" "datasync-agent" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["aws-datasync-*"]
#   }

#   owners = ["633936118553"] # AMZN
# }

# resource "aws_security_group" "datasync-instance" {
#   name        = "datasync-agent-Instance-sg"
#   description = "Datasync Security Group - datasync-agent-Instance"
#   vpc_id      = var.vpc_id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = [var.vpc_cidr_block]
#     description = "SSH"
#   }

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = [var.vpc_cidr_block]
#     description = "HTTP"
#   }

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [var.vpc_cidr_block]
#     description = "HTTPS"
#   }

#   egress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "HTTPS for Datasync agent to AWS Service endpoint"
#   }

#   egress {
#     from_port   = 53
#     to_port     = 53
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "DNS"
#   }

#   egress {
#     from_port   = 53
#     to_port     = 53
#     protocol    = "udp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "DNS"
#   }

#   egress {
#     from_port   = 123
#     to_port     = 123
#     protocol    = "udp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "NTP"
#   }

#   egress {
#     from_port   = 2049
#     to_port     = 2049
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "EFS/NFS"
#   }

#   tags = {
#     Name = "datasync-agent-Instance-sg"
#   }
# }

# ## Management Key Pair
# resource "aws_key_pair" "management" {
#   key_name   = "management"
#   public_key = file(var.public_key)
# }

# resource "aws_instance" "datasync" {
#   ami                    = data.aws_ami.datasync-agent.id
#   instance_type          = var.instance_type
#   vpc_security_group_ids = ["${aws_security_group.datasync-instance.id}"]
#   subnet_id              = var.ds_instance_subnet_id

#   metadata_options {
#     http_endpoint = "enabled"
#     http_tokens   = "required"
#   }

#   root_block_device {
#     encrypted = true
#   }

#   disable_api_termination = false
#   iam_instance_profile    = aws_iam_instance_profile.datasync-instance-profile.name
#   key_name                = aws_key_pair.management.id

#   monitoring = true

#   associate_public_ip_address = false

#   tags = {
#     Name = "datasync-agent-instance-${var.datasync_agent_name}"
#   }
# }

# ### DataSync Agent

# resource "aws_datasync_agent" "datasync_agent" {
#   depends_on = [aws_instance.datasync]
#   ip_address = aws_instance.datasync.private_ip
#   name       = var.datasync_agent_name
#   vpc_endpoint_id = var.datasync_endpoint
#   lifecycle {
#     create_before_destroy = false
#   }

#   tags = {
#     Name = var.datasync_agent_name
#   }
# }
