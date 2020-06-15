provider "aws"{
region = "ap-south-1"
profile = "jai"
}
resource "aws_instance" "web"{
  ami="ami-0447a12f28fddb066"
  instance_type="t2.micro"
  key_name = "mykeypair1"
  security_groups=["launch-wizard-2"]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("/home/jai/Downloads/mykeypair1.pem")
    host     = aws_instance.web.public_ip
  }


  provisioner "remote-exec"{
  inline=[
    "sudo yum install httpd php git -y",
    "sudo systemctl restart httpd",
    "sudo systemctl enable httpd"
  ]
}


  tags={
    Name="myos1"
  }
}

output "myos_ip"{
  value=aws_instance.web.public_ip
}



resource "aws_ebs_volume" "ebs1" {
  availability_zone = aws_instance.web.availability_zone
  size              = 1

  tags = {
    Name = "jaiebs"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs1.id
  instance_id = aws_instance.web.id
  force_detach=true
}

resource "null_resource" "null_local2"{
  depends_on=[
    aws_volume_attachment.ebs_att,
  ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("/home/jai/Downloads/mykeypair1.pem")
    host     = aws_instance.web.public_ip
  }

  provisioner "remote-exec" {
  inline=[
    "sudo mkfs.ext4 /dev/xvdh",
    "sudo mount /dev/xvdh /var/www/html",
    "sudo rm -rf /var/www/html",
    "sudo git clone https://github.com/jayachandra-9/multi_cloud.git  /var/www/html"
  ]
  }
}

resource "null_resource" "null_local1"{
  depends_on=[
    null_resource.null_local2,
  ]
  provisioner "local-exec" {

    command="google-chrome ${aws_instance.web.public_ip}"
  }
}
