provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}
/* #instance creation no need in case of ASG
resource "aws_instance" "ex1" {
  #ami           = "${lookup(var.amis, var.region)}"
  ami = "${data.aws_ami.latest_ecs.id}"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  security_groups = ["${aws_security_group.web-node.name}"]
   tags = {
          Name = "PlayQ-2019"
          Type = "webserver"
          }
  user_data = "${file("./userdata.sh")}"
# provisioner "local-exec" {
#   command = "echo ${aws_instance.ex1.public_ip} > ip_address.txt"
#                          }
}
*/
#declare zone usage
data "aws_availability_zones" "all" {}
#data "aws_availability_zones" "available" {}
#attempt to list all subnets
#data "aws_subnet_ids" "all" {}

# find lates ecs image
data "aws_ami" "latest_ecs" {
most_recent = true
owners = ["591542846629"] # AWS number
  filter {
      name   = "name"
      values = ["*amazon-ecs-optimized"]
  }
  filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }
}

#find ,y public IP
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

output "my_public_ip" {
  value = "${chomp(data.http.myip.body)}/32"
}

/*
output "ecs_public_ip" {
  value = "${aws_instance.ex1.public_ip}"
}
output "ami_name"{
  value = "${data.aws_ami.latest_ecs.id}"
}*/

#create security group allowing SSH  and 2x IPs my and PlayQ
resource "aws_security_group" "web-node" {
  name = "web-node"
  description = "Web Security Group"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["76.169.181.157/32"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating Launch Configuration for ASG
resource "aws_launch_configuration" "ex1" {
  name = "Launch_Config_ASG_PlayQ-2019_webservers"
  image_id               = "${data.aws_ami.latest_ecs.id}"
  instance_type          = "t2.micro"
  security_groups = ["${aws_security_group.web-node.name}"]
  key_name               = "${var.key_name}"
  user_data = "${file("./userdata.sh")}"
  lifecycle {
    create_before_destroy = true
  }
}

## Creating AutoScaling Group
resource "aws_autoscaling_group" "ex1" {
  name = "ASG_PlayQ-2019_webservers"
  launch_configuration = "${aws_launch_configuration.ex1.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  min_size = 2
  max_size = 5
  #load_balancers = ["${aws_elb.example.name}"]
  #health_check_type = "ELB"
  tags = [
    {
    key = "Name"
    value = "PlayQ-2019"
    propagate_at_launch = true
     },
    {
    key                 = "Type"
    value               = "webserver"
    propagate_at_launch = true
     },
  ]

}

##ALB section, move to file loadbalancer.tf
## Security Group for ALB
/*resource "aws_security_group" "alb" {
  name = "terraform-ex1-alb"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}*/
### Creating ALB
/*Presource "aws_alb" "alb" {
  name            = "terraform-example-alb"
  security_groups = ["${aws_security_group.alb.id}"]
  subnets		=	["${aws_subnet.public-1a.id}", "${aws_subnet.public-1b.id}"]
  tags {
    Name = "terraform-example-alb"
  }
}*/
#temp point checker
