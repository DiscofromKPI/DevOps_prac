<h2 align="center">DevOps test task</h2>


[![Build status](https://ci.appveyor.com/api/projects/status/n4uj9qfuywrkdrhb/branch/main?svg=true)](https://ci.appveyor.com/project/DiscofromKPI/DevOps_prac/branch/main)

### Configuration

Before start you need to install the [Terraform](https://www.terraform.io/downloads) <br/>
Also you need to have the [AWS Account](https://aws.amazon.com/) <br/>

### Getting Started

Setup the credentials, you can find them at the [IAM AWS](https://console.aws.amazon.com/iam) <br/>
Then save them and export:

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
Then setup the ```aws_intance```, use the Key Pair, which you can setup in the [AWS EC2 KeyPairs](https://us-east-2.console.aws.amazon.com/ec2/v2) <br/>
Download the **.pem** file and import this key to your instance, keep the key hidden!

Run the linux commands to setup docker and watchtower

**Watchtower helps us to update the running version of your containerized app simply by pushing a new image to the Docker Hub or your own image registry.**
```tf
provisioner "remote-exec" {
    inline = [
    "sudo apt-get update && install curl",
    "curl -sSL https://get.docker.com/ | sh",
    "sudo docker run -d --name [Your_resource_name] --log-driver=awslogs --log-opt awslogs-group=[Your_log_group_name] -p 80:80 straxseller/devops_prac",
    "sudo docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --cleanup -i 10",
    ]
  }
```
Setup the ```aws_security_group``` for the instance:
```tf
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
You can also setup the **https** if you have the certificate.

Also setup the **Elastic IP**. It commonly used to help with fault-tolerant instances or software. For example, if you have an EC2 instance that has an Elastic IP address and that instance is stopped or terminated, you can remap the address and re-associate it with another instance in your account.

```tf
resource "aws_eip" "lb" {
  instance = aws_instance.docker_site.id
  vpc      = true
}
```
### Actions
Setup the github actions to run pipelines and check image build(steps showing):
```yml
 steps:
      - name: Check out the repo
        uses: actions/checkout@v2
      
      - name: Lint Dockerfile
        uses: luke142367/Docker-Lint-Action@v1.0.0
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Log in to Docker Hub
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_PASSWORD }}
      
      - name: Build and push Docker image
        uses: docker/build-push-action@v2
        with:
          context: .
          push: true
          tags: straxseller/devops_prac:latest
```
### Monitoring and Logging
Create the ```log_group``` and ```metric_alarm``` for monitoring and logging:

**Metric_alarm**
```tf
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
```


**Log_Group**
```tf
resource "aws_cloudwatch_log_group" "logs" {
  name = "logs"

  tags = {
    Environment = "production"
    Application = "serviceA"
  }
}
```
### DNS
Setup the DNS for your server using [Route53](https://console.aws.amazon.com/route53/v2)<br/>

<h3 align="center" link="samoyed.space">samoyed.space</h3>
### Check it out [samoyed.space](https://samoyed.space) <br/>
