/* 
data "terraform_remote_state" "core_network" {
  backend = "remote" # Terraform Cloud
  config = {
    organization = "your-org"
    workspaces = {
      name = "core-network"
    }
  }
} 
*/

/* 
data "terraform_remote_state" "tf_state_network" {
 
  backend = "remote"

  config = {
    hostname     = "app.terraform.io"
    organization = "tatamatata-org"

    workspaces = {
      name = "core-network"
    }
  }
} */

data "terraform_remote_state" "core_network" {
  backend = "local" # Local backend for testing
  config = {
    path = "../core_network/terraform.tfstate"
  }
}

data "terraform_remote_state" "global_ssh_keys" {
  backend = "local" # Local backend for testing
  config = {
    path = "../global/ssh_keys/terraform.tfstate"
  }
}

data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}


## for retrieving the list of all available images in Hetzner Terraform 
## see outputs
data "hcloud_images" "all_x86" {
  with_architecture = ["x86"]
  with_status       = ["available"]
}