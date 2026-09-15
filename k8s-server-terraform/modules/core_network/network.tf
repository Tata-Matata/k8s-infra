//parent network equivalent to VPC in AWS
resource "hcloud_network" "private_net" {
  name     = "private-net-k8s-playground"
  ip_range = var.private_network_cidr
}

//actual usable subnet inside the parent network
//VMs get IPs from this subnet
resource "hcloud_network_subnet" "private_subnet" {
  network_id   = hcloud_network.private_net.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.private_subnet_cidr
}