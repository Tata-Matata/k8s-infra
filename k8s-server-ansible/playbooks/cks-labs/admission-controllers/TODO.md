1. Lab for troubleshooting incorrect admission controller configuration if api server is static pod

We need a custom admission controller (for ex., rejecting pulling latest images) and a config file for this admission controller, for ex., /etc/kubernetes/imgvalidation/adm-controller.yaml


```
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  path: /etc/kubernetes/imgvalidation/imagepolicy-conf.yaml

```

When we add it to kube-apiserver, we specify

--enable-admission-plugins
--admission-control-config-file=/etc/kubernetes/imgvalidation/adm-controller.yaml


- first, it is easy to forget to define volumeMount to make /etc/kubernetes/imgvalidation/adm-controller.yaml available inside the api-server static pod. 
- second, if we only map it as file, kube-apiserver will not start, because this config refers to /etc/kubernetes/imgvalidation/imagepolicy-conf.yaml (s. above), and this must also be mapped. So the solution would be either mapping each file separately or the whole directory /etc/kubernetes/imgvalidation/
- Troubleshooting is not trivial, because kubelet has a lot of logs that are hard to search through. crictl ps and crictl logs will help immediately, but this needs to be done before the container is deleted
