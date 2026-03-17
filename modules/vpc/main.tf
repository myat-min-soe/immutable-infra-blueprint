data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "public_subnet" {
  count             = 3                                                                                    # Create two public subnets
  cidr_block        = var.public_subnet_cidr[count.index]                                                  # CIDR block for each public subnet from `public_subnet_cidr`
  vpc_id            = aws_vpc.this.id                                                                      # The VPC to associate the subnet with
  availability_zone = element(coalesce(var.azs, data.aws_availability_zones.available.names), count.index) # Choose an AZ from the list or fallback to available AZs
  tags = {
    Name                     = "${var.vpc}-public_subnet-${count.index + 1}",
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id # Attach the gateway to the VPC
  tags = {
    Name = "${var.vpc}-igw"
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    aws_vpc.this # Ensure the VPC is created/modified before creating IGW
  ]
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id # Associate the route table with the VPC
  route {
    cidr_block = "0.0.0.0/0"                  # Route all traffic to the internet
    gateway_id = aws_internet_gateway.this.id # Use the internet gateway as the route
  }
  tags = {
    Name = "${var.vpc}-public-rt"
  }
}

resource "aws_route_table_association" "public_rt_association" {
  count          = 3                                        # Create an association for each public subnet
  subnet_id      = aws_subnet.public_subnet[count.index].id # Associate the route table with each public subnet
  route_table_id = aws_route_table.public_rt.id             # Associate the public route table
}

resource "aws_subnet" "private_subnet" {
  count             = 6                                                                                  # Create six private subnets
  cidr_block        = var.private_subnet_cidr[count.index]                                                 # CIDR block for each private subnet from `private_subnet_cidr`
  vpc_id            = aws_vpc.this.id                                                                      # The VPC to associate the subnet with
  availability_zone = element(coalesce(var.azs, data.aws_availability_zones.available.names), count.index) # Choose an AZ from the list or fallback to available AZs
  tags = {
    Name                              = "${var.vpc}-private_subnet-${count.index + 1}",
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "this" {
  count = var.create_nat ? 1 : 0
  # count = 1
  tags = {
    Name = "${var.vpc}-nat_eip"
  }
}

resource "aws_nat_gateway" "this" {
  count         = var.create_nat ? 1 : 0         # Create NAT gateways or Not
  subnet_id     = aws_subnet.public_subnet[0].id # Attach each NAT gateway to a public subnet
  allocation_id = aws_eip.this[0].id             # Associate each NAT gateway with an Elastic IP
  depends_on    = [aws_eip.this]                 # Ensure the Elastic IPs are created before the NAT gateways
  tags = {
    Name = "${var.vpc}-nat-gw" # Name the NAT gateways with the VPC name and suffix
  }
}

resource "aws_route_table" "private_rt" {
  count  = var.create_nat ? 1 : 0  # Only create if NAT gateway exists
  vpc_id = aws_vpc.this.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[0].id
  }
  
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      route,
    ]
  }
  
  tags = {
    Name = "${var.vpc}-private-rt"
  }
}

resource "aws_route_table_association" "private_rt_association" {
  count          = var.create_nat ? 6 : 0
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = one(aws_route_table.private_rt[*].id)  # Use one() to safely reference
}

