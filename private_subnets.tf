resource "aws_subnet" "privateSubnet" {
  count             = var.private_subnet_size > 0 ? length(var.availability_zone_names) : 0
  vpc_id            = aws_vpc.k8svpc.id
  availability_zone = var.availability_zone_names[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, (var.private_subnet_size - split("/", var.vpc_cidr)[1]), count.index + (pow(2, 32 - split("/", var.vpc_cidr)[1]) / pow(2, 32 - var.private_subnet_size) - length(var.availability_zone_names)))
  tags = {
    "Name" = join("_", [var.name_tag_base, "private", count.index])
  }
}

resource "aws_network_acl" "networkAclPrivate" {
  vpc_id = aws_vpc.k8svpc.id
  tags = {
    "Name" = join("_", [var.name_tag_base, "private"])
  }
}

resource "aws_network_acl_association" "networkAclAssocationPrivate" {
  count          = var.private_subnet_size > 0 ? length(var.availability_zone_names) : 0
  network_acl_id = aws_network_acl.networkAclPrivate.id
  subnet_id      = aws_subnet.privateSubnet[count.index].id
}

resource "aws_network_acl_rule" "all_inbound_private" {
  network_acl_id = aws_network_acl.networkAclPrivate.id
  protocol = -1
  cidr_block = "0.0.0.0/0"
  rule_action = "allow"
  rule_number = 1
  egress = false
}

resource "aws_network_acl_rule" "all_outbound_private" {
  network_acl_id = aws_network_acl.networkAclPrivate.id
  protocol = -1
  cidr_block = "0.0.0.0/0"
  rule_action = "allow"
  rule_number = 1
  egress = true
}

resource "aws_route_table" "privateRouteTable" {
  vpc_id = aws_vpc.k8svpc.id

  tags = {
    "Name" = join("_", [var.name_tag_base, "private"])
  }
}

resource "aws_route_table_association" "privateRouteTableAssociation" {
  count          = var.private_subnet_size > 0 ? length(var.availability_zone_names) : 0
  route_table_id = aws_route_table.privateRouteTable.id
  subnet_id      = aws_subnet.privateSubnet[count.index].id
}

resource "aws_eip" "natGatewayEip" {
  count = var.use_nat_gateway ? 1 : 0
}

resource "aws_nat_gateway" "natGateway" {
  count         = var.use_nat_gateway ? 1 : 0
  allocation_id = aws_eip.natGatewayEip[count.index].allocation_id
  subnet_id     = aws_subnet.publicSubnet[0].id
}

resource "aws_route" "natGatewayDefaultRoute" {
  count                  = var.use_nat_gateway ? 1 : 0
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natGateway[0].id
  route_table_id         = aws_route_table.privateRouteTable.id
}

resource "aws_ec2_tag" "natGatewayEniTag" {
  count = var.use_nat_gateway ? 1 : 0
  resource_id = aws_nat_gateway.natGateway[0].network_interface_id
  key = "Name"
  value = var.name_tag_base
}

output "private_subnets" {
  value = aws_subnet.privateSubnet.*.id
}
