//for ssh into server, private key is local, 
//public key is registered with Hetzner Cloud and injected into the server upon creation
resource "hcloud_ssh_key" "k8s-infra-admin" {
  name       = "k8s-infra-admin"
  public_key = file(var.ssh_public_key)
}

moved {
  from = hcloud_ssh_key.admin
  to   = hcloud_ssh_key.k8s-infra-admin
}