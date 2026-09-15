## Calico web ui

kubectl port-forward -n calico-system service/whisker 8081:8081

pre-requisite: 

in ~/.bashrc KUBECONFIG=/home/tati//kubernetes/hetzner-playground/admin.conf
(s. 42-proxy-to-laptop playbook)

otherwise 

kubectl port-forward  --kubeconfig ~/kubernetes/hetzner-playground/admin.conf -n calico-system service/whisker 8081:8081