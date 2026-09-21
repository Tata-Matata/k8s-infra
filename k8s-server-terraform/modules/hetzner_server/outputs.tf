output "server_id" {
  description = "ID of the created Hetzner server"
  value       = hcloud_server.server.id
}

output "public_ipv4_address" {
  description = "Public IPv4 address of the server, if enabled"
  value       = hcloud_server.server.ipv4_address
}