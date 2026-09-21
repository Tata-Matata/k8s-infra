//subnet
output "subnet_id" {
  value = module.core_network.subnet_id
}

output "subnet_cidr" {
  value = module.core_network.subnet_cidr
}

// gateway for access from the worker VM to the parent_network, configured on Linux OS level; 
// comes pre-configured on worker VMs by Hetzner as gateway to the parent_network;
// makes sure VMs can reach each other on the private network;
// We want all egress traffic from private VMs to travel to this default gateway (not only traffic to the private network)
// This way, the egress traffic can be forwarded through controlplane that has public interface and thus acts as bastion or jump server
// this is done in cloud-init on worker VMs (ip route add default)
output "subnet_gateway" {
  value = module.core_network.subnet_gateway
}

//parent network
output "parent_network_id" {
  value = module.core_network.parent_net_id
}

output "parent_net_cidr" {
  value = module.core_network.parent_net_cidr
}