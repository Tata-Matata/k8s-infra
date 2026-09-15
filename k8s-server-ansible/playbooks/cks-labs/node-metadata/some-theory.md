## Protection strategies

- RBAC access control to allow only specific users to access and modify node metadata
- node isolation reserves specific nodes for designated workloads, ensuring that less critical or unauthorized applications are prevented from running on them
- network policies ensure that only certain services or users can communicate with certain resources (pods, nodes)
- audit logs track who accessed and modified node metadata


## Reasons to secure node metadata


<details>
<summary>Answer</summary>

One purpose of the metadata is that the right workloads land on the right nodes.
If metadata is not secured, an unauthorized user could 

- list all nodes and sensitive info like kubelet version (outdated and vulnerable for ex.) and then launch this version specific attack
- modify taints and for ex. allow non-prod workloads to be scheduled on prod nodes -> resource contention and outages
- list IP addresses and get a map of the internal network to launch a targeted attack against
- get kernel version which breaches compliance with regulations like GDPR, HIPAA


</details>

## Node metadata

<details>
<summary>Answer</summary>

- node name (unique node id within the cluster)
- labels (for grouping, for ex.)
- annotations (for debugging, logging, monitoring. For ex., CNI plugin like Flannel could mark nodes)
- architecture
- system info (OS, kernel version, k8s version, machine ID, OS image)
- addresses (internal and external IPs, hostname)
- Node conditions (state, kubelet version, capacity and allocatable resources, taints, POD CIDR)


</details>

