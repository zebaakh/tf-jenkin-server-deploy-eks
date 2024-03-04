# use data source to get a registered amazon linux 2 ami
data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# launch the ec2 instance
resource "aws_instance" "myapp-server" {
  ami                         = data.aws_ami.latest-amazon-linux-image.id
  instance_type               = var.instance_type
  key_name                    = "eks-tf-poc-key"
  subnet_id                   = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids      = [aws_default_security_group.default-sg.id]
  availability_zone           = var.avail_zone
  associate_public_ip_address = true
  user_data                   = file("jenkins-server-script.sh")
  tags = {
    Name = "${var.env_prefix}-server"
  }
}

# an empty resource block
resource "null_resource" "name" {

  # ssh into the ec2 instance 
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/Downloads/eks-tf-poc-key.pem")
    host        = aws_instance.myapp-server.public_ip
  }

  # copy the jenkins-server-script.sh file from your computer to the ec2 instance 
  provisioner "file" {
    source      = "jenkins-server-script.sh"
    destination = "/tmp/jenkins-server-script.sh"
  }

  # set permissions and run the jenkins-server-script.sh file
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/jenkins-server-script.sh",
      "sudo sh /tmp/jenkins-server-script.sh",
    ]
  }

  # wait for ec2 to be created
  depends_on = [aws_instance.myapp-server]
}

# print the url of the jenkins server
output "website_url" {
  value = join("", ["http://", aws_instance.myapp-server.public_dns, ":", "8080"])
}