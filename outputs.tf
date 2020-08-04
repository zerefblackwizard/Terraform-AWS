output "vpc_id" {
	value = "${aws_vpc.application.id}"
}

output "public_subnet1_id" {
	value = "${aws_subnet.application_public_subnet1.id}"
}

output "public_subnet2_id" {
	value = "${aws_subnet.application_public_subnet2.id}"
}

output "private_subnet_1_id" {
	value = "${aws_subnet.application_private_subnet1.id}"
}

output "bastion_public_ip" {
        value = "${aws_instance.Bastion_host.public_ip}"
}

output "private_instance_ip" {
	value = "${aws_instance.Application_deployed.private_ip}"
}

