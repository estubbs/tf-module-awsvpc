resource "aws_vpc" "k8svpc" {
  cidr_block = var.vpc_cidr
}

resource "aws_default_network_acl" "defaultAcl" {
  default_network_acl_id = aws_vpc.k8svpc.default_network_acl_id

  tags = {
    "Name" = join("_", [var.name_tag_base, "default"])
  }
}

resource "aws_default_route_table" "defaultRouteTable" {
  default_route_table_id = aws_vpc.k8svpc.default_route_table_id
  tags = {
    "Name" = join("_", [var.name_tag_base, "default"])
  }
}

resource "aws_default_security_group" "defaultSG" {
  depends_on = [aws_vpc.k8svpc]
  vpc_id     = aws_vpc.k8svpc.id

  tags = {
    "Name" = join("_", [var.name_tag_base, "default"])
  }
}

resource "aws_vpc_dhcp_options" "dhcpOptions" {
  domain_name         = "ec2.internal"
  domain_name_servers = ["AmazonProvidedDNS"]
}

resource "aws_vpc_dhcp_options_association" "dhcpOptionsAssociation" {
  dhcp_options_id = aws_vpc_dhcp_options.dhcpOptions.id
  vpc_id          = aws_vpc.k8svpc.id
}
