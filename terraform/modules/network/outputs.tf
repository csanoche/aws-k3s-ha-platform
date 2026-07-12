output "main_vpc_id" {
    value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}

output "common_sg_id" {
  value = aws_security_group.common_sg.id
}

output "k3s_master_sg_id" {
  value = aws_security_group.k3s_master_sg.id
}

output "k3s_worker_sg_id" {
  value = aws_security_group.k3s_worker_sg.id
}

output "postgres_sg_id" {
  value = aws_security_group.postgres_sg.id
}

output "haproxy_keepalived_sg_id" {
  value = aws_security_group.haproxy_keepalived_sg.id
}

