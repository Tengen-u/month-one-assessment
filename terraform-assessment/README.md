Project Overview
  This terraform project deploys a highly available web application infrastructure on AWS for Techcorp.
The infrastucture includes a vpc with a public and private subnet across multiple availability zones, EC2 instances, application load balancer, target groups and all other working components. 
# Required Software
- Terraform
- AWS CLI


# AWS Requirements
- AWS account with administrative privileges or sufficient permissions to create:
  - VPC and networking components
  - EC2 instances
  - Application Load Balancer
  - Security Groups
- AWS CLI configured using bash
  aws configure
   Enter your Access Key ID, Secret Access Key, and default region


SSH Requirements 

· An EC2 key pair (if you want SSH access)
  · Create via AWS Console: EC2 → Key Pairs → Create key pair
  · Name it techcorp-key or update the key_name variable




Deployment Instructions

1. Clone or Download the Project

  bash
git clone 
cd terraform-assessment


2. Configure Variables

Copy the example variables file and update with your values:

  bash
cp terraform.tfvars.example terraform.tfvars


Edit terraform.tfvars with your specific values:

hcl
# Required: Your current public IP address (find at https://ifconfig.me or curl using bash)
your_ip = "203.0.113.42/32"(example, not my actual ip)

# Optional: EC2 key pair name 
key_name = "techcorp-key" 

# Optional: Customize instance types (or copy from the .example)
instance_type_bastion = "t3.micro"
instance_type_web     = "t3.micro"
instance_type_db      = "t3.small"



3. Initialize Terraform

bash
terraform init




4. Validate Configuration (optional)

bash
terraform validate


5. Review the Plan

bash
terraform plan


Review the planned resources. 

6. Deploy Infrastructure

bash
terraform apply


Type yes when prompted. 

7. Access the Application

After successful deployment, get the ALB DNS name:

bash
terraform output alb_dns_name


Open a web browser and navigate to:


http://<alb-dns-name>
Refresh the page to see load balancing in action (the instance ID will alternate between web-1 and web-2).


Post-Deployment Verification

Check All Outputs

Expected outputs:

· vpc_id: The created VPC ID
· alb_dns_name: Load balancer endpoint
· bastion_public_ip: Public IP for SSH access

Verify Web Servers

bash
# Get ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)

# Test the endpoint
curl http://$ALB_DNS


Verify Database (Optional, requires SSH)

bash
# SSH to bastion
ssh -i techcorp-key.pem ec2-user@$(terraform output -raw bastion_public_ip)

# From bastion, SSH to database
ssh ec2-user@<database-private-ip>

# Check PostgreSQL status
sudo systemctl status postgresql

# Connect to database
sudo -u postgres psql

# Inside PostgreSQL, run:
\l                    # List databases (should show techcorpdb)
\q                    # Exit



Update Infrastructure

After making changes to Terraform files:

bash
terraform plan   (Review changes)
terraform apply 


Connect to Instances (if using key pair)

bash
# Bastion host
ssh -i techcorp-key.pem ec2-user@$(terraform output -raw bastion_public_ip)

# From bastion to web servers
ssh ec2-user@10.0.3.10    # Web-1 private IP
ssh ec2-user@10.0.4.10    # Web-2 private IP

# From bastion to database
ssh ec2-user@10.0.3.20    # Database private IP


Troubleshooting

Common Issues and Solutions

Issue Likely Cause Solution
Connection timed out when SSH to bastion Your IP changed Update your_ip in terraform.tfvars and run terraform apply
Invalid value for keyName Empty or missing key name Remove key_name from terraform.tfvars or set to null
ALB error about subnets in same AZ Subnets in same availability zone Check subnets use different AZs in main.tf
Web page not loading Security group or user data issue Check web server security group allows port 80
PostgreSQL not installed User data script failed SSH to database and run install commands manually

Debugging User Data Scripts

bash
# SSH to the instance and check logs
sudo cat /var/log/cloud-init-output.log
sudo cat /var/log/cloud-init.log


Resource Cleanup

Important: Always destroy resources when done to avoid ongoing charges!

bash
# Destroy all infrastructure
terraform destroy

# Type 'yes' when prompted






To reduce costs:

· Use only during business hours and destroy after testing
· Consider t2.micro instead of t3 (slightly cheaper)
· Use only 1 NAT Gateway instead of 2 (reduces HA)

Security Considerations

This infrastructure includes:

· SSH access restricted to your specific IP address
· Database accessible only from web servers (not public)
· Bastion host as single entry point for administrative access
· Private subnets for application and database tiers

Do NOT commit terraform.tfvars or *.tfstate files to version control!







install postgres manually to the database server. There seems to be a package avaliability issue
