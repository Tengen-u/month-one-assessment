#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
EC2_INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
echo "<html><body><h1>Hello from web server: $EC2_INSTANCE_ID</h1></body></html>" > /var/www/html/index.html