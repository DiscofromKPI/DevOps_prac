<h2 align="center">DevOps test task</h2>

[![Build status](https://ci.appveyor.com/api/projects/status/n4uj9qfuywrkdrhb/branch/main?svg=true)](https://ci.appveyor.com/project/DiscofromKPI/DevOps_prac/branch/main)

### Configuration

Before start you need to install the [Terraform](https://www.terraform.io/downloads) <br/>
Also you need to have the [AWS Account](https://aws.amazon.com/) <br/>

### Getting Started

Setup the credentials, you can find them at the [IAM AWS](https://console.aws.amazon.com/iam) <br/>
Then save them and export like 

```bash
export AWS_ACCESS_KEY_ID="Here your key"
export AWS_SECRET_ACCESS_KEY="Here your secret key"
```

Then setup the ubuntu instance:
```tf
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
```
Then setup the ```aws_intance```, use the KeyPair, which you can setup in the [AWS EC2 KeyPairs](https://us-east-2.console.aws.amazon.com/ec2/v2) <br/>
Download the **.pem** file and import this key to your instance, keep the key hidden!

Run the linux commands to setup docker and watchtower

**Watchtower helps us to update the running version of your containerized app simply by pushing a new image to the Docker Hub or your own image registry.**
```bash
provisioner "remote-exec" {
    inline = [
    "sudo apt-get update && install curl",
    "curl -sSL https://get.docker.com/ | sh",
    "sudo docker run -d --name [Your_resource_name] --log-driver=awslogs --log-opt awslogs-group=[Your_log_group_name] -p 80:80 straxseller/devops_prac",
    "sudo docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --cleanup -i 10",
    ]
  }
```
Setup the ```aws_security_group``` for the instance
```bash
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
```
You can also setup the **https** if you have the certificate
