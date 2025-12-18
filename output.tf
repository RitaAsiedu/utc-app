# outputs.tf

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.utc_vpc.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.utc_vpc.cidr_block
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "subnet_details" {
  description = "Details of all subnets"
  value = {
    public_subnets = [
      for i, subnet in aws_subnet.public : {
        id   = subnet.id
        az   = subnet.availability_zone
        cidr = subnet.cidr_block
        name = subnet.tags.Name
      }
    ]
    private_subnets = [
      for i, subnet in aws_subnet.private : {
        id   = subnet.id
        az   = subnet.availability_zone
        cidr = subnet.cidr_block
        name = subnet.tags.Name
      }
    ]
  }
}

# Security Group Outputs
output "security_group_ids" {
  description = "Security Group IDs"
  value = {
    alb_sg      = aws_security_group.alb_sg.id
    bastion_sg  = aws_security_group.bastion_sg.id
    app_sg      = aws_security_group.app_sg.id
    database_sg = aws_security_group.database_sg.id
  }
}

# Instance Outputs
output "bastion_host" {
  description = "Bastion host details"
  value = {
    public_ip  = aws_instance.bastion.public_ip
    private_ip = aws_instance.bastion.private_ip
    id         = aws_instance.bastion.id
  }
  sensitive = false
}

output "app_servers" {
  description = "App server details"
  value = [
    for i, server in aws_instance.app_servers : {
      name       = server.tags.Name
      private_ip = server.private_ip
      id         = server.id
      az         = server.availability_zone
    }
  ]
}

# Load Balancer Outputs
output "load_balancer" {
  description = "Load Balancer details"
  value = {
    dns_name = aws_lb.utc_alb.dns_name
    arn      = aws_lb.utc_alb.arn
    zone_id  = aws_lb.utc_alb.zone_id
  }
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = aws_lb_target_group.utc_tg.arn
}

# Database Outputs
output "database" {
  description = "Database details"
  value = {
    endpoint = aws_db_instance.utc_db.endpoint
    address  = aws_db_instance.utc_db.address
    port     = aws_db_instance.utc_db.port
    name     = aws_db_instance.utc_db.db_name
  }
  sensitive = true  # Hides endpoint in outputs
}

# EFS Outputs
output "efs_file_system" {
  description = "EFS details"
  value = {
    id       = aws_efs_file_system.utc_efs.id
    dns_name = aws_efs_file_system.utc_efs.dns_name
  }
}

# Auto Scaling Outputs
output "auto_scaling_group" {
  description = "Auto Scaling Group details"
  value = {
    name = aws_autoscaling_group.utc_asg.name
    arn  = aws_autoscaling_group.utc_asg.arn
  }
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.utc_lt.id
}

# AMI Output
output "custom_ami_id" {
  description = "Custom AMI ID created from app server"
  value       = aws_ami_from_instance.utcappserver.id
}

# IAM Outputs
output "iam_role_arn" {
  description = "IAM Role ARN for EC2 instances"
  value       = aws_iam_role.ec2_s3_role.arn
}

# S3 Output
output "s3_bucket_name" {
  description = "S3 bucket name for logs"
  value       = aws_s3_bucket.utc_logs.bucket
}

# SNS Output
output "sns_topic_arn" {
  description = "SNS Topic ARN for notifications"
  value       = aws_sns_topic.utc_scaling.arn
}

# Connection Instructions
output "ssh_instructions" {
  description = "SSH connection instructions"
  value = <<-EOT
  To connect to bastion host:
  ssh -i utc-key.pem ec2-user@${aws_instance.bastion.public_ip}
  
  From bastion, connect to app servers:
  ${join("\n  ", [for server in aws_instance.app_servers : "ssh -i utc-key.pem ec2-user@${server.private_ip}"])}
  EOT
}

output "application_url" {
  description = "Application URL"
  value       = "http://${aws_lb.utc_alb.dns_name}"
}

output "health_check_url" {
  description = "Health check URL"
  value       = "http://${aws_lb.utc_alb.dns_name}/"
}

# Cost Estimate (Informational)
output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value = <<-EOT
  Estimated Monthly Costs:
  - 2x t2.micro EC2 instances: ~$15.00
  - 1x ALB: ~$20.00
  - 1x RDS db.t3.micro: ~$12.00
  - 2x NAT Gateways: ~$64.00
  - EFS Storage: ~$6.00 (per GB)
  - Data Transfer: Variable
  
  Total Estimate: ~$117.00 + Data Transfer
  EOT
}

# Important Notes
output "important_notes" {
  description = "Important notes and next steps"
  value = <<-EOT
  IMPORTANT:
  1. Change the default password for RDS immediately
  2. Update the my_ip variable with your actual IP address
  3. Update team_email with your team's email
  4. Save the key pair securely
  5. Monitor CloudWatch alarms for scaling events
  6. Check S3 bucket for application logs
  
  Next Steps:
  - Configure Route 53 DNS records
  - Set up SSL certificate for HTTPS
  - Configure backup policies
  - Set up monitoring and alerts
  EOT
}

# Outputs


output "alb_dns_name" {
  value = aws_lb.utc_alb.dns_name
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "app_server_private_ips" {
  value = aws_instance.app_servers[*].private_ip
}

output "rds_endpoint" {
  value = aws_db_instance.utc_db.endpoint
}

output "efs_dns_name" {
  value = aws_efs_file_system.utc_efs.dns_name
}