output "server_id" {
  description = "ID of the created Hetzner server"
  value       = hcloud_server.server.id
}