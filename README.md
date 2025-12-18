# UTC AWS Infrastructure

Terraform project deploying a production-ready, multi-tier web application on AWS with auto-scaling, RDS, EFS, and centralized logging.

Architecture
3 Availability Zones for high availability

Auto-scaling group (CPU-based: 80% out, 30% in)

Application Load Balancer with health checks

RDS MySQL in private subnets

EFS shared storage for app servers

Bastion host for secure SSH access

S3 bucket for centralized logging

SNS notifications for scaling events

Security Features
Least-privilege security groups (ALB → App → DB only)

Private subnet isolation with NAT gateways

IAM roles for EC2 S3 access (no credentials on instances)

SSH restricted to your IP only

Post-Deployment
Test application: curl http://$(terraform output -raw load_balancer)

SSH to bastion: Use generated utc-key.pem file

Check logs in S3 bucket: terraform output s3_bucket_name

Monitor scaling via CloudWatch/SNS emails
