
//NETWORK
variable "subnet_cidr" {
  description = "CIDR of the private network allowed to SSH into bastion"
  type        = string
}

variable "parent_network_id" {
  description = "ID of the parent network where the servers will be attached"
  type        = string

}

variable "public_ip_enabled" {
  description = "Whether the server should have a public IPv4 address"
  type        = bool
  default     = false

}

//SERVER
variable "server_type" {
  default = "cx23"
  type    = string
}

locals {
  host_ip = cidrhost(var.subnet_cidr, var.host_offset)
}

// e.g., for 10.50.1.20 use offset 20
variable "host_offset" {
  description = "Host offset inside subnet server IP"
  type        = number
}

variable "ssh_key_ids" {
  description = "List of Hetzner SSH key IDs to inject for root access (optional, can be empty if user_data is used to inject keys for ansible user)"
  type        = list(string)
}

variable "server_location" {
  type    = string
  default = "nbg1" //Nuremberg
}

variable "os_image" {
  default = "ubuntu-22.04"
  type    = string
}

variable "server_name" {
  description = "Name of the server to be created"
  type        = string

}

variable "user_data" {
  description = "User data script to initialize the server"
  type        = string
  default     = ""

}

variable "server_labels" {
  description = "Labels to assign to the server"
  type        = map(string)
  default     = {}
}
