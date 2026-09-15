//subnet
output "subnet_id" {
  value = hcloud_network_subnet.private_subnet.id
}

output "subnet_cidr" {
  value = hcloud_network_subnet.private_subnet.ip_range
}


//parent network
output "parent_net_id" {
  value = hcloud_network_subnet.private_subnet.network_id
}

output "parent_net_cidr" {
  value = hcloud_network.private_net.ip_range
}