## Run 02-lab-fix-rbac playbook

The playbook creates a role and rolebinding to allow default service account to get/watch/list pods and to create configmaps.
However, after the role and rolebinding are created, the default SA still can't get information about a specific pod and it can not create configmaps
Troubleshoot and fix.

## Test and fix permissions to get/watch/list pods

<details>
<summary>Show answer</summary>


<details>
<summary>Possible troubleshooting strategies</summary>


1. Create a pod and check what exactly is not working
   
   <code>kubectl get pods</code>
   <code>kubectl get pod mypod</code>

   The first command works, the second fails 

   You can also double check with

   <code> kubectl auth can-i get pod --as system:serviceaccount:default:default -n default </code>
   <code> kubectl auth can-i list pod --as system:serviceaccount:default:default -n default </code>



2. Increase verbosity

<code> kubectl get pod <pod-name> -v=8 </code>

3. Check if the role is in the same namespace as pod
4. Check if the verbs in the role include list and get
5. Check if rolebinding points to the correct service account
6. List all that default SA can do 
<code>  kubectl auth can-i --list --as system:serviceaccount:default:default </code> 

This surprisingly shows that default service account can actually get, list and watch pods
7. Check if more than one rule applies to default SA, and maybe one of them is restricted by resouce names
8. Check resource names in the rule

</details>

<details>
<summary>Solution</summary>
**resourceNames** restricts the rule to specific pod names.
In this case, it is set to "", equivalent to *Only allow access to a resource whose name is the empty string*

#### Why does list still work?

The list verb does not operate on a named object. It operates on the collection:
<code> GET /api/v1/namespaces/default/pods </code>
There is no resource name in the request, so the resourceNames restriction is effectively ignored for list.

#### Fix
remove **resourceNames** completely

</details>
</details>

## Test and fix permissions to create configMaps

<details>
<summary>Show answer</summary>

<details>
<summary>Possible troubleshooting strategies</summary>
1. Increase verbosity
   <code>kubectl create configmap test --from-literal=key=value --as=system:serviceaccount:default:default -v=8</code>

2. Verify with can-i

<code>kubectl auth can-i create configmaps --as=system:serviceaccount:default:default</code>

3. If it says no - verify rolebinding (correct service account?) and namespaces
4. Check if the resource, the verbs, the resource names are correct


<details>
<summary>Solution</summary>
Resource names in RBAC are case-sensitive. The canonical resource name is: configmaps

To verify:
<code>kubectl api-resources | grep config</code>

#### Fix
change **configMaps** to **configmaps**

</details>
</details>

</details>