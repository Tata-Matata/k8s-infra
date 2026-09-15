### Network QoS

<details>
<summary>Answer</summary>

Here, QoS means controlling network traffic characteristics, such as:

- bandwidth
- rate limits
- priority
- latency
- packet loss
- traffic classes

For example, conceptually:

Pod A ──► network ──► max 10 Mbit/s
Pod B ──► network ──► max 100 Mbit/s

This is not what a Kubernetes NetworkPolicy normally does. A standard NetworkPolicy answers:
Who is allowed to communicate with whom, and on which ports/protocols? That's access control, not bandwidth control.

And **CNIs** such as Cilium or Calico can provide additional networking capabilities beyond standard Kubernetes NetworkPolicy, including traffic management features.


</details>

### Calico example

<details>
<summary>Answer</summary>

Allow traffic to 10.0.0.0/8, but limit the traffic rate to 10 Mbps.

```
apiVersion: projectcalico.org/v3
kind: NetworkPolicy
metadata:
  name: frontend-policy
  namespace: app
spec:
  selector: app == 'frontend'

  ingress:
  - action: Allow
    source:
      selector: app == 'nginx'
    destination:
      ports:
      - 8080

  egress:
  - action: Allow
    destination:
      selector: app == 'backend'
      ports:
      - 8080

  - action: Allow
    destination:
      nets:
      - 10.0.0.0/8
    limits:
      rate: 10Mbps

  - action: Deny
```



</details>