output "k8s_infra_admin_ssh_public_key" {
  description = "will be injected by hetzner terraform on the server for k8s-infra-admin access via ssh"
  value       = hcloud_ssh_key.k8s-infra-admin.id

}