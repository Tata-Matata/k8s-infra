## K8s API

kubectl proxy

pre-requisite: 

in ~/.bashrc KUBECONFIG=/home/tati//kubernetes/hetzner-playground/admin.conf
(s. 42-proxy-to-laptop playbook)

otherwise 

kubectl --kubeconfig ~/kubernetes/hetzner-playground/admin.conf proxy

http://localhost:8001


## kubectl

kubectl get nodes
if KUBECONFIG set

otherwise

kubectl --kubeconfig ~/kubernetes/hetzner-playground/admin.conf get nodes


## CIS CAT Lite report

Use 

kubectl --kubeconfig ~/kubernetes/hetzner-playground/admin.conf port-forward -n cis-cat-report svc/cis-cat-report-nginx 8888:80 

and then open 

http://localhost:8888/index.html