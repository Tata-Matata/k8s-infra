# Check which certificate kubelet presents to auth as server

<details>
<summary>Answer</summary>

```
openssl s_client -connect localhost:10250 -showcerts
```

</details>

<details>
<summary>How it works</summary>


We can think of **s_client** as curl for TLS debugging. It performs the TLS handshake and prints everything it learns.
<code> -showcerts makes the server send the entire certificate chain.</code>

OpenSSL performs:

1. TCP connect
2. TLS ClientHello
3. ServerHello
4. Certificate
5. Certificate Verify
6. It then prints everything it saw.


### Useful info in the command output

##### Certificate chain

the output starts with certificate 0, which is the leaf (end-entity) certificate presented by the server.
Here, for example, 0 represents kubelet server certificate, and 1 is the self-generated CA certificate with which the server cert is signed

Subject (s:) = who the certificate belongs to
Issuer (i:) = who signed it 

```
Certificate chain
 0 s:CN = k8s-playground@1780987714
   i:CN = k8s-playground-ca@1780987713


 1 s:CN = k8s-playground-ca@1780987713
   i:CN = k8s-playground-ca@1780987713

```
A certificate chain is always ordered like this:

0  Leaf (server/client certificate)
1  Intermediate CA (if any)
2  Intermediate CA
...
n  Root CA (sometimes sent, sometimes omitted)

##### Subject and issuer

```
Server certificate
subject=CN = k8s-playground@1780987714
issuer=CN = k8s-playground-ca@1780987713
```

##### Acceptable client certificate CA names

<code>CN = kubernetes</code>

"If you want to authenticate with a client certificate, it must chain back to this CA."

##### Verify return code

0 = OK, trusted
19 = self-signed  <code>verify error:num=19:self-signed certificate in certificate chain</code>
20 = unknown CA
21 - unable to verify chain



</details>


# Check if this certificate can be validated against this CA

<details>
<summary>Answer</summary>
```
openssl verify  -CAfile ca.crt kubelet.crt
```

</details>

# Inspect a certificate

<details>
<summary>Answer</summary>

```
openssl x509 -in kubelet.crt -text  -noout
```
#### Only subject

```
openssl x509 -in kubelet.crt -subject  -noout
```

#### Only ussuer

```
openssl x509 -in kubelet.crt -issuer  -noout
```

#### Expiration 

```
openssl x509 -in kubelet.crt -dates  -noout
```

</details>


# Check if certificates are identical

<details>
<summary>Answer</summary>

```
openssl x509 -in cert.crt -noout  -fingerprint -sha256
```

</details>

# Check private key matches certificate

<details>
<summary>Answer</summary>

```
openssl x509 -in cert.crt -pubkey  -noout
openssl x509 -in my.key -pubout 
```
The public keys should be identical.
</details>

# Inspect CSR

<details>
<summary>Answer</summary>

```
openssl req -in csr.pem -text  -noout
```

</details>

# Decode a Kubernetes CSR object

<details>
<summary>Answer</summary>

```
kubectl get csr mycsr -o jsonpath='{.spec.request}' | base64 -d | openssl req -text -noout
```

</details>

# Decode issued certificate from CSR


<details>
<summary>Answer</summary>

```
kubectl get csr mycsr -o jsonpath='{.status.certificate}' | base64 -d | openssl x509 -text -noout
```

</details>


# Check runtime kubelet configuration

<details>
<summary>Answer</summary>

Replace **localhost** in the command below - by IP or hostname as specified in kubelet serving certificate SANs, if the command fails with <code> curl: (60) SSL: no alternative certificate subject name matches target host name 'localhost'</code>

The certificate and key are, for example, the ones used by API server (/etc/kubernetes/pki)

```
curl --cacert ca.crt --cert apiserver-kubelet-client.crt --key apiserver-kubelet-client.key  https://localhost:10250/configz
```

</details>


# Generate private key and CA certificate, sign with it a client certificate for admin user


<details>
<summary>Answer</summary>


```
openssl genrsa -out ca.key 2048
openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA" -out ca.csr
openssl x509 -req -in ca.csr -signkey ca.key -out ca.crt

openssl genrsa -out admin.key 2048
openssl req -new -key admin.key -subj "/CN=kube-admin/OU=system:masters" -out admin.csr
openssl x509 -req -in admin.csr -CA ca.crt -CAKey ca.key -out admin.crt

```
CN **kube-admin** is both for logging and RBAC. Group **system:masters** is to differentiate the user as admin.
To include **alternative** names, use openssl.cnf file and add section 

```
[alt_names]
DNS.1 = kubernetes
DNS2. = kubernetes.default.svc

```

Then use <code>-config openssl.cnf</code> when creating CSR
</details>