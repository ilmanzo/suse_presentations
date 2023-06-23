---
paginate: true
marp: true
footer: andrea.manzini@suse.com
theme: default
---
# introduction to Ansible

## 

![bg left fit](img/opensuse-logo-color.svg)

---
# A little background

## Automation
is about taking manual processes and placing technology around them to make them repeatable.
Automation is the key to speed, consistency, scalability and repeatability.

Think about car factories in the 1900 vs automated robot industries

---
## Benefits of Automation:

What does automation enable:
- Scalability
- Reliability
- Repeatability
- Consistency
- Auditability
- Security

---
# Configuration Management Tools

- [Salt](https://saltstack.com)
- [Puppet](https://puppetlabs.com)
- [Chef](https://www.chef.io)
- [Ansible](https://www.ansible.com)

---
## What is Ansible?

## Ansible is a tool for:
- Configuration Management
- Deploying software
- Orchestration
- Provisioning

##  Ansible features
- Based on Python
- Agentless (only needs Python on remote host)
- Only requires SSH
- Push based
---
## installing Ansible

```
$ toolbox enter

# zypper install ansible
```




---
PLAYBOOK EXAMPLE: INSTALL & CONFIGURE APACHE

```yaml
---
- name: install and start apache
  hosts: localhost
  connection: local
  become: yes
  tasks:
    - name: install apache2
      zypper: name=apache2 state=latest
    - name: start apache2
      systemd:
        state: started
        name: apache2

```

---
SAP HANA DEPLOYMENT EXTRACT ([source](https://people.redhat.com/mkoch/training/1805-farnborough/presentations/05%20-%20Ansible%20and%20Ansible%20Tower%20Introduction.pdf))

from
```bash
echo "vm.swappiness=60" >> /etc/sysctl.d/90-sap_hana.conf
echo "kernel.msgmni=32768" >> /etc/sysctl.d/90-sap_hana.conf
...
sysctl -p /etc/sysctl.d/90-sap_hana.conf
```
to

```yaml
- name: setting kernel tunables
  sysctl: name={{ item.name }} value={{ item.value }} state=present
          sysctl_set=yes reload=yes
  with_items:
    - { name: kernel.msgmni, value: 32768 }
    - { name: vm.swappiness, value: 60 }
 
```

---
# Thanks!

These slides are Open Source and live in a [github repository](https://github.com/ilmanzo/suse_presentations), feel free to improve them 💚

![bg right fit](img/opensuse-logo-color.svg)