variable "name_tag_base" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "availability_zone_names" {
  type = list(string)
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_size" {
  type = number
}

variable "private_subnet_size" {
  type = number
}

variable "use_nat_gateway" {
  type = bool
}
