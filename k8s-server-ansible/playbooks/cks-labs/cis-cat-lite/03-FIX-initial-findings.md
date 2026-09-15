# The idea

As part of preparation for CKS, we want to practice using CIS CAT Lite tool to discover and fix security vulnerabilities on an Ubuntu server. For discovering specific K8s cluster vulnerabilities, we are going to use kube-bench.

## Initial system state

We roll out a VM with Hetzner Terraform provider and install K8s cluster with kubeadm.
At this point, nothing is changed intentionally on the system to introduce vulnerabilities.
Later playbooks, however, might intentionally break certain security features of the server to learn more about them by fixing them.

## Pre-requisites


1. Run playbook install-cis-cat-lit to install java and CIS CAT Lite on the server. 
2. The playbook rollout-report-nginx is optional, it rolls out deployment with nginx pod (behind ClusterIP service) that will serve the html report produced by the tool. This report can then be viewed in browser after port forwarding nginx service
3. For port forwarding (s. below), you need to have admin.conf from the K8s cluster on your machine

## Run CIS CAT Lite and fix findings

1. Run playbook run-cis-cat-lite to execute CIS CAT Lite tool on the server. It publishes html report into host folder that is volume mounted into the pod as  /usr/share/nginx/html
2. Nginx server now serves the static html report. By port forwarding it to your laptop, you can see it in browser

``
 kubectl --kubeconfig ~/kubernetes/hetzner-playground/admin.conf port-forward -n {{ cis_cat_namespace }} svc/{{ cis_cat_nginx_name }} 8888:{{ cis_cat_service_port }} 
``

``
 kubectl --kubeconfig ~/kubernetes/hetzner-playground/admin.conf port-forward -n cis-cat-report svc/cis-cat-report-nginx 8888:80
``
 
3. Open http://localhost:8888 and check the report
4. The report can also be generated on the server by running
   
``
/opt/CIS-CAT-Lite/Assessor/Assessor-CLI.sh  -b /opt/CIS-CAT-Lite/benchmarks/CIS_Ubuntu_Linux_24.04_LTS_Benchmark_v2.0.0-xccdf.xml -p "Level 1 - Server" -nts -rd /srv/cis-cat-report -rp index
``

| Short flag | Long flag | Meaning |
| --- | --- | --- |
| `-nts` | `--no-timestamp` | Do not append a timestamp to the report name |
| `-rd` | `--reports-dir` | Directory where reports are written |
| `-rp` | `--report-prefix` | Prefix used for the report file name |
| `-b` | `--benchmark` | Benchmark file to assess |
| `-p` | `--profile` | Benchmark profile to use |

5. After fixing the initial findings, run playbook run-cis-cat-lite again and check the report

6. For help - check folder initial-findings-fixes
   



