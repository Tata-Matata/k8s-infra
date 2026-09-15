### TO BE FINISHED later In the context of multi-tenancy

We don't want workloads of one tenant to be able to resolve DNS names of other tenants.

#### The problem

``` 
namespace: team-a
  pod-a
  service-a

namespace: team-b
  pod-b
  service-b
```

#### TODO

how to configure multi-tenant clusters with separate CoreDNS instances?
more or less realistically



#### CoreDNS configuration
Normally, Kubernetes DNS lets team-a query: service-b.team-b.svc.cluster.local and get the IP of service-b. We want to prevent this.

**in-namespace** in the code below tells the CoreDNS Kubernetes plugin: If the DNS query is for a Kubernetes name in a namespace that CoreDNS isn't going to answer, fall through to the next plugin.

``` 
.:53 { 
    ... 
    kubernetes cluster.local in-addr.arpa ip6.arpa { 
        pods verified 
        fallthrough in-namespace 
    } 
    prometheus :9153 
    forward . /etc/resolv.conf

``` 


Suppose a workload from **team-a** asks: *service-b.team-b.svc.cluster.local*. The Kubernetes plugin checks the query. Because this is a Kubernetes DNS name in another namespace, the plugin doesn't answer it and:

<code>fallthrough in-namespace</code>

causes the query to continue to:

<code>forward . /etc/resolv.conf</code>

To make this actually work we need separate CoreDNS-A and CoreDNS-B instances (separate CoreDNS deployments and services) and configure pods to use the proper DNS server

``` 
spec:
  dnsPolicy: None
  dnsConfig:
    nameservers:
      - 10.0.0.10
``` 



kubectl edit configmap coredns -n kube-system