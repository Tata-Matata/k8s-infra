### What is a syscall?


<details>
<summary>Answer</summary>

the interface a user-space program uses to ask the Linux kernel to perform privileged operations.
A normal application cannot directly manipulate hardware, kernel memory, page tables, network interfaces, etc. Instead, it asks the kernel:

- open this file
- create this process
- send these bytes over this socket
- allocate memory

</details>

### User space vs kernel space


<details>
<summary>Answer</summary>

Linux separates memory/CPU privileges into different privilege levels. Kernel code has much greater privileges. If an ordinary process could directly modify kernel memory, a compromised application could potentially take over the entire machine.

**User space** is where normal programs run. They have restricted access. For example, cat /etc/passwd cannot simply read arbitrary physical memory.


The kernel and kernel-level code run in **kernel space**:

- Linux kernel
- kernel modules
- device drivers


</details>

### How a syscall works

<details>
<summary>Answer</summary>

For ex., <code>cat /etc/hostname </code> needs to read a file and write content to terminal.
cat isn't directly reading the disk or directly writing to your terminal. It is making kernel requests.

cat --> **open()** -->  kernel accesses file on filesystem

cat --> **read()** --> kernel retrieves bytes --> cat --> **write()** --> terminal


</details>

### Observe a process's system calls

<details>
<summary>Answer</summary>

<code>strace ls</code> 

The output is something like

```

execve("/usr/bin/ls", ["ls"], 0x7ffd60ad1a60 /* 56 vars */) = 0
brk(NULL)                               = 0x5ac8b2a62000
mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x754315419000
access("/etc/ld.so.preload", R_OK)      = -1 ENOENT (No such file or directory)
openat(AT_FDCWD, "/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3
fstat(3, {st_mode=S_IFREG|0644, st_size=75111, ...}) = 0
mmap(NULL, 75111, PROT_READ, MAP_PRIVATE, 3, 0) = 0x754315406000
close(3)              
...
```

</details>

### Follow a process and its children

<details>
<summary>Answer</summary>

<code>strace -f ls</code> 


</details>


### Follow an already running process

<details>
<summary>Answer</summary>

<code>strace -p PID</code> 

PID can be determined by *ps aux* or *pgrep nginx*

Very useful for troubleshooting:

- "Why is this process stuck?"
- "Is it trying to connect somewhere?"
- "Which file is it trying to access?"

</details>

### Trace only specific syscalls

<details>
<summary>Answer</summary>

#### file specific

<code>strace -e trace=file ls</code> 

You can see things such as:

```
openat(...)
statx(...)
access(...)
unlink(...)
rename(...)
```

Very useful for answering: Which files is this program actually accessing?

#### memory specific

<code>strace -e trace=memory ls</code> 

</details>

### Observe Network operations

<details>
<summary>Answer</summary>

<code>strace -e trace=network curl https://example.com</code> 

You can see things such as:

```
socket(...)
connect(...)
sendto(...)
recvfrom(...)
close(...)
```

</details>

### Summarize system calls

<details>
<summary>Answer</summary>

<code>strace -c ls</code> 

This tells you:

- which syscalls were made
- how many times
- how much time they consumed
- how many failed

Very useful for getting the big picture rather than thousands of individual lines.

```

% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 41.29    0.000860         860         1           execve
 17.57    0.000366          20        18           mmap
  7.78    0.000162          23         7           openat
  6.96    0.000145          16         9           close
  6.24    0.000130          18         7           write
  5.28    0.000110          22         5           read
  4.85    0.000101          50         2           getdents64
  3.84    0.000080          10         8           fstat

```

</details>