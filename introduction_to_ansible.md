---
paginate: true
marp: true
footer: andrea.manzini@suse.com
theme: default
class: 
#  - invert
  

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
## Benefits of Automation

What does automation enable:
- Scalability
- Reliability
- Repeatability
- Consistency
- Auditability
- Security

---
## Some widely-known configuration Management Tools

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

---

##  Ansible features
- Based on Python
- Agentless (only needs Python on remote host)
- Only requires SSH
- Push based

---
# Idempotency

Configure systems using shell script can be simple and effective, but:
- complex logic to follow
- env variables scoping rules
- portability issues between distributions or operating system
- they are not repeatable (e.g. **idempotent**)

### With Ansible we solve this problem by writing the final destination state we want to reach; the tool makes only the necessary changes.



---
### Idempotency example #1
```yaml
# Ensure the user Adam exists in the system
    - name: Add the user 'Adam' with a specific uid and a primary group of 'sudo'
      ansible.builtin.user:
        name: adam
        comment: Adam Engineer
        uid: 1077
        group: sudo
        createhome: yes
        home: /home/users/adamlis    
```
vs 
```bash
$ adduser / useradd -b -u -d -G ... 
$ adduser / useradd -b -u -d -G ... 
ERROR: user 'adam' already exists
```

---
### Idempotency example #2
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
## installing Ansible

we will use a development container for our workshop:

```
$ toolbox enter
```

When you have shell access to container, installation is simple:

```
# zypper install ansible
```
This need to be run only on the "main" node. Ansible by default works via ssh connection sending/pushing commands to other machines.

---
## Ansible Hello World

```bash
$ ansible -m ping localhost
localhost | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

this means that Ansible is correctly installed and working. `-m` stands for "use this module". The `ping` module does not **change** anything on the host, it simply reply back to test the communication.

---
# Ansible Basic Terminology

- **Task** : A single action to perform
- **Play** : A collection of tasks
- **Playbook** : YAML file containing one or more plays

![Workflow](img/ansible-workflow.png "Ansible Workflow")

---
PLAYBOOK EXAMPLE: INSTALL & CONFIGURE APACHE WEBSERVER

```yaml
# begin of playbook
--- 
- name: first play to install and start apache
  hosts: localhost
  connection: local
  become: yes
  tasks:
    - name: install apache2 (task1)
      zypper: name=apache2 state=latest
    - name: start apache2 (task2)
      systemd:
        state: started
        name: apache2
- name: second play, includes another play from a file
  ansible.builtin.import_playbook: otherplays.yaml        
# end of playbook
```

---
# More Terminology

- **Module** : Blob of Python code which is executed to perform task 
- **Inventory**: File containing hosts and groups of hosts to run tasks
- **Role**: A mechanism for reusing and organizing code in Ansible in a standard  hierarchy
- **Facts**: Builtin variables related to remote systems (i.e. ipaddress, hostname, cpu, ram, disk, etc.). They are filled-in by the `setup` module which is always run by default. Let's see the facts in our machine: 

```
$ ansible localhost -m setup | less
```

---
# running Ansible

There are two ways to run ansible:

1. ad hoc

  Run a single task

  `ansible <pattern> [options]`

2. Playbook

Run multiple tasks (a *playbook*) sequentially

  `ansible-playbook <pattern> [options]`

---
# Inventory

Ansible inventory is the list of hosts where we want to apply our recipe. 
The simplest inventory is a single file with a list of hosts and groups. The default location for this file is `/etc/ansible/hosts`. You can specify a different inventory file at the command line using the `-i <path>` option or in configuration using inventory.

A inventory can contain many groups of hosts and associate variables to the group or at the host level.

The inventory can be made dynamic, user can provide a script that outputs list of machines (there are some already made for most cloud providers)

---
SIMPLE INVENTORY EXAMPLE

```ini
machine-debug.example.suse.de
another_server-1.example.suse.de

[virtual_machines]
openqa-worker1.example.suse.asia
srv01.example.suse.asia
srv02.example.suse.asia
srv03.example.suse.asia
srv04.example.suse.asia
srv05.example.suse.asia

[baremetal]
baremetal1.example.suse.de
baremetal2.example.suse.de

[asia]
openqa-worker1.example.suse.asia
srv0[1-5].example.suse.asia

[europe]
machine-debug.example.suse.de
baremetal[1-2].example.suse.de
another_server-1.example.suse.de
```


---
INVENTORY EXAMPLE with GROUP VARS

```ini
[asia]
openqa-worker1.example.suse.asia
srv0[1-5].example.suse.asia

[europe]
machine-debug.example.suse.de
baremetal[1-2].example.suse.de
another_server-1.example.suse.de

[asia:vars]
ntp_server=time-sync-server.example.suse.com 
nfs_path="another-nfs-server.suse.asia:/folder/blabla/pckgs"

[europe:vars]
ntp_server=ntp.suse.de 
nfs_path="11.22.33.44:/folder nfs-server.suse.de:/mnt/myfolder"

```
---
## How Ansible talks to hosts ?

By default, Ansible uses native OpenSSH, because it supports ControlPersist (a performance feature), Kerberos, and options in `~/.ssh/config` such as Jump Host setup.

By default, Ansible connects to all remote devices with the user name you are using on the control node. If that user name does not exist on a remote device, you can [set a different user name for the connection](https://docs.ansible.com/ansible/latest/inventory_guide/connection_details.html#setting-a-remote-user).

If you just need to do some tasks as a different user, use [privilege escalation](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_privilege_escalation.html#become):

```yaml
- name: Ensure the httpd service is running
  service:
    name: httpd
    state: started
  become: true
```

--- 
# Facts

By default, whenever you run an Ansible playbook, Ansible first gathers information
(“facts”) about each host in the play.
```
$ ansible-playbook playbook.yml
PLAY [group] ********************************************************
GATHERING FACTS *****************************************************
ok: [host1]
ok: [host2]
ok: [host3]
```

--- 
# Facts

Facts can be extremely helpful when you’re running playbooks; you can use
gathered information like host IP addresses, CPU type, disk space, operating system
information, and network interface information to change when certain tasks are
run, or to change certain information used in configuration files.

to see all available facts on a system: `$ ansible localhost -m ansible.builtin.setup`

--- 
# Local Facts

Another way of defining host-specific facts is to place a .fact file in a special
directory on remote hosts, `/etc/ansible/facts.d/`. These files can be either JSON
or INI files, or you could use executables that return JSON. As an example, create
the file `/etc/ansible/facts.d/settings.fact` on a remote host, with the following
contents:
```ini
[users]
admin=jane,john
normal=jim
```
Next, use Ansible’s setup module to display the new facts on the remote host:
```bash
$ ansible hostname -m setup -a "filter=ansible_local"
```


---
# Conditionals

A task can be conditionally executed with the `when:` keyword. 

```yaml
tasks:
  - name: Shut down CentOS 6 and Debian 7 systems
    ansible.builtin.command: /sbin/shutdown -t now
    when: (ansible_facts['distribution'] == "CentOS" and ansible_facts['distribution_major_version'] == "6") or
          (ansible_facts['distribution'] == "Debian" and ansible_facts['distribution_major_version'] == "7")
```

[see more example on the documentation](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_conditionals.html)


---
# Register variables

There are many times that you will want to run a command, then use its return code,
stderr, or stdout to determine whether to run a later task. For these situations, Ansible
allows you to use register to store the output of a particular command in a variable
at runtime.

```yaml
     - name: Run a shell command and register its output as a variable
       ansible.builtin.shell: /usr/bin/foo
       register: foo_result
       ignore_errors: true

     - name: Run a shell command using output of the previous task
       ansible.builtin.shell: /usr/bin/bar
       when: foo_result.rc == 5
```

---
# When to quote variables (a YAML gotcha)

If you start a value with {{ foo }}, you must quote the whole expression to create valid YAML syntax. 

```yaml
- hosts: app_servers
  vars:
      app_path: {{ base_path }}/myapp
```

You will see: `ERROR! Syntax Error while loading YAML.` If you add quotes, Ansible works correctly:

```yaml
- hosts: app_servers
  vars:
       app_path: "{{ base_path }}/myapp"
```

---
# Loops / Iteration 1

Repeated tasks can be written as standard loops over a simple list of strings. You can define the list directly in the task or keep the values in a variable

```yaml
- name: Add several users
  ansible.builtin.user:
    name: "{{ item }}"
    state: present
    groups: "developers"
  loop:
     - joe
     - frank
     - "{{ another_big_list_of_users }}"
```
---
# Loops / Iteration 2


You can use the until keyword to retry a task until a certain condition is met. Here’s an example:

```yaml
- name: Retry a task until a certain condition is met
  ansible.builtin.shell: /usr/bin/foo
  register: result
  until: result.stdout.find("all systems go") != -1
  retries: 5
  delay: 10
```


for details please [see documentation](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_loops.html)


---
# Handlers

Sometimes you want a task to run only when a change is made on a machine. For example, you may want to restart a service if a task updates the configuration of that service, but not if the configuration is unchanged. Ansible uses handlers to address this use case. __Handlers are tasks that only run when notified.__

[See documentation example](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_handlers.html)


---
# Templating

When we want to refer to some variable content, introduce some logic expressions or provide a file, we can use the **Jinja2** template engine embedded in Ansible. 

A template contains variables and/or expressions, which get replaced with values when a template is rendered; and tags, which control the logic of the template. The template syntax is heavily inspired by Django and Python.

- most common is `{{ }}` for Expressions (emit the template output)
- there is also `{% %}` for Statements and `{# #}` for Comments

[See template documentation](https://jinja.palletsprojects.com/en/latest/templates/)

---
# Templating Example

    $ cd ansible_examples
    $ ansible-playbook -i inventory.txt motd.yml
    $ cat /tmp/motd

*exercise*: we want to give some control to the user, who can for example change the destination file or include/exclude IPV6 addresses. How can we achieve that ? 



---
#### Ansible vault : Keeping secrets secret
If you use Ansible to fully automate the provisioning and configuration of your
servers, chances are you will need to use passwords or other sensitive data for some
tasks, whether it’s setting a default admin password, synchronizing a private key, or authenticating to a remote service.

It’s better to treat passwords and sensitive data specially, and
there are two primary ways to do this:

1. Use a separate secret management service, such as Vault by HashiCorp,
Keywhiz by Square, or a hosted service like AWS’s Key Management Service
or Microsoft Azure’s Key Vault.
2. Use Ansible Vault, which is built into Ansible and stores encrypted passwords
and other sensitive data alongside the rest of your playbook.

---
# Ansible Vault

### How it works:
Ansible Vault works much like a real-world vault:
1. You take any YAML file you would normally have in your playbook (e.g. a
variables file, host vars, group vars, role default vars, or even task includes!),
and store it in the vault.
2. Ansible encrypts the vault (‘closes the door’), using a key (a password you set).
3. You store the key (your vault’s password) separately from the playbook in a
location only you control or can access.
4. You use the key to let Ansible decrypt the encrypted vault whenever you run
your playbook.


---
# What is Ansible roles?

**Roles** are a way to group multiple tasks together into one container to do the automation in very effective manner with clean directory structures.

Roles are set of tasks and additional files for a certain role which allow you to break up the configurations.

It can be easily reuse the codes by anyone if the role is suitable to someone.

It can be easily modify and will reduce the syntax errors.

an example Ansible Role can be to [install a WordPress website](https://github.com/MakarenaLabs/ansible-role-wordpress). It requires a web server, php, a database, the application and some configuration

---
# Ansible galaxy

Ansible roles are powerful and flexible; they allow you to encapsulate sets of
configuration and deployable units of playbooks, variables, templates, and other files,
so you can easily reuse them across different servers.

It’s annoying to have to start from scratch every time, though; wouldn’t it be better
if people could share roles for commonly-installed applications and services?
Enter [Ansible Galaxy](https://galaxy.ansible.com/).

Ansible Galaxy, or just ‘Galaxy’, is a repository of community-contributed Ansible
content. There are thousands of roles available which can configure and deploy com-
mon applications, and they’re all available through the ansible-galaxy command.

---
# Ansible Galaxy

Galaxy offers the ability to add, download, and rate roles. With an account, you can
contribute your own roles or rate others’ roles (though you don’t need an account to
use roles).

```bash
$ ansible-galaxy role install geerlingguy.apache \
geerlingguy.mysql geerlingguy.php
```
---
# A LAMP server in nine lines of YAML

```yaml
# file: lamp-setup.yml
- hosts: all
  become: yes
  roles:
    - geerlingguy.mysql
    - geerlingguy.apache
    - geerlingguy.php
    - geerlingguy.php-mysql
```
```bash
$ ansible-playbook -i path/to/custom-inventory lamp-setup.yml
```

---
# Anatomy of a Role

TODO directory structure


---
# let's look at real use case

https://sap-linuxlab.github.io/

TODO find some concrete and easy to follow example in the repo


---
# Thanks!

These slides are Open Source and live in a [github repository](https://github.com/ilmanzo/suse_presentations), feel free to improve them 💚

![bg right fit](img/opensuse-logo-color.svg)