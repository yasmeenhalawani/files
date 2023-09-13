# Define the AWS provider
provider "aws" {
  region = "us-east-1"  # Change to your desired region
}

# Create a security group for the master node
resource "aws_security_group" "master_sg" {
  name        = "k8s-master-sg"
  description = "Security group for the Kubernetes master node"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH access from anywhere (adjust as needed)
  }
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH access from anywhere (adjust as needed)
  }
  # Add additional rules as required, e.g., for API server and etcd communication
}
# Create a security group for the worker node
resource "aws_security_group" "worker_sg" {
  name        = "k8s-worker-sg"
  description = "Security group for the Kubernetes worker node"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH access from anywhere (adjust as needed)
  }
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH access from anywhere (adjust as needed)
  }
  # Add additional rules as required, e.g., for API server and etcd communication
}



# Create an EC2 instance for the master node
resource "aws_instance" "master_node" {
  ami           = "var.ami"  # Choose a suitable Kubernetes-ready AMI
  instance_type = "var.instance_type"  # Change to your desired instance type
  key_name      = "var.key_name"  # Specify your SSH key pair

  security_groups = [aws_security_group.master_sg.name]

  # Add any user data or provisioning scripts as needed 
  user_data = file("master.sh")
}

# Create an EC2 instance for the worker node
resource "aws_instance" "worker_node" {
  ami           = "var.ami"  # Choose a suitable Kubernetes-ready AMI
  instance_type = "var.instance_type"  # Change to your desired instance type
  key_name      = "var.key_name"  # Specify your SSH key pair

  security_groups = [aws_security_group.worker_sg.name]

  # Add any user data or provisioning scripts as needed 
  user_data = file("master.sh")
}









# Output the master node's public IP address for reference
output "master_public_ip" {
  value = aws_instance.master_node.public_ip
}

  
