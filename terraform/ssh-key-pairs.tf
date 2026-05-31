# External to Bastion SSH Key Pair

# Generate ssh key pair
resource "tls_private_key" "bastion_ssh_key" {
  algorithm = "ED25519"
}

# Create AWS key pair using the generated public key
resource "aws_key_pair" "bastion_ssh_key" {
  key_name   = "bastion-ssh-key"
  public_key = tls_private_key.bastion_ssh_key.public_key_openssh
}

# Save the private key to a local file
resource "local_file" "aws_bastion_ssh_key" {
  content  = tls_private_key.bastion_ssh_key.private_key_openssh
  filename = "../ssh/bastion-ssh-key.pem"
  file_permission = "0600"
}

# Bastion to Node SSH Key Pair

# Generate ssh key pair
resource "tls_private_key" "node_ssh_key" {
  algorithm = "ED25519"
}

# Create AWS key pair using the generated public key
resource "aws_key_pair" "node_ssh_key" {
  key_name   = "node-ssh-key"
  public_key = tls_private_key.node_ssh_key.public_key_openssh
}

# Save the private key to a local file
resource "local_file" "aws_node_ssh_key" {
  content  = tls_private_key.node_ssh_key.private_key_openssh
  filename = "../ssh/node-ssh-key.pem"
  file_permission = "0600"
}