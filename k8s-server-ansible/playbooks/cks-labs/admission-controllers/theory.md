### Kubernetes admission-control mechanism

The API server has an admission phase:

API request
    ↓
Authentication
    ↓
Authorization
    ↓
Admission
    ↓
Persistence

During admission, the API server can call admission controllers (built-in or external webhooks)


### Types of admission controllers and their configuration


<details>
<summary>Answer</summary>

There are **built-in admission controllers** that we can enable, disable and provide config for. And there are **custom admission webhooks** that we can implement, deploy and configure


#### built-in admission controllers

The list of enabled ones is specified in k8s PI server's

**--enable-admission-plugins=**

We can also provide configuration file path for them in

**--admission-control-config-file**

```
kind: AdmissionConfiguration
plugins:
  - name: PodSecurity
...
```
</details>

### PodSecurity as example of built-in admission controller

<details>
<summary>Answer</summary>

Its job is to check Pods against the Kubernetes Pod Security Standards (PSS) when they are created or updated.

There are three security levels:

- privileged
- baseline
- restricted

For example, you can configure a namespace so that Pods must satisfy the restricted policy.

#### configuration file

For ex., at /etc/kubernetes/pod-security-config.yaml

```
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration

plugins:
  - name: PodSecurity
    configuration:
      apiVersion: pod-security.admission.config.k8s.io/v1beta1
      kind: PodSecurityConfiguration

      defaults:
        enforce: "restricted"
        enforce-version: "latest"

      exemptions:
        usernames: []
        runtimeClasses: []
        namespaces: []
```

#### tell kube-apiserver about this file

```
kube-apiserver \
  --enable-admission-plugins=PodSecurity \
  --admission-control-config-file=/etc/kubernetes/pod-security-config.yaml
```

#### What happens when you create a Pod?

```
spec:
  containers:
    - name: nginx
      image: nginx
      securityContext:
        privileged: true
```

The request goes:

kubectl
   │
   ▼
kube-apiserver
   │
   ▼
PodSecurity admission controller
   │
   │ "Does this Pod satisfy restricted?"
   │
   ▼
   DENY


The Pod isn't persisted in etcd because the admission controller rejects the request.


#### Namespace-specific configuration

Different namespaces can have different levels of PSS and different modes

```
kubectl label namespace production  pod-security.kubernetes.io/enforce=restricted

kubectl label namespace development \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

For development namespace it means:
- baseline violations are rejected
- resricted violations are recorded in audit and user gets warning

in modern Kubernetes, PodSecurity is **enabled by default** in the standard API-server admission-plugin set


</details>


### Check enabled admission plugins

<details>
<summary>Answer</summary>

If plugin is enabled because it is part of the API server's default admission-plugin set, it does not necessarily appear in --enable-admission-plugins in the static Pod manifest (or in ExecStart args if api server is deployed as service).

The Kubernetes API server has a compiled-in list of default admission plugins. PodSecurity is included in that default set in current Kubernetes versions.

You can see the defaults with:

```
kube-apiserver -h | grep enable-admission-plugins
```


</details>

### Custom admission plugin

<details>
<summary>Answer</summary>


This is the list of things to implement to get your custom admission plugin running:

- Deployment
- Service
- TLS
- ValidatingWebhookConfiguration
- webhook server with AdmissionReview handling



1. Develop application with an HTTPS endpoint that understands Kubernetes AdmissionReview requests.This API server receives an AdmissionReview object from K8s API server and must return an AdmissionReview response.

**Example request**

```
{
  "apiVersion": "admission.k8s.io/v1",
  "kind": "AdmissionReview",
  "request": {
    "uid": "12345",
    "operation": "CREATE",
    "object": {
      "kind": "Pod",
      "metadata": {
        "name": "test"
      },
      "spec": {
        "containers": [
          {
            "name": "nginx",
            "securityContext": {
              "privileged": true
            }
          }
        ]
      }
    }
  }
}
```

**Example Response**

```
{
  "apiVersion": "admission.k8s.io/v1",
  "kind": "AdmissionReview",
  "response": {
    "uid": "12345",
    "allowed": false,
    "status": {
      "message": "Privileged containers are not allowed"
    }
  }
}

```

K8s API server then rejects the Pod.


2. We can deploy webhook as Deployment on the cluster or a stand-alone app on an external server

3. If it is a Deployment - expose via Service

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: security-webhook
  namespace: admission-system
spec:
  replicas: 2
  selector:
    matchLabels:
      app: security-webhook
  template:
    metadata:
      labels:
        app: security-webhook
    spec:
      containers:
        - name: webhook
          image: myregistry/security-webhook:v1
          ports:
            - containerPort: 8443
```

```
apiVersion: v1
kind: Service
metadata:
  name: security-webhook
  namespace: admission-system
spec:
  selector:
    app: security-webhook
  ports:
    - port: 443
      targetPort: 8443
```



Now the API server can reach:

<code>security-webhook.admission-system.svc:443</code>

4. TLS
   
The API server normally communicates with admission webhooks over **HTTPS**. The webhook needs a certificate. The certificate needs to be valid for the Service DNS name, such as:

**security-webhook.admission-system.svc**

The K8s API server also needs to know which CA it should trust. That's where **caBundle** comes in (s. WebhookConfiguration below)

5. API server certificate and private key

This is implementation specific and not prescribed by K8s. A very common pattern is to put the certificate and key in a Kubernetes Secret and mount the secret into the webhook Pod

```
apiVersion: v1
kind: Secret
metadata:
  name: webhook-tls
  namespace: admission-system
type: kubernetes.io/tls
data:
  tls.crt: <certificate>
  tls.key: <private-key>

```

```
spec:
  containers:
    - name: webhook
      image: my-webhook:v1
      volumeMounts:
        - name: tls
          mountPath: /tls
          readOnly: true

  volumes:
    - name: tls
      secret:
        secretName: webhook-tls
```

6. Register the webhook by creating ValidatingWebhookConfiguration (or Mutating)

```
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: security-webhook
webhooks:
  - name: security.example.com

    clientConfig:
      service:
        name: security-webhook
        namespace: admission-system
        path: /validate
        port: 443

      caBundle: <CA-CERTIFICATE>

    rules:
      - apiGroups: [""]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["pods"]

    admissionReviewVersions:
      - v1

    sideEffects: None

```



</details>

### Built-in admission plugin that uses an external webhook service

<details>
<summary>Answer</summary>

This is a combination of both types of admission controllers.

#### ImagePolicyWebhook 

is a **built-in admission plugin** in the Kubernetes API server, but it acts as a **client to an external image-policy webhook server**. And this:

```
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  path: /etc/kubernetes/imgvalidation/imagepolicy-conf.yaml
```

is exactly the kind of configuration used with this K8s API server option:

```
--admission-control-config-file=/path/to/admission-config.yaml
```

The built-in ImagePolicyWebhook plugin handles the integration with the API server, while the actual image policy decision is made by the external webhook.

The path in the example above:  <code>/etc/kubernetes/imgvalidation/imagepolicy-conf.yaml </code> is the path to the configuration file consumed by the built-in ImagePolicyWebhook plugin.

That configuration tells the plugin things such as where the external policy webhook is and how to communicate with it.


</details>