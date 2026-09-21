1. TF state on Hashicorp
2. . before adding multiple control planes, provision a stable private Kubernetes API endpoint (internal load balancer or private DNS/VIP) and point both control_plane_endpoint and cilium_k8s_service_host at it
3. automate synchronization of Terraform outputs for control plane public IPs and node private IPs into k8s-server-ansible/inventory/hosts.yaml