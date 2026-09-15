### Which of the following commands is used to list all installed packages on an ubuntu system?
<details>
<summary>Answer</summary>

<code>apt list --installed </code>

</details>


### Remove nginx package
<details>
<summary>Answer</summary>

<code>apt remove nginx -y</code>

</details>


### Check if there is a newer version of wget package available and install it

<details>
<summary>Answer</summary>

```
wget --version

apt update
apt list --upgradable | grep wget
apt install wget

```

OR

```
apt-cache policy wget 
```
Newest version available in your repositories. You might see:

```
Installed: 1.21.3-1ubuntu1
Candidate: 1.21.3-1ubuntu1.1
```

Here, Candidate is the newest version available from your configured repositories.

</details>