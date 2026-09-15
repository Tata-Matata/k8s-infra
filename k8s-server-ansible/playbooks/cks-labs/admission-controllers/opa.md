## OPA

<details>
<summary>Answer</summary>

Open Policy Agent is the general-purpose policy engine. It doesn't inherently care about Kubernetes.
You give OPA: input + policy written in Rego and OPA evaluates to allow / deny

</details>

## Gatekeeper


<details>
<summary>Answer</summary>

Gatekeeper is the Kubernetes integration for OPA.Gatekeeper is a software system/application deployed into your Kubernetes cluster. It consists of multiple pieces (s. custom admission plugin implementation in theory.md)

When you install Gatekeeper, Gatekeeper's installation manifests configure the necessary Kubernetes webhook machinery.

- Gatekeeper Deployment/Pods
- Service
- certificates/TLS
- ValidatingWebhookConfiguration for API server to recognize: "send certain requests to Gatekeeper"

You can inspect it:

<code>kubectl get validatingwebhookconfiguration </code>

and you'll typically see a Gatekeeper-related configuration.


One of its important **functions** is: Expose an admission webhook so the Kubernetes API server can ask Gatekeeper whether an object violates policy.

Kubernetes --> AdmissionReview --> Gatekeeper --> OPA --> Rego

Gatekeeper:

- runs in your Kubernetes cluster
- registers an admission webhook
- receives admission requests from the API server
- converts/evaluates them against OPA policies
- tells the API server whether the request should be allowed

kubectl
   │
   ▼
Kubernetes API Server
   │
   │ admission
   ▼
Gatekeeper webhook (pod)
   │
   ▼
evaluate constraints
   │
   ▼
Rego
   │
   ▼
violation?
   │
   ├──── YES ────► reject request
   │
   └──── NO ─────► allow request


</details>


## ConstraintTemplate and Constraints

<details>
<summary>Answer</summary>

Gatekeeper deliberately separates: "What kind of policy do I want?"

from:

"Where do I apply it and with what parameters?"

### ConstraintTemplate
ConstraintTemplate = policy template
But not the actual policy

Suppose you want a reusable rule: *Containers must not run as privileged.*

You could write the Rego logic. But you don't necessarily want to hard-code: *apply this to every Pod everywhere.*

Instead, you create a ConstraintTemplate.

```
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sdisallowprivileged
spec:
  crd:
    spec:
      names:
        kind: K8sDisallowPrivileged
      validation:
        openAPIV3Schema:
          type: object
  targets:
  - target: admission.k8s.gatekeeper.sh
    rego: |
      package k8sdisallowprivileged

      violation[{"msg": msg}] {
        container := input.review.object.spec.containers[_]
        container.securityContext.privileged == true

        msg := "Privileged containers are not allowed"
      }
```

#### rego

 is actual policy logic.

#### target: admission.k8s.gatekeeper.sh

is telling Gatekeeper which target implementation should evaluate the Rego. "This Rego policy is intended for Gatekeeper's Kubernetes admission target."
It is not a shell command and has nothing to do with Bash. This is a Gatekeeper target identifier.

#### crd
The CRD K8sDisallowPrivileged is created when we apply this yaml. Now we can create constraints (actual policies) with **Kind: K8sDisallowPrivileged** (s. below)


After applying this yaml we haven't yet said: "Reject privileged Pods." We've only defined the type of constraint that can do that.

### Constraint
Constraint = actual policy instance

```
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sDisallowPrivileged
metadata:
  name: no-privileged
```

Now you're saying: Create an instance of the K8sDisallowPrivileged policy.

You can also have parameters. For example, imagine a template saying: *Images must come from an approved registry.* The template defines the general rule: image must come from allowed registry. Then a Constraint might say:

```
parameters:
  registries:
    - "registry.example.com"
    - "docker.io/mycompany"
```

</details>

## kube-mgmt

<details>
<summary>Answer</summary>

kube-mgmt is an older/different Kubernetes integration used with OPA directly.
kube-mgmt can synchronize Kubernetes objects/data into OPA and help integrate OPA with Kubernetes.

the important distinction is:

OPA + kube-mgmt

versus

OPA + Gatekeeper

</details>
