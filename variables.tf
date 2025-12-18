
# variable.tf

# Required Variables (You MUST provide these)
variable "my_ip" {
  description = "Your public IP address for bastion host access"
  type        = string
  default     = "0.0.0.0/0"  # CHANGE THIS TO YOUR IP like "123.45.67.89/32"
}

variable "team_email" {
  description = "Email for SNS notifications"
  type        = string
  default     = "rasabea@gmail.com"  
}

# Optional Variables (with defaults)
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "utc-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "environment" {
  description = "environment name"
  type        = string
  default     = "dev"
}

variable "team_name" {
  description = "Team name"
  type        = string
  default     = "config management"
}

# Subnet Configuration
variable "public_subnet_count" {
  description = "Number of public subnets (3 for 3 AZs)"
  type        = number
  default     = 3
}

variable "private_subnet_count" {
  description = "Number of private subnets (6 for 3 AZs)"
  type        = number
  default     = 6
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# Instance Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for instances"
  type        = string
  default     = "ami-0c02fb55956c7d316"  # Amazon Linux 2
}

variable "key_name" {
  description = "Key pair name"
  type        = string
  default     = "utc-key"
}

# Database Configuration
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "utcdb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "utcuser"
}

variable "db_password" {
  description = "Database password"
  type        = string
  default     = "utcdev12345"
  sensitive   = true  # Marks this as sensitive (won't show in output)
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

# Auto Scaling Configuration
variable "asg_min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 5
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

# Load Balancer Configuration
variable "lb_name" {
  description = "Load balancer name"
  type        = string
  default     = "utc-alb"
}

variable "target_group_name" {
  description = "Target group name"
  type        = string
  default     = "utc-target-group"
}

# Scaling Thresholds
variable "scale_out_cpu" {
  description = "CPU threshold for scaling out"
  type        = number
  default     = 80
}

variable "scale_in_cpu" {
  description = "CPU threshold for scaling in"
  type        = number
  default     = 30
}

# Tag Variables
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project = "UTC"
    ManagedBy = "Terraform"
  }
}