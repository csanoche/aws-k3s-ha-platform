data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}


# Create EC2 instance for bastion host (1)
resource "aws_instance" "bastion_host" {
  ami           = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = "t3.nano"

  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [ aws_security_group.bastion_sg.id ]
  key_name = aws_key_pair.bastion_ssh_key.key_name

  tags = merge(
    var.common_tags,
    {
      Role = "bastion"
    }
  )
}