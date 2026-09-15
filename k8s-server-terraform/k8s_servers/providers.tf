terraform {
  required_version = "~> 1.15"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.64"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.6.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}
