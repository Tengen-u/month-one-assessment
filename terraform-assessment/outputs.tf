output "vpc_id" {
  value = aws_vpc.techcorp-vpc.id
}
output "alb_dns_name" {
  value = aws_lb.techcorp_lb.dns_name
}
output "bastion-pub-ip" {
  value = aws_instance.bastion.public_ip
}