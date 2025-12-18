# Get public IP for bastion
data "http" "my_ip" {
  url = "https://ifconfig.me/ip"
}

# Bastion Host
# main.tf - Bastion instance (simplified)

resource "aws_instance" "bastion" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = aws_key_pair.utc_key.key_name

  # Wait for instance to be ready
  provisioner "local-exec" {
    command = "echo 'Bastion IP: ${self.public_ip}'"
  }

  tags = {
    Name = "utc-bastion"
    env  = "dev"
    team = "config management"
  }
}

#   provisioner "file" {
#     content     = tls_private_key.utc_key.private_key_pem
#     destination = "/home/ec2-user/utc-key.pem"

#     connection {
#       type        = "ssh"
#       user        = "ec2-user"
#       private_key = tls_private_key.utc_key.private_key_pem
#       host        = self.public_ip
#     }
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "chmod 400 /home/ec2-user/utc-key.pem"
#     ]

#     connection {
#       type        = "ssh"
#       user        = "ec2-user"
#       private_key = tls_private_key.utc_key.private_key_pem
#       host        = self.public_ip
#     }
#   }
# }


# App Servers
resource "aws_instance" "app_servers" {
  count = 2

  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type          = "t2.micro"
  subnet_id              = element([aws_subnet.private[0].id, aws_subnet.private[2].id], count.index)
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name               = aws_key_pair.utc_key.key_name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd.x86_64
              systemctl start httpd.service
              systemctl enable httpd.service
              echo "Hello World from $(hostname -f)" > /var/www/html/index.html
              EOF

  tags = {
    Name = "appserver-${element(["1a", "1b"], count.index)}"
    env  = "dev"
    team = "config management"
  }
}

# Target Group
resource "aws_lb_target_group" "utc_tg" {
  name     = "utc-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.utc_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    env  = "dev"
    team = "config management"
  }
}

# Target Group Attachment
resource "aws_lb_target_group_attachment" "app_servers" {
  count            = 2
  target_group_arn = aws_lb_target_group.utc_tg.arn
  target_id        = aws_instance.app_servers[count.index].id
  port             = 80
}

# ALB
resource "aws_lb" "utc_alb" {
  name               = "utc-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    env  = "dev"
    team = "config management"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.utc_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.utc_tg.arn
  }
}

# RDS Database
resource "aws_db_subnet_group" "utc_db_subnet" {
  name       = "utc-db-subnet-group"
  subnet_ids = [aws_subnet.private[1].id, aws_subnet.private[3].id]

  tags = {
    env  = "dev"
    team = "config management"
  }
}

resource "aws_db_instance" "utc_db" {
  identifier           = "utc-dev-database"
  engine              = "mysql"
  engine_version      = "5.7"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  db_name             = "utcdb"
  username            = "utcuser"
  password            = "utcdev12345"
  db_subnet_group_name = aws_db_subnet_group.utc_db_subnet.name
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  skip_final_snapshot = true
  publicly_accessible = false

  tags = {
    env  = "dev"
    team = "config management"
  }
}

# IAM Role for S3 Access
resource "aws_iam_role" "ec2_s3_role" {
  name = "utc-ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  # tags = {
  #   Name = "utc-ec2-s3-role"
  #   env  = "dev"
  #   team = "config management"
  # }
}
resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "utc-ec2-profile"
  role = aws_iam_role.ec2_s3_role.name
}

# EFS File System
resource "aws_efs_file_system" "utc_efs" {
  creation_token = "utc-efs"

  tags = {
    Name = "utc-efs"
    env  = "dev"
    team = "config management"
  }
}

resource "aws_efs_mount_target" "efs_mount" {
  count           = 2
  file_system_id  = aws_efs_file_system.utc_efs.id
  subnet_id       = element([aws_subnet.private[0].id, aws_subnet.private[2].id], count.index)
  security_groups = [aws_security_group.app_sg.id]
}

# AMI from App Server
resource "aws_ami_from_instance" "utcappserver" {
  name               = "utcappserver"
  source_instance_id = aws_instance.app_servers[0].id

  tags = {
    env  = "dev"
    team = "config management"
  }
}

# Launch Template
# In your main.tf, replace the launch template resource with this:

resource "aws_launch_template" "utc_lt" {
  name          = "utc-launch-template"
  image_id      = aws_ami_from_instance.utcappserver.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.utc_key.key_name

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  # Use base64encoded user_data directly instead of file reference
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd awscli amazon-efs-utils
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from UTC App Server - $(hostname)" > /var/www/html/index.html
              
              # Create log upload script
              cat << 'SCRIPT' > /opt/upload_logs.sh
              #!/bin/bash
              DATE=\$(date +%Y-%m-%d)
              INSTANCE_ID=\$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
              BUCKET_NAME="${aws_s3_bucket.utc_logs.bucket}"
              
              if [ -f /var/log/httpd/access_log ]; then
                  aws s3 cp /var/log/httpd/access_log s3://\$BUCKET_NAME/logs/\$INSTANCE_ID/access_log_\$DATE
              fi
              
              if [ -f /var/log/httpd/error_log ]; then
                  aws s3 cp /var/log/httpd/error_log s3://\$BUCKET_NAME/logs/\$INSTANCE_ID/error_log_\$DATE
              fi
              SCRIPT
              
              chmod +x /opt/upload_logs.sh
              echo "0 0 * * * /opt/upload_logs.sh" | crontab -
              
              # EFS mount (will be configured separately)
              mkdir -p /mnt/efs
              EOF
             )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "utc-app-server"
      env  = var.environment
      team = var.team_name
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "utc_asg" {
  name               = "utc-asg"
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2
  vpc_zone_identifier = [aws_subnet.private[0].id, aws_subnet.private[2].id]
  target_group_arns  = [aws_lb_target_group.utc_tg.arn]

  launch_template {
    id      = aws_launch_template.utc_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "env"
    value               = "dev"
    propagate_at_launch = true
  }

  tag {
    key                 = "team"
    value               = "config management"
    propagate_at_launch = true
  }
}

# Auto Scaling Policy
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "utc-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.utc_asg.name
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "utc-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.utc_asg.name
}

# CloudWatch Alarm for Scaling
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "utc-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Scale out when CPU > 80%"
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.utc_asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "utc-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "Scale in when CPU < 30%"
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.utc_asg.name
  }
}

# SNS Topic
resource "aws_sns_topic" "utc_scaling" {
  name = "utc-auto-scaling"
  tags = {
    env  = "dev"
    team = "config management"
  }
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.utc_scaling.arn
  protocol  = "email"
  endpoint  = "team@example.com" # Replace with actual email
}

# Auto Scaling Notifications
resource "aws_autoscaling_notification" "asg_notifications" {
  group_names = [aws_autoscaling_group.utc_asg.name]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.utc_scaling.arn
}

# S3 Bucket for Logs
resource "aws_s3_bucket" "utc_logs" {
  bucket = "utc-app-logs-${random_id.bucket_suffix.hex}"

  tags = {
    env  = "dev"
    team = "config management"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

