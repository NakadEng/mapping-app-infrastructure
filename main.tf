variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {
    default = "ap-northeast-2"
}
 
variable "images" {
    type = "map"
    default = {
        ap-northeast-1 = ""
        ap-northeast-2 = "ami-00dc207f8ba6dc919"
    }
}
 
provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.region}"
}
 
resource "aws_vpc" "test-mappingApp" {
    cidr_block = "10.1.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "false"
    tags {
      Name = "test-mappingApp"
    }
}
 
resource "aws_internet_gateway" "myGW" {
    vpc_id = "${aws_vpc.test-mappingApp.id}"
}
 
resource "aws_subnet" "public-a" {
    vpc_id = "${aws_vpc.test-mappingApp.id}"
    cidr_block = "10.1.1.0/24"
    availability_zone = "ap-northeast-2a"
}
 
resource "aws_route_table" "public-route" {
    vpc_id = "${aws_vpc.test-mappingApp.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.myGW.id}"
    }
}
 
resource "aws_route_table_association" "puclic-a" {
    subnet_id = "${aws_subnet.public-a.id}"
    route_table_id = "${aws_route_table.public-route.id}"
}
 
resource "aws_security_group" "admin" {
    name = "admin"
    description = "Allow SSH inbound traffic"
    vpc_id = "${aws_vpc.test-mappingApp.id}"
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "http-https-express" {
    name = "http-https-express"
    description = "Allow HTTP-HTTPS-Express inbound traffic"
    vpc_id = "${aws_vpc.test-mappingApp.id}"
    ingress {
        from_port = 3000
        to_port = 3000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
 
resource "aws_instance" "mappingApp-ba" {
    ami = "${lookup(var.images, "ap-northeast-2")}"
    instance_type = "t2.micro"
    key_name = "key_nakata_kr"
    vpc_security_group_ids = [
      "${aws_security_group.admin.id}",
      "${aws_security_group.http-https-express.id}"
    ]
    subnet_id = "${aws_subnet.public-a.id}"
    associate_public_ip_address = "true"
    root_block_device = {
      volume_type = "gp2"
      volume_size = "20"
    }
    ebs_block_device = {
      device_name = "/dev/sdf"
      volume_type = "gp2"
      volume_size = "100"
    }
    tags {
        Name = "mappingApp-ba"
    }
}

resource "aws_dynamodb_table" "user_mapping_table" {
  name = "UserMapping"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "MacAddressHash"
  attribute {
    name = "MacAddressHash"
    type = "S"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_endpoint_type = "Gateway"
  vpc_id = "${aws_vpc.test-mappingApp.id}"
  service_name = "com.amazonaws.ap-northeast-2.dynamodb"
}

output "public ip of mappingApp-ba" {
  value = "${aws_instance.mappingApp-ba.public_ip}"
}