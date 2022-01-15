provider "aws" {
  region = "us-east-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] 
}

resource "aws_eip" "lb" {
  instance = aws_instance.docker_site.id
  vpc      = true
}

resource "aws_instance" "docker_site" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.allow_web.id]
  key_name                    = "connect_key"
  iam_instance_profile = aws_iam_instance_profile.log_profile.name

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("connect_key.pem")
}

    provisioner "remote-exec" {
    inline = [
    "sudo apt-get update && install curl",
    "curl -sSL https://get.docker.com/ | sh",
    "sudo docker run -d --name docker_site --log-driver=awslogs --log-opt awslogs-group=logs -p 80:80 straxseller/devops_prac",
    "sudo docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --cleanup -i 10",
    ]
  }

  tags = {
    Name = "docker_site"
  }
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "Elastic_IP" {
  value = aws_instance.docker_site.public_ip
}

resource "aws_cloudwatch_metric_alarm" "foobar" {
  alarm_name                = "terraform-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "2"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  insufficient_data_actions = []
  dimensions = {
    InstanceId = aws_instance.docker_site.id
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  name = "logs"

  tags = {
    Environment = "production"
    Application = "serviceA"
  }
}

resource "aws_cloudwatch_log_metric_filter" "yada" {
  name           = "MyAppAccessCount"
  pattern        = "\"[error]\""
  log_group_name = aws_cloudwatch_log_group.logs.name

  metric_transformation {
    name      = "EventCount"
    namespace = "Namespace"
    value     = "1"
  }
  
}

resource "aws_iam_role" "role" {
  name = "log_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "log_attach" {
  name       = "log_attachment"
  roles      = [aws_iam_role.role.name]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_instance_profile" "log_profile" {
  name = "log_profile"
  role = aws_iam_role.role.name
}
