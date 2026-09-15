## Auditing 

is recording who made what change, when and how. For security, compliance and troubleshooting


## Audit Policy Levels

<details>
<summary>Answer</summary>

#### None

Nothing is logged

#### Metadata

logs request's metadata like user, timestamp..., but not the request or response body

#### Request

logs the metadata and request body, but not response body

#### RequestResponse

logs all of the above

</details>

## Audit Policy definition

<details>
<summary>Answer</summary>

When an event is processed, it's compared against the list of rules in order. The first matching rule sets the audit level of the event. 

Pass the file to API server with <code>--audit-policy-file</code>

If the flag is omitted, no events are logged. 
A policy with **no rules** is treated as illegal.


```

apiVersion: audit.k8s.io/v1 # This is required.
kind: Policy
# Don't generate audit events for all requests in RequestReceived stage.
omitStages:
  - "RequestReceived"
rules:
  # Do not log get or list events on pods
  - level: None
    verbs:
    - get
    - list
    resources:
    - group: ""
      resources: ["pods"]

 
```

#### Subresources example

```

  # Log "pods/log", "pods/status" at Metadata level
  - level: Metadata
    resources:
    - group: ""
      resources: ["pods/log", "pods/status"]

```


group: "" means the core API group. So these are core API resources:

/api/v1/namespaces/.../pods/...

These are subresources of Pods: ["pods/log", "pods/status"]

For example:

<code>kubectl logs mypod</code>

accesses roughly:

<code> GET /api/v1/namespaces/default/pods/mypod/log</code>

while:

<code> kubectl get pod mypod -o json</code>

normally accesses the main pods resource, whereas operations involving pod status can access:

<code> .../pods/mypod/status </code>


#### Resource names example

```

  # Don't log requests to a configmap called "controller-leader"
  - level: None
    resources:
    - group: ""
      resources: ["configmaps"]
      resourceNames: ["controller-leader"]

```


#### Users and groups example

```

  # Don't log watch requests by the "system:kube-proxy" on endpoints or services
  - level: None
    users: ["system:kube-proxy"]
    verbs: ["watch"]
    resources:
    - group: "" # core API group
      resources: ["endpoints", "services"]

  # Don't log authenticated requests to certain non-resource URL paths.
  - level: None
    userGroups: ["system:authenticated"]
    nonResourceURLs:
    - "/api*" # Wildcard matching.
    - "/version"

```


#### Namespaced resources example

```

  # Log the request body of configmap changes in kube-system.
  - level: Request
    resources:
    - group: "" # core API group
      resources: ["configmaps"]
    # This rule only applies to resources in the "kube-system" namespace.
    # The empty string "" can be used to select non-namespaced resources.
    namespaces: ["kube-system"]

```

#### Resources of certain API groups

```

  # Log all other resources in core and extensions at the Request level.
  - level: Request
    resources:
    - group: "" # core API group
    - group: "extensions" # Version of group should NOT be included.

```

####  A catch-all rule

```

  # A catch-all rule to log all other requests at the Metadata level.
  - level: Metadata
    # Long-running requests like watches that fall under this rule will not
    # generate an audit event in RequestReceived.
    omitStages:
      - "RequestReceived"
 

```

</details>

## Audit backend configuration

<details>
<summary>Answer</summary>

Specified as flag to API server

#### Log backend

```

--audit-log-path=/var/log/kubernetes/audit.log

```


#### Webhook backend

- Splunk
- ElasticSearch
- Vector
- Grafana Loki
- Cloud provider services

API server can send audit events to another service configured with something like:

```

--audit-webhook-config-file=...
```

</details>