1. TF state on Hashicorp
2. before adding multiple control planes, provision a stable private Kubernetes API endpoint (internal load balancer or private DNS/VIP) and point both control_plane_endpoint and cilium_k8s_service_host at it
3. automate synchronization of Terraform outputs for control plane public IPs and node private IPs into k8s-server-ansible/inventory/hosts.yaml. As well as gateway ip that Hetzner generates when creating network and subnet
4. CI/CD for Ansible: 
   -  ansible-lint for style, bad patterns, and common mistakes.
   -  ansible-playbook --syntax-check for basic validity.
   -  molecule for role/playbook testing, often with Docker, Podman, or ephemeral VMs.
   -  testinfra or plain verification tasks for post-provision assertions.
  
5. CI/CD for terraform: 
   - terraform fmt -check for formatting.
   - terraform validate for config validity.
   - tflint for Terraform-specific linting.
   - tfsec or checkov for security/policy checks.
   - terratest or native terraform test for deeper module/integration testing.
  
  6. static analysis
   - tfsec, checkov, terrascan, kics
   - gitleaks