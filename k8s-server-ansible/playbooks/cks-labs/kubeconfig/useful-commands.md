# View currently used config

<details>
<summary>Answer</summary>

```
kubectl config view
```

This is for default config in ~/.kube. For file in another path

```
kubectl config view --kubeconfig <path>
```

</details>

# Change current context

<details>
<summary>Answer</summary>

```
kubectl config use-context produser@prodcluster
```

**This will override the config file!**

</details>

# Change default config file make it persistent across all sessions without overwriting the existing ~/.kube/config. Ensure any configuration changes persist across reboots and new shell sessions.

<details>
<summary>Answer</summary>

```
vi ~/.bashrc
export KUBECONFIG=~/myconfig
source ~/.bashrc    

```

</details>