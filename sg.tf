# Security Groups
resource "aws_security_group" "alb_sg" {
  name        = "utc-alb-sg"
  description = "ALB Security Group"
  vpc_id      = aws_vpc.utc_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "utc-alb-sg"
    env  = "dev"
    team = "config management"
  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "utc-bastion-sg"
  description = "Bastion Security Group"
  vpc_id      = aws_vpc.utc_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "utc-bastion-sg"
    env  = "dev"
    team = "config management"
  }
}

resource "aws_security_group" "app_sg" {
  name        = "utc-app-sg"
  description = "App Server Security Group"
  vpc_id      = aws_vpc.utc_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "utc-app-sg"
    env  = "dev"
    team = "config management"
  }
}

resource "aws_security_group" "database_sg" {
  name        = "utc-database-sg"
  description = "Database Security Group"
  vpc_id      = aws_vpc.utc_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "utc-database-sg"
    env  = "dev"
    team = "config management"
  }
}


