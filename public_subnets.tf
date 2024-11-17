resource "aws_subnet" "publicSubnet" {
  count             = var.public_subnet_size > 0 ? length(var.availability_zone_names) : 0
  vpc_id            = aws_vpc.k8svpc.id
  availability_zone = var.availability_zone_names[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, (var.public_subnet_size - split("/", var.vpc_cidr)[1]), count.index)
  tags = {
    "Name" = join("_", [var.name_tag_base, "public", count.index])
  }
}

resource "aws_network_acl" "networkAclPublic" {
  vpc_id = aws_vpc.k8svpc.id
  tags = {
    "Name" = join("_", [var.name_tag_base, "public"])
  }
}

resource "aws_network_acl_association" "networkAclAssocationPublic" {
  count          = var.public_subnet_size > 0 ? length(var.availability_zone_names) : 0
  network_acl_id = aws_network_acl.networkAclPublic.id
  subnet_id      = aws_subnet.publicSubnet[count.index].id
}

resource "aws_route_table" "publicRouteTable" {
  vpc_id = aws_vpc.k8svpc.id

  tags = {
    "Name" = join("_", [var.name_tag_base, "public"])
  }
}

resource "aws_route_table_association" "publicRouteTableAssociation" {
  count          = var.public_subnet_size > 0 ? length(var.availability_zone_names) : 0
  route_table_id = aws_route_table.publicRouteTable.id
  subnet_id      = aws_subnet.publicSubnet[count.index].id

}

resource "aws_internet_gateway" "igw" {
  count  = var.public_subnet_size > 0 ? 1 : 0
  vpc_id = aws_vpc.k8svpc.id
}

resource "aws_route" "publicRoute" {
  count                  = var.public_subnet_size > 0 ? 1 : 0
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[count.index].id
  route_table_id         = aws_route_table.publicRouteTable.id
}
