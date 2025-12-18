# # Create a new file: keypair.tf

resource "tls_private_key" "utc_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "utc_key" {
  key_name   = "utc-key"
  public_key = tls_private_key.utc_key.public_key_openssh
  
  tags = {
    Name = "utc-key"
    env  = "dev"
    team = "config management"
  }
}

resource "local_file" "private_key" {
  content  = tls_private_key.utc_key.private_key_pem
  filename = "${path.module}/utc-key.pem"
  
  provisioner "local-exec" {
    command = "chmod 400 ${path.module}/utc-key.pem"
  }
}