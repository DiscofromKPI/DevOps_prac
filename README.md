<h2 align="center">DevOps test task</h2>

[![Build status](https://ci.appveyor.com/api/projects/status/n4uj9qfuywrkdrhb/branch/main?svg=true)](https://ci.appveyor.com/project/DiscofromKPI/DevOps_prac/branch/main)

### Configuration

Before start you need to install the [Terraform](https://www.terraform.io/downloads) <br/>
Also you need to have the [AWS Account](https://aws.amazon.com/) <br/>

###Getting Started

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
