variable "private_network_cidr" {
  type    = string
  default = "10.50.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.private_network_cidr))
    error_message = "private_network_cidr must be a valid CIDR block"
  }
}

variable "network_zone" {
  description = "Hetzner Cloud Network Zone"
  default     = "eu-central"
  type        = string
}

//part of private_network_cidr
variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  default     = "10.50.1.0/24"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.private_subnet_cidr))
    error_message = "private_subnet_cidr must be a valid CIDR block"
  }
}

