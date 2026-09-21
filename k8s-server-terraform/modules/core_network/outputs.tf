//subnet
output "subnet_id" {
  value = hcloud_network_subnet.private_subnet.id
}

output "subnet_cidr" {
  value = hcloud_network_subnet.private_subnet.ip_range
}

// gateway for access from the worker VM to the parent_network, configured on Linux OS level; 
// comes pre-configured on worker VMs by Hetzner as gateway to the parent_network;
// makes sure VMs can reach each other on the private network;
// We want all egress traffic from private VMs to travel to this default gateway (not only traffic to the private network)
// This way, the egress traffic can be forwarded through controlplane that has public interface and thus acts as bastion or jump server
// this is done in cloud-init on worker VMs (ip route add default)
output "subnet_gateway" {
  value = hcloud_network_subnet.private_subnet.gateway
}


//parent network
output "parent_net_id" {
  value = hcloud_network_subnet.private_subnet.network_id
}

output "parent_net_cidr" {
  value = hcloud_network.private_net.ip_range
}