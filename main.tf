# main.tf
resource "aws_vpc" "dev_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "dev_pub_subnet" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-3a"
  tags = {
    Name = "dev_pub"
  }
}

resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name = "dev_igw"
  }
}

resource "aws_route_table" "dev_pub_route" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name = "dev_rt"
  }
}

resource "aws_route" "dev_route" {
  route_table_id            = aws_route_table.dev_pub_route.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.dev_igw.id
}

resource "aws_route_table_association" "dev_pub_assoc" {
  subnet_id      = aws_subnet.dev_pub_subnet.id
  route_table_id = aws_route_table.dev_pub_route.id
}

resource "aws_security_group" "dev_sg" {
  name        = "dev_sg"
  description = "Dev_Security_Group"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Only allow trsusted ip addresses
  }

    egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow it to access open internet  
    }

  tags = {
    Name = "Dev_SG"
  }
}

# Generate SSH Key /home/abdoulie/.ssh/devkey

resource "aws_key_pair" "dev_key_auth" {
  key_name   = "devkey"
  public_key = file("~/.ssh/devkey.pub")

}

resource "aws_instance" "foo" {
  ami           = data.aws_ami.server_ami.id
  instance_type = "t2.micro"
  key_name = aws_key_pair.dev_key_auth.id # On peut utiliser key_name à la place de id
  vpc_security_group_ids = [aws_security_group.dev_sg.id]
  subnet_id = aws_subnet.dev_pub_subnet.id

  tags ={
    Name = "dev-node"
  }

} 