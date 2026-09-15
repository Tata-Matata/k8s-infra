### Configuration 

<details>
<summary>Answer</summary>

When Kubernetes stores a Secret in etcd, you can configure the API server to encrypt it:

<code>--encryption-provider-config=/etc/kubernetes/encryption-config.yaml</code>

#### Example of config file

```
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration

resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: <base64-encoded-32-byte-key>
      - identity: {}

```

The order of providers is important. 
For **writing** new data, the first provider is used.
But for **reading** try the providers in order.
The *identity* provider is essentially "no encryption."

</details>


#### Why have a list?

<details>
<summary>Answer</summary>

Because Kubernetes needs to be able to read existing data that may have been encrypted using an older provider/key.

The main reason: **key rotation**

Suppose your cluster initially uses:

```
providers:
  - aescbc:
      keys:
        - name: key1
          secret: <key1>

```

Secret A gets stored encrypted with *key1* in etcd. Six months later you want to rotate the encryption key.
You don't immediately remove *key1*, because existing Secrets are still encrypted with it.

Instead you change the configuration to:

```
providers:
  - aescbc:
      keys:
        - name: key2
          secret: <key2>

  - aescbc:
      keys:
        - name: key1
          secret: <key1>

```

Now new writes use *key2*. Existing data will be decrypted with *key1*

</details>

### There are actually two levels of lists in the config

<details>
<summary>Answer</summary>

List of providers and list of keys within one provider is also possible

```
providers:
  - aescbc:
      keys:
        - name: key2
          secret: ...
        - name: key1
          secret: ...
  - identity: {}
```

The first key is used for **encryption**. The API server can use the other configured keys to **decrypt** existing data.

</details>



### How to migrate existing Secrets to new key (provider)

<details>
<summary>Answer</summary>

<code>kubectl get secrets --all-namespaces -o json  | kubectl replace -f - </code>

The API server reads each Secret using the old provider if necessary and then writes it using the first provider, thereby re-encrypting it with *key2*.

After successful migration, you can eventually remove *key1* from the configuration.

</details>




### why use identity provider
<details>
<summary>Answer</summary>

The *identity* provider is essentially "no encryption." The data is stored as-is.
It is useful during migration because the API server can read both:

- encrypted Secret → aescbc
- plaintext Secret  → identity

</details>


### If encryption is not activated 

<details>
<summary>Answer</summary>

you can basically see etcd entries in clear text


<code>ETCDCTL_API=3 etcdctl get /registry/secrets/default/secret1 [...] | hexdump -C </code>


if **etcdctl** is not available on host - install with apt. Or exec into etcd static pod

</details>