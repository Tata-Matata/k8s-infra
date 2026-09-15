variable "ssh_public_key" {
  type        = string
  description = "Admin SSH public key for ssh into the server"
  default     = "~/.ssh/k8s-infra/id_ed25519.pub"
}

variable "hcloud_token" {

  type        = string
  description = "Hetzner Cloud API token"
  sensitive   = true
}
