provider "aws" {
  region = "eu-north-1"

}
resource "aws_vpc" "techcorp-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "techcorp-vpc" }

}
resource "aws_internet_gateway" "techcorp_igw" {
  vpc_id = aws_vpc.techcorp-vpc.id
  tags   = { Name = "techcorp_igw" }

}
data "aws_availability_zones" "available" { state = "available" }

resource "aws_subnet" "public_sub1" {
  vpc_id                  = aws_vpc.techcorp-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "techcorp-public-subnet_1" }
}
resource "aws_subnet" "public_sub2" {
  vpc_id                  = aws_vpc.techcorp-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags                    = { Name = "techcorp-public-subnet_2" }
}
resource "aws_subnet" "private_sub1" {
  vpc_id                  = aws_vpc.techcorp-vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
  tags                    = { Name = "techcorp-private-subnet_1" }
}
resource "aws_subnet" "private_sub2" {
  vpc_id                  = aws_vpc.techcorp-vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
  tags                    = { Name = "techcorp-private-subnet_2" }
}
resource "aws_eip" "nat_1" { domain = "vpc" }
resource "aws_eip" "nat_2" { domain = "vpc" }

resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.public_sub1.id
  tags          = { Name = "techcorp-nat-1" }
}
resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_2.id
  subnet_id     = aws_subnet.public_sub2.id
  tags          = { Name = "techcorp-nat-2" }
}

# public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.techcorp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.techcorp_igw.id
  }
  tags = { Name = "techcorp-public-rt" }
}
resource "aws_route_table_association" "public_sub1" {
  subnet_id      = aws_subnet.public_sub1.id
  route_table_id = aws_route_table.public.id

}
resource "aws_route_table_association" "public_sub2" {
  subnet_id      = aws_subnet.public_sub2.id
  route_table_id = aws_route_table.public.id

}

resource "aws_route_table" "private_sub1" {
  vpc_id = aws_vpc.techcorp-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }
  tags = { Name = "techcorp-private-rt" }
}
resource "aws_route_table_association" "private_sub1" {
  subnet_id      = aws_subnet.private_sub1.id
  route_table_id = aws_route_table.private_sub1.id

}
resource "aws_route_table" "private_sub2" {
  vpc_id = aws_vpc.techcorp-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }
  tags = { Name = "techcorp-private-rt" }
}
resource "aws_route_table_association" "private_sub2" {
  subnet_id      = aws_subnet.private_sub2.id
  route_table_id = aws_route_table.private_sub2.id

}



resource "aws_security_group" "bastion-sg" {
  name        = "techcorp-bastion-sg"
  description = "Allow ssh from only my ip"
  vpc_id      = aws_vpc.techcorp-vpc.id
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_Ip]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web-sg" {
  name        = "techcorp-web-sg"
  description = "Allow HTTPS/HTTP from anywhere and SSH from bastion"
  vpc_id      = aws_vpc.techcorp-vpc.id
  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description     = "Allow SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion-sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}

# Database sg
resource "aws_security_group" "DB-sg" {
  name        = "techcorp-DB-sg"
  description = "Allow postgres from web sg and SSH from bastion"
  vpc_id      = aws_vpc.techcorp-vpc.id
  ingress {
    description     = "Allow postgres from web sg"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web-sg.id]
  }
  ingress {
    description     = "Allow SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion-sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = var.instance_type_bastion
  subnet_id                   = aws_subnet.public_sub1.id
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.bastion-sg.id]
  associate_public_ip_address = true
  tags                        = { Name = "techcorp-bastion" }

}

resource "aws_instance" "web-server1" {
  ami                    = data.aws_ami.amazon-linux-2.id
  instance_type          = var.instance_type_web
  subnet_id              = aws_subnet.private_sub1.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  user_data              = file("user-data/web-server_setup.sh")
  tags                   = { Name = "techcorp-web1" }

}
resource "aws_instance" "web-server2" {
  ami                    = data.aws_ami.amazon-linux-2.id
  instance_type          = var.instance_type_web
  subnet_id              = aws_subnet.private_sub2.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  user_data              = file("user-data/web-server_setup.sh")
  tags                   = { Name = "techcorp-web2" }
}
resource "aws_instance" "database" {
  ami                    = data.aws_ami.amazon-linux-2.id
  instance_type          = var.instance_type_db
  subnet_id              = aws_subnet.private_sub1.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.DB-sg.id]
  user_data              = file("user-data/web-server_setup.sh")
  tags                   = { Name = "techcorp-database" }

}


#load balancer
resource "aws_lb" "techcorp_lb" {
  name               = "techcorp-web-lb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.web-sg.id]
  subnets            = [aws_subnet.public_sub1.id, aws_subnet.public_sub2.id]


}
resource "aws_lb_target_group" "web-tg" {
  name     = "techcorp-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.techcorp-vpc.id
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"

  }

}
resource "aws_lb_target_group_attachment" "web1-attach" {
  target_group_arn = aws_lb_target_group.web-tg.arn
  target_id        = aws_instance.web-server1.id
  port             = 80


}
resource "aws_lb_target_group_attachment" "web2-attach" {
  target_group_arn = aws_lb_target_group.web-tg.arn
  target_id        = aws_instance.web-server2.id
  port             = 80

}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.techcorp_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-tg.arn
  }

}

