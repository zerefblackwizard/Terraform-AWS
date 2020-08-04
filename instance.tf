resource "aws_instance" "Application_deployed" {
	ami = "ami-0447a12f28fddb066"
	instance_type = "t2.micro"
	subnet_id = "${aws_subnet.application_private_subnet1.id}"
	security_groups = ["${aws_security_group.allow_traffic.id}"]
	key_name = "${aws_key_pair.bastion_key.id}"
}

resource "aws_instance" "Bastion_host" {
	ami = "ami-0447a12f28fddb066"
	instance_type = "t2.micro"
	subnet_id = "${aws_subnet.application_public_subnet1.id}"
	security_groups = ["${aws_security_group.allow_traffic.id}"]
	associate_public_ip_address = true
	key_name = "${aws_key_pair.bastion_key.id}"
	
	provisioner "remote-exec" {
		connection {
			type = "ssh"
			host = self.public_ip
			private_key = "${file("bastion_key.pem")}"
			user = "ec2-user"
		}
		inline = [
			"sudo yum -y update",
			"sudo yum -y install httpd",
			"sudo systemctl status httpd",
			"sudo systemctl start httpd",
			"sudo systemctl status httpd",
			"mkdir /home/ec2-user/key"
		]
		
	}
	provisioner "file" {
		source = "C:\\Terraform\\images"
		destination = "/home/ec2-user/images"
		
		connection {
			type = "ssh"
			host = self.public_ip
			private_key = "${file("bastion_key.pem")}"
			user = "ec2-user"
		}
		
	}
	provisioner "file" {
		source = "C:\\Terraform\\bastion_key.pem"
		destination = "/home/ec2-user/key/bastion_key.pem"
		
		connection {
			type = "ssh"
			host = self.public_ip
			private_key = "${file("bastion_key.pem")}"
			user = "ec2-user"
		}
		
	}
	provisioner "file" {
		source = "C:\\Terraform\\index.html"
		destination = "/home/ec2-user/index.html"
		
		connection {
			type = "ssh"
			host = self.public_ip
			private_key = "${file("bastion_key.pem")}"
			user = "ec2-user"
		}
	}
	provisioner "file" {
		source = "C:\\Terraform\\execute.sh"
		destination = "/home/ec2-user/execute.sh"
		
		connection {
			type = "ssh"
			host = self.public_ip
			private_key = "${file("bastion_key.pem")}"
			user = "ec2-user"
		}
	}
	provisioner "remote-exec" {
		connection {
			type = "ssh"
			host = self.public_ip
			private_key = "${file("bastion_key.pem")}"
			user = "ec2-user"
		}
		inline = [
			"mv index.html nseit.html",
			"sudo mv nseit.html /var/www/html/",
			"sudo mv images /var/www/html/",
			"sudo yum install -y postgresql-server postgresql-contrib",
			"sudo postgresql-setup initdb",
			"sudo systemctl start postgresql",
			"sudo systemctl status postgresql",
			"sudo bash -x execute.sh"
		]
	}
	provisioner "remote-exec" {
		connection {
			type = "ssh"
			host = self.public_ip
			private_key = "${file("bastion_key.pem")}"
			user = "ec2-user"
		}
	
		// FOR PRIVATE
		inline = [
			"cd key",
			"chmod 400 bastion_key.pem",
			"cd ..",
			"sudo ssh -i /home/ec2-user/key/bastion_key.pem -o StrictHostKeyChecking=no ec2-user@${aws_instance.Application_deployed.private_ip} -t exit",
		    "scp -i /home/ec2-user/key/bastion_key.pem -o StrictHostKeyChecking=no execute.sh ec2-user@${aws_instance.Application_deployed.private_ip}:/home/ec2-user",
			"sudo ssh -i /home/ec2-user/key/bastion_key.pem -o StrictHostKeyChecking=no ec2-user@${aws_instance.Application_deployed.private_ip} -t sudo yum install -y postgresql-server postgresql-contrib",
			"sudo ssh -i /home/ec2-user/key/bastion_key.pem -o StrictHostKeyChecking=no ec2-user@${aws_instance.Application_deployed.private_ip} -t sudo postgresql-setup initdb",
			"sudo ssh -i /home/ec2-user/key/bastion_key.pem -o StrictHostKeyChecking=no ec2-user@${aws_instance.Application_deployed.private_ip} -t sudo systemctl start postgresql",
			"sudo ssh -i /home/ec2-user/key/bastion_key.pem -o StrictHostKeyChecking=no ec2-user@${aws_instance.Application_deployed.private_ip} -t bash -x execute.sh && exit"
		]
	}

}

resource "aws_key_pair" "bastion_key" {
	key_name = "bastion_key"
	public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCqVMrsux4IHs8RemYT612Zj1HLgwvVHsNTv0LaqSxBlhPyHQpsCNo0YXCN9FJP57WXAo0eFXSXGpy5t7QrpEo42oetWYIrWsEPkrFboz2rsbQF66FIM0J53Mmk1W2LGY4aZByilOLvHPNgvSXZ/zsPF1AcnAP6dPfpgVAVU4YEwJ6wDAjls3mHev3TJllxGdbFXOxUKFPiMXDU6cXr4Qtl4jKhSOpkJldjzSMFFG4Q5tUj1VO1urbunarMUtU2NQhHTDv9DO/PpSN+MPHzS2h3/dxY9fzpd3SOMPeMP1rK++/pgdVXxSujbqG4gDDq3T1gJFigYbAJAH5LnUEh6lhlQhNwlV7k9HP4WZPVrH+nNHrr+ngwgo08Ilm/7eNayMWAiKXAGdlqmNGmID1nFMsnwKco4+bhzTbsy8RyOHnzzM6SKecuFsT1jeKxrr2U25PTy12HEVEVI9zwv99sX34VbNpTui+u1Fo8dFyZohOvUes9pAQV6JMaCX784or/QDcm7wOEcp2EOxvBHVNC11D80YolnjS4NwuSP/UPR/47LK6lTxGIMIDQElykZPlkyKKJ0aAHX/bb5HL+NBrIHKlP/0J8jKfMpr+ppHjdkmCTA2NcL0kzGJjc8UMdtI7TrwmgSmSek8YWo7cziDnEdUDnGtGXva9caOZeVtswPkDa4w== vidhim@nseit.com"
}

