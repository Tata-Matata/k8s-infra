output "controlplane_public_ipv4_addresses" {
	description = "Public IPv4 addresses of control plane nodes keyed by host name"
	value = {
		for name, server in module.controlplane :
		name => server.public_ipv4_address
	}
}
