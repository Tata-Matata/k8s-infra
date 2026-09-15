

### Kernel modules

<details>
<summary>Answer</summary>


The Linux kernel can contain functionality in two forms:

- built-in → compiled directly into the kernel
- module → compiled separately and loaded into the kernel when needed

Typical things implemented as modules:

- hardware drivers
- filesystem drivers
- networking functionality
- security functionality
- virtualization components

Modules usually live as **.ko** files in subdirs under: <code> /lib/modules/$(uname -r)/ </code>

For ex.: /lib/modules/6.14.0-37-generic/kernel/drivers/tty/ttynull.ko.zst

</details>

### Check what is currently loaded

<details>
<summary>Answer</summary>

**lsmod**

For example

<code> nf_conntrack  204800  1  nf_nat </code>

means another module (nf_nat) is using nf_conntrack. 
204800 = Memory occupied by the module.

</details>


### Load a module

<details>
<summary>Answer</summary>

```
sudo modprobe overlay 

lsmod | grep overlay

```

modprobe will load the required dependencies automatically.

</details>


### Remove a module

<details>
<summary>Answer</summary>

```
sudo modprobe -r overlay

```

It will fail if something is currently using the module.

</details>

### Blacklisting module

<details>
<summary>Answer</summary>


Create .conf file under **/etc/modprobe.d/**

```
/etc/modprobe.d/blacklist.conf

```

containing:

```
blacklist foo

```

Then <code>sudo modprobe foo </code> will normally be prevented from automatically loading it.

This is commonly relevant when:

- two drivers compete for hardware
- you need to disable an unwanted driver
- security hardening requires disabling functionality


</details>

### Check whether something is built-in or a module

<details>
<summary>Answer</summary>


Suppose you want to know about overlay:

<code> lsmod | grep overlay </code>

If it appears → it's currently loaded as a module. But if it doesn't appear, that does not necessarily mean the functionality doesn't exist. It might be **compiled directly into the kernel.**

You can inspect the kernel configuration:

<code> grep CONFIG_OVERLAY_FS /boot/config-$(uname -r) </code>

You might see:

<code> CONFIG_OVERLAY_FS=m </code>

Meaning: <code>  m = module </code>

Whereas: <code>  CONFIG_OVERLAY_FS=y </code> means: <code>  y = built into kernel </code>


</details>


### Inspect a module

<details>
<summary>Answer</summary>

```
sudo modinfo overlay

```

It will fail if something is currently using the module.

</details>


### If I loaded this module, what would modprobe do?

<details>
<summary>Answer</summary>


This is useful for understanding dependencies and configuration.

```
sudo modprobe -n -v overlay

```

-n = don't actually do it

-v = verbose

</details>