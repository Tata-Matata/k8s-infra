variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API token"
  sensitive   = true
}


locals {
  my_ip = var.admin_ssh_subnet_cidr != "" ? var.admin_ssh_subnet_cidr : trimspace(data.http.my_ip.response_body)
}

variable "controlplane_offsets" {
  type = map(number)
  default = {
    controlplane-1 = 101
     ##add here
    # controlplane-2 = 102
  }

  validation {
    condition = alltrue([
      for offset in values(var.controlplane_offsets) : offset >= 101 && offset <= 110
    ]) && length(distinct(values(var.controlplane_offsets))) == length(values(var.controlplane_offsets))
    error_message = "controlplane_offsets values must be unique and between 101 and 110."
  }
}

variable "worker_offsets" {
  type = map(number)
  default = {
    worker-1 = 1
    ##add here
    # worker-2 = 2
  }

  validation {
    condition = alltrue([
      for offset in values(var.worker_offsets) : offset >= 1 && offset <= 100
    ]) && length(distinct(values(var.worker_offsets))) == length(values(var.worker_offsets))
    error_message = "worker_offsets values must be unique and between 1 and 100."
  }
}

variable "nat_gateway_host" {
  type        = string
  description = "Control plane host that acts as the NAT gateway for private-only nodes"
  default     = "controlplane-1"

  validation {
    condition     = contains(keys(var.controlplane_offsets), var.nat_gateway_host)
    error_message = "nat_gateway_host must match one of the controlplane_offsets keys."
  }
}

# from which servers admin is allowed to ssh into the k8s server
variable "admin_ssh_subnet_cidr" {
  type = string
}

variable "server_location" {
  type    = string
  default = "nbg1"
}

variable "os_image" {
  type    = string
  default = "ubuntu-24.04"
}

variable "server_type" {
  type    = string
  default = "cx23"
}

variable "worker_dns_servers" {
  description = "Public DNS resolvers configured on private-only worker nodes"
  type        = list(string)
  default     = ["1.1.1.1", "1.0.0.1"]
}



