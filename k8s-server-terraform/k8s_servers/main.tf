module "controlplane" {
  for_each = var.controlplane_offsets
  source   = "../modules/hetzner_server"

  #server config
  server_name     = each.key
  server_location = var.server_location
  os_image        = var.os_image
  server_type     = var.server_type

  #admin ssh access
  ssh_key_ids = [data.terraform_remote_state.global_ssh_keys.outputs.k8s_infra_admin_ssh_public_key]


  #network config
  //enable public IP only for controlplane 
  public_ip_enabled = true

  // Hetzner expects here ID of the parent network
  parent_network_id = data.terraform_remote_state.core_network.outputs.parent_network_id

  //But Hetzner also expects server IP that belongs to a subnet of the network
  subnet_cidr = data.terraform_remote_state.core_network.outputs.subnet_cidr

  // e.g., for 10.50.1.5 use offset 5
  host_offset = each.value

  //for attaching firewall
  server_labels = {
    role     = "controlplane",
    firewall = "ssh-only"
  }

}

module "worker" {
  for_each = var.worker_offsets
  source   = "../modules/hetzner_server"

  #server config
  server_name     = each.key
  server_location = var.server_location
  os_image        = var.os_image
  server_type     = var.server_type

  #admin ssh access
  ssh_key_ids = [data.terraform_remote_state.global_ssh_keys.outputs.k8s_infra_admin_ssh_public_key]


  #network config
  // enable public IP only for controlplane; 
  // workers are accessible via ssh jump: laptop --> controlplane --> worker
  // ssh -J user@control-plane user@worker-private-ip
  // same works for Ansible
  public_ip_enabled = false

  // same as controlplane
  parent_network_id = data.terraform_remote_state.core_network.outputs.parent_network_id

  // same as controlplane
  subnet_cidr = data.terraform_remote_state.core_network.outputs.subnet_cidr

  // e.g., for 10.50.1.5 use offset 5
  host_offset = each.value

  //for attaching firewall
  server_labels = {
    role     = "worker",
    firewall = "ssh-jump-via-controlplane"
  }

}

module "hetzner_firewall_ssh_only" {
  source = "../modules/hetzner_firewall_ssh_only"

  #access to the server only from this subnet via ssh
  admin_ssh_subnet_cidr = "${local.my_ip}/32"

}

module "hetzner_firewall_k8s_cluster" {
  source = "../modules/hetzner_firewall_k8s_cluster"

  #access to the controlplanes only from this subnet (laptop) via ssh
  admin_ssh_subnet_cidr = "${local.my_ip}/32"

  # subnet with controlplanes and worker nodes
  private_subnet_cidr   = data.terraform_remote_state.core_network.outputs.subnet_cidr
  
  # IPs of controlplanes as one host subnet
  controlplane_ip_cidrs = [
    for host_offset in values(var.controlplane_offsets) :
    "${cidrhost(data.terraform_remote_state.core_network.outputs.subnet_cidr, host_offset)}/32"
  ]

}
