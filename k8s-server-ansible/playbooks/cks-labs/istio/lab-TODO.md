play around with different mechanisms of Istio injection (namespace, pod) and different PeerAuthentication (global vs namespaced) - using simple nginx pod and curl pod in different namespaces

kubectl exec -ti -n test test -- curl --head http://helloworld.default.svc:5000/hello 


curl: (56) Recv failure: Connection reset by peer
command terminated with exit code 56