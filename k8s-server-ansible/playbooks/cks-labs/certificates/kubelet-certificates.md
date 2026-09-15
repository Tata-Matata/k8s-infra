# Kubelet auth as client to K8s API server

Paths to Kubelet's certificate and private key can be found in Kubelet's  kubeconfig usually at 
<code>/etc/kubernetes/kubelet.conf</code>. The path to kubeconfig itself can be found, for ex., in systemctl output to kubelet's service status


```
kind: Config
users:
- name: system:node:k8s-playground
  user:
    client-certificate: /var/lib/kubelet/pki/kubelet-client-current.pem
    client-key: /var/lib/kubelet/pki/kubelet-client-current.pem
```

.pem file often contains **both the certificate and the private key**, which is why the same file may be referenced for both client-certificate and client-key.


# K8s API server auth as client to Kubelet

Sometimes the API server wants to establish a TLS connection to the kubelet.

For example:

- kubectl logs
- kubectl exec
- kubectl port-forward

The certificate and key paths can be found in API server configuration. For ex., if it is deployed as static pod by kubeadm, check 

<code>cat /etc/kubernetes/manifests/kube-apiserver.yaml  | grep -i kubelet </code>

```
- --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
- --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
```

# Kubelet auth as server to K8s API server (when it acts as client)
The kubelet itself presents a server certificate when something connects to port 10250.

The paths can be either in kubelet's kubeconfig

```
--tls-cert-file
--tls-private-key-file
```

or if missing - the kubelet uses its default certificate manager and stores the serving certificate under <code>/var/lib/kubelet/pki/kubelet.crt and kubelet.key</code>



# How to quickly differentiate which certificate is for what purpose

```
openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -text -noout
openssl x509 -in /var/lib/kubelet/pki/kubelet.crt -text -noout

```

The first pem certificate will have 

```
X509v3 Extended Key Usage: 
  TLS Web Client Authentication
```

The second one 

```
X509v3 Extended Key Usage: 
  TLS Web Server Authentication
```