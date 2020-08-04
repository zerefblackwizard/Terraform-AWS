provider "aws" {
    region = "ap-south-1"
    access_key = "AKIAI4464W5ST6GJYX3Q"
    secret_key = "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"
}

resource "aws_vpc" "application" {
    cidr_block = "10.0.0.0/16"
    tags = {
        application = "the Virtual private cloud in which the application network architecture is to be deployed"
    }
}

resource "aws_subnet" "application_private_subnet1" {
    vpc_id = "${aws_vpc.application.id}"
    availability_zone = "ap-south-1a"
    cidr_block = "10.0.0.1/24"
    tags = {
	Name = "Application_private1"
        application = "Private subnet of the actual application instance which is to be deployed"
    }
}

resource "aws_subnet" "application_public_subnet1" {
    vpc_id = "${aws_vpc.application.id}"
    availability_zone = "ap-south-1a"
    cidr_block = "10.0.1.0/24"
    tags = {
	Name = "Application_public1"
        application = "The first public subnet in which the load balancer will be deployed."
    }
}

resource "aws_subnet" "application_public_subnet2" {
    vpc_id = "${aws_vpc.application.id}"
    availability_zone = "ap-south-1b"
    cidr_block = "10.0.2.0/24"
    tags = {
        Name = "Application_public2"
        application = "Second subnet (public) in which the application load balancer may be deployed if 1a south region is not available"
    }
}

resource "aws_eip" "for_NAT" {
 //   subnet_id = "${aws_subnet.application_public_subnet1.id}"  
}

resource "aws_internet_gateway" "application_internet_gateway" {
    vpc_id = "${aws_vpc.application.id}"
   tags = {
        Name = "Main"
    }     
}

resource "aws_nat_gateway" "nat_gateway" {
    subnet_id = "${aws_subnet.application_public_subnet1.id}"
    allocation_id = "${aws_eip.for_NAT.id}"
    depends_on = ["aws_internet_gateway.application_internet_gateway"]
}

resource "aws_route_table" "igw1" {
	vpc_id = "${aws_vpc.application.id}"
	route {
	   cidr_block = "0.0.0.0/0"
           gateway_id = "${aws_internet_gateway.application_internet_gateway.id}"
	}
}

resource "aws_route_table_association" "one_with_igw1" {
   subnet_id = "${aws_subnet.application_public_subnet1.id}"
   route_table_id = "${aws_route_table.igw1.id}"
}

resource "aws_route_table" "igw2" {
    vpc_id = "${aws_vpc.application.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.application_internet_gateway.id}"
    }
}

resource "aws_route_table_association" "one_with_igw2" {
	subnet_id = "${aws_subnet.application_public_subnet2.id}"
	route_table_id = "${aws_route_table.igw2.id}"	
}

resource "aws_route_table" "ngw1" {
    vpc_id = "${aws_vpc.application.id}"
    route {
	cidr_block = "0.0.0.0/0"
	gateway_id = "${aws_nat_gateway.nat_gateway.id}"
    }
}

resource "aws_route_table_association" "one_with_nat" {
	subnet_id = "${aws_subnet.application_private_subnet1.id}"
	route_table_id = "${aws_route_table.ngw1.id}"
}

resource "aws_security_group" "allow_traffic" {
	name = "Allow_Application_traffic"
	description = "Allowing traffic of the application"
	vpc_id = "${aws_vpc.application.id}"

	ingress {
		from_port = 22
		to_port = 22
		protocol = "TCP"
		cidr_blocks = ["0.0.0.0/0"]	
	}

	ingress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]		
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_lb" "application_lb" {
	name = "For-Application"
	internal = false
	load_balancer_type = "application"
	subnets = ["${aws_subnet.application_public_subnet1.id}","${aws_subnet.application_public_subnet2.id}"]
	security_groups = ["${aws_security_group.allow_traffic.id}"]
	enable_deletion_protection = false
	tags = {
		Load_Balancer = "For the Application to connect to the internet traffic on the specific port"
	}
}

resource "aws_lb_target_group" "postgre_db" {
	name = "db"
	port = 5432
	protocol = "HTTP"
	target_type = "instance"
	vpc_id = "${aws_vpc.application.id}"	
}

resource "aws_lb_listener" "postgre_db" {
	load_balancer_arn = "${aws_lb.application_lb.arn}"
	port = 5432
	protocol = "HTTP"

	default_action {
		type = "forward"
		target_group_arn = "${aws_lb_target_group.postgre_db.arn}"
	}
}


