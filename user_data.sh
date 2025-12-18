# user_data.sh
#!/bin/bash
# UTC App Server User Data Script

# Update system
yum update -y

# Install required packages
yum install -y httpd awscli amazon-efs-utils

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create index page
echo "<html><body><h1>UTC Application Server</h1><p>Server: $(hostname)</p><p>IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)</p><p>Time: $(date)</p></body></html>" > /var/www/html/index.html

# Create log upload script
cat << 'EOF' > /opt/upload_logs.sh
#!/bin/bash
DATE=$(date +%Y-%m-%d)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
BUCKET_NAME="utc-app-logs-bucket"  # Update with your actual bucket name

# Upload access logs if they exist
if [ -f /var/log/httpd/access_log ]; then
    aws s3 cp /var/log/httpd/access_log s3://$BUCKET_NAME/logs/$INSTANCE_ID/access_log_$DATE
fi

# Upload error logs if they exist
if [ -f /var/log/httpd/error_log ]; then
    aws s3 cp /var/log/httpd/error_log s3://$BUCKET_NAME/logs/$INSTANCE_ID/error_log_$DATE
fi
EOF

# Make script executable
chmod +x /opt/upload_logs.sh

# Add to crontab - run daily at midnight
echo "0 0 * * * /opt/upload_logs.sh" | crontab -

# Create EFS mount directory
mkdir -p /mnt/efs

# Note: EFS mount command will be added during instance launch
# The actual mount command depends on your EFS DNS name