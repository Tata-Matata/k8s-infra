//subnet
output "subnet_id" {
  value = module.core_network.subnet_id
}

output "subnet_cidr" {
  value = module.core_network.subnet_cidr
}

//parent network
output "parent_network_id" {
  value = module.core_network.parent_net_id
}