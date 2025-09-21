# for output purpose
output "ec2_public_ip" {
  value = aws_instance.myapp-ec2.public_ip
}
