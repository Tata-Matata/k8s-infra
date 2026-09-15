### Storage QoS

<details>
<summary>Answer</summary>

StorageClasses can select/provision storage with particular performance characteristics.

For example, with AWS EBS, a StorageClass can request an EBS volume type and performance parameters such as IOPS:

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ebs
provisioner: ebs.csi.aws.com
parameters:
  type: io2
  iopsPerGB: "10"
  fsType: ext4
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

The StorageClass says: "Provision this using EBS io2 with these performance characteristics."
he PVC effectively says: "Give me 100 GiB from the fast-ebs storage class."

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database
spec:
  storageClassName: fast-ebs
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
```

</details>
