---
marp: true
theme: default
paginate: true
backgroundColor: #fff
backgroundImage: url('https://marp.app/assets/hero-background.jpg')
---

# 🛡️ SELinux the Easy Way
### A Practical Guide for QA Engineers

### Andrea Manzini
#### Software Quality Engineer @ SUSE

May 2026

---

# 📋 Agenda

1. Why QA Cares About SELinux
2. Labels: What They Are, How to Work With Them
3. Managing SELinux: Modes, Booleans, Ports
4. Troubleshooting Denials
5. Live Demo: Break It, Find It, Fix It
6. QA Cheat Sheet

---

# 🎯 Why QA Cares About SELinux

![bg right:35%](images/works_on_my_machine.jpg)

* SELinux is the **default MAC** on SLES 16, Leap 16, and Tumbleweed
* Customers run SELinux in **Enforcing** mode — so must QA
* Testing with SELinux OFF = **shipping untested code**
* SELinux denials look like permission errors — easy to misdiagnose
* A proper bug report with SELinux context saves developers **hours**

> "It works on my machine" — because you had SELinux disabled.

---

# 🏷️ What is a Label?

Every object in the system has a **security context** (label):

```
system_u : system_r : httpd_t : s0:c1,c2
  user       role       type      level
```

---

# 🔍 Label Fields Explained

**User** (`system_u`, `unconfined_u`, `staff_u`)
* SELinux user — mapped from Linux users. Controls which roles are available.
* `system_u` = system daemons, `unconfined_u` = regular users (no restrictions)
* Check mappings: `semanage login -l`

**Role** (`system_r`, `object_r`, `unconfined_r`)
* Bridges users to types — limits which domains a user can enter
* `system_r` = system processes, `object_r` = files/passive objects
* Mostly relevant in strict/MLS policies, less so in targeted policy

**Type** (`httpd_t`, `user_home_t`, `tmp_t`)
* **The field you'll work with 95% of the time**
* Processes have a **domain** (`httpd_t`), files have a **type** (`httpd_sys_content_t`)
* Policy rules: `allow <domain> <type> : <class> { <permissions> };`

**Level** (`s0`, `s0:c1,c2`)
* MLS sensitivity + MCS categories. Used for container isolation.
* See: [Red Hat MLS/MCS docs](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/using_selinux/using-multi-level-security-mls_using-selinux)

---

# 👀 Viewing Labels

```bash
# Files
$ ls -Z /var/www/html/index.html
system_u:object_r:httpd_sys_content_t:s0 /var/www/html/index.html

# Processes
$ ps -eZ | grep nginx
system_u:system_r:httpd_t:s0     1234 ?  00:00:00 nginx

# Your own context
$ id -Z
unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
```

**Rule**: if a process in domain `X_t` tries to access a file of type `Y_t`, SELinux checks the policy for an `allow X_t Y_t` rule.

---

# ✏️ Changing Labels

| Tool | Permanent? | Use case |
|------|-----------|----------|
| `chcon -t httpd_sys_content_t file` | No (lost on relabel) | Quick testing |
| `semanage fcontext -a -t httpd_sys_content_t '/srv/web(/.*)?'` + `restorecon -Rv /srv/web` | Yes | Production fix |

**QA tip**: always use `semanage fcontext` + `restorecon` in test procedures. `chcon` changes silently vanish after `restorecon -R` or a full relabel.

---

# ⚠️ The mv/cp Trap

![bg right:30%](images/its_a_trap.jpg)

```bash
# Create a test config
$ echo "server {}" > /tmp/mysite.conf
$ ls -Z /tmp/mysite.conf
unconfined_u:object_r:user_tmp_t:s0  /tmp/mysite.conf

# COPY inherits destination label
$ cp /tmp/mysite.conf /etc/nginx/conf.d/
$ ls -Z /etc/nginx/conf.d/mysite.conf
unconfined_u:object_r:httpd_config_t:s0     # correct!

# MOVE keeps original label
$ mv /tmp/mysite.conf /etc/nginx/conf.d/
$ ls -Z /etc/nginx/conf.d/mysite.conf
unconfined_u:object_r:user_tmp_t:s0         # WRONG! nginx can't read this
```

**Fix**: `restorecon -v /etc/nginx/conf.d/mysite.conf`

---

# 🐛 QA Angle: Labels in Bug Reports

When filing a bug where SELinux might be involved, **always include**:

```bash
# 1. Label of the file/directory that failed
ls -Z /path/to/file

# 2. Label of the process that got denied
ps -eZ | grep <process_name>

# 3. What label the file SHOULD have
matchpathcon /path/to/file

# 4. Current SELinux mode
getenforce
```

A bug report that says "permission denied" without this info is **incomplete**.

---

# 📖 Policies: The Rulebook

A **policy** is the set of rules that defines what each domain (process type) is allowed to do.

**Policy types** (set in `/etc/selinux/config`):

| Policy | Description | Use case |
|--------|------------|----------|
| **targeted** | Only known services are confined, everything else runs unconfined | Default on SLES 16 / Tumbleweed / Leap 16 |
| **minimum** | Like targeted but fewer services confined | Minimal environments |
| **mls** | Full Multi-Level Security | Government/military only |

---
**Policies are modular** — built from independent `.pp` modules:

```bash
# List loaded policy modules
$ sudo semodule -l | head
httpd    1.14.0
nginx    1.12.1
container  2.200.0

# Install a custom module
$ sudo semodule -i my_fix.pp

# Remove a module
$ sudo semodule -r my_fix
```

SLES 16 ships **440+ policy modules** out of the box (based on Fedora upstream policy with SUSE-specific patches). Custom modules are how you extend the policy — `audit2allow -M` generates them.

---

# 🧩 Policy Rules: A Concrete Example

A Type Enforcement (TE) rule looks like this:

```
allow  httpd_t  httpd_sys_content_t : file  { read getattr open };
─────  ───────  ──────────────────   ────   ──────────────────────
  │     source       target          class      permissions
  │     domain       type
  │
  └─ "allow this to happen"
```

**Read it as**: "A process running in the `httpd_t` domain is allowed to `read`, `getattr`, and `open` files labeled `httpd_sys_content_t`."

You can query existing rules with `sesearch`:

```bash
# What can httpd_t read?
$ sesearch --allow -s httpd_t -t httpd_sys_content_t -c file
allow httpd_t httpd_sys_content_t:file { getattr ioctl lock map open read };

# What can WRITE to /var/log/httpd?
$ sesearch --allow -t httpd_log_t -c file -p write
allow httpd_t httpd_log_t:file { append create write ... };
```

If no rule exists → **denied**. That's the "default deny" principle.

---

# 📂 Where Do Policies Live? (on SUSE)

```
/etc/selinux/
├── config                      # SELINUX=enforcing, SELINUXTYPE=targeted
└── targeted/
    ├── policy/policy.33        # compiled binary policy (loaded by kernel)
    ├── contexts/               # default contexts for logins, services, etc.
    └── modules/                # installed policy modules (recently migrated here)

/usr/share/selinux/targeted/    # source .pp modules shipped by packages
```

**Key packages** (zypper):

| Package | Contents |
|---------|----------|
| `selinux-policy` | Base policy, file contexts, core types |
| `selinux-policy-targeted` | The targeted policy variant (440+ modules) |
| `container-selinux` | Policy for Podman/Docker containers |
| `policycoreutils-python-utils` | `semanage`, `audit2allow`, `audit2why` |

**SUSE-specific**: policy modules recently migrated from `/var/lib/selinux` to `/etc/selinux` so they're covered by BTRFS snapshots and rollbacks.

---

# 🔀 SELinux Modes

![bg right:30%](images/one_does_not_simply.jpg)

| Mode | Behavior | When to use |
|------|----------|-------------|
| **Enforcing** | Blocks + logs denials | Always (production & testing) |
| **Permissive** | Logs but does NOT block | Diagnosing SELinux issues only |
| **Disabled** | Kernel support off | Never (requires reboot + relabel to re-enable) |

---

```bash
$ getenforce                    # Check current mode
Enforcing

$ sudo setenforce 0             # Switch to Permissive (temporary)
$ sudo setenforce 1             # Back to Enforcing

# Permanent: edit /etc/selinux/config
SELINUX=enforcing
```

---

# 🔘 Booleans: Policy Switches

Modify policy behavior **without writing custom rules**.

```bash
# List all booleans related to httpd
$ getsebool -a | grep httpd
httpd_can_network_connect --> off
httpd_can_sendmail --> off
httpd_enable_homedirs --> off

# Allow Apache to make network connections
$ sudo setsebool -P httpd_can_network_connect on
```

The **`-P`** flag = persistent across reboots. Without it, the change is lost on restart.

---

# 🔌 Port Labeling

SELinux controls which processes can **bind** to which ports.

```bash
# See what ports SSH is allowed to use
$ sudo semanage port -l | grep ssh
ssh_port_t                     tcp      22

# Move SSH to port 2222 → it will FAIL to start
# Fix: add the port to the policy
$ sudo semanage port -a -t ssh_port_t -p tcp 2222

# Verify
$ sudo semanage port -l | grep ssh
ssh_port_t                     tcp      2222, 22
```

Same applies to any service using a non-standard port.

---

# 📁 File Context Rules

The **permanent** way to manage labels for custom paths:

```bash
# Tell SELinux: everything under /srv/myapp is web content
$ sudo semanage fcontext -a -t httpd_sys_content_t '/srv/myapp(/.*)?'

# Apply the rule to existing files
$ sudo restorecon -Rv /srv/myapp
Relabeled /srv/myapp from unconfined_u:object_r:default_t:s0
  to unconfined_u:object_r:httpd_sys_content_t:s0

# Verify
$ ls -Z /srv/myapp/
system_u:object_r:httpd_sys_content_t:s0 index.html
```

---

# ✅ QA Angle: Testing with SELinux

![bg right:33%](images/this_is_fine.jpg)

**Rules for QA test environments:**

1. **Always test in Enforcing mode** — matches customer environments
2. Use Permissive **only** to diagnose, then switch back immediately
3. Never put `setenforce 0` in test setup scripts
4. After installing/upgrading a package, run `restorecon -R` on its paths
5. If a test fails with "Permission denied", check SELinux **before** filing a DAC bug

**Test matrix consideration:**
| Scenario | SELinux Mode | Expected |
|----------|-------------|----------|
| Normal operation | Enforcing | Pass |
| After relabel | Enforcing | Pass |
| Fresh install | Enforcing | Pass |

---

# 🔎 Where to Look for Denials

```bash
# The audit log (primary source)
$ sudo ausearch -m AVC -ts recent

# Or directly
$ sudo grep "avc:  denied" /var/log/audit/audit.log

# Via journald
$ sudo journalctl -t audit --since "10 minutes ago" | grep AVC
```

**No denials showing?** Check:
- Is `auditd` running? (`systemctl status auditd`)
- Is SELinux actually in Enforcing? (`getenforce`)
- Some denials are "dontaudit" — use `semodule -DB` to temporarily disable dontaudit rules

---

# 🔬 Anatomy of a Denial

```
type=AVC msg=audit(1716000000.123:456): avc:  denied  { read }
  for  pid=1234 comm="nginx" name="mysite.conf"
  dev="sda1" ino=5678
  scontext=system_u:system_r:httpd_t:s0
  tcontext=unconfined_u:object_r:user_tmp_t:s0
  tclass=file permissive=0
```

| Field | Meaning |
|-------|---------|
| `{ read }` | What action was denied |
| `comm="nginx"` | Which program tried |
| `scontext=...httpd_t...` | Process domain (subject) |
| `tcontext=...user_tmp_t...` | File type (target) |
| `tclass=file` | Object class |

**Read it as**: "nginx (`httpd_t`) tried to read a file labeled `user_tmp_t` → denied"

---

# ⚡ The Quick Check: Is It SELinux?

```bash
# Step 1: Something fails. Is SELinux blocking it?
$ sudo setenforce 0          # Permissive mode

# Step 2: Retry the operation
$ sudo systemctl restart nginx
# If it works now → SELinux was blocking it

# Step 3: IMMEDIATELY switch back
$ sudo setenforce 1

# Step 4: Find the denial
$ sudo ausearch -m AVC -ts recent
```

**Never leave a system in Permissive mode** after testing. Automate: set a timer or use `at` to switch back.

---

# 🔧 audit2why & audit2allow

```bash
# WHY was it denied?
$ sudo ausearch -m AVC -ts recent | audit2why
Was caused by: Missing type enforcement (TE) allow rule.
  Allow rules: allow httpd_t user_tmp_t:file read;

# WHAT rule would fix it?
$ sudo ausearch -m AVC -ts recent | audit2allow
#============= httpd_t ==============
allow httpd_t user_tmp_t:file read;

# Generate a loadable policy module
$ sudo ausearch -m AVC -ts recent | audit2allow -M my_nginx_fix
$ sudo semodule -i my_nginx_fix.pp
```

**Warning**: `audit2allow` may suggest overly broad rules. Always check what it proposes before loading.

---

# 🚨 setroubleshoot / sealert

Human-readable analysis of denials:

```bash
$ sudo sealert -a /var/log/audit/audit.log

SELinux is preventing nginx from read access on the file mysite.conf.

*****  Plugin restorecon (99.5 confidence) suggests   **************
If you want to fix the label:
  restorecon -v /etc/nginx/conf.d/mysite.conf

*****  Plugin catchall (1.49 confidence) suggests   *****************
If you want to allow httpd_t to read user_tmp_t files:
  audit2allow -M mypol
```

`sealert` ranks suggestions by confidence — **start from the top**.

---

# 📝 QA Angle: Filing SELinux Bugs

**Template for SELinux-related bug reports:**

```
## Environment
- OS: SLES 16 SP0 / openSUSE Tumbleweed
- SELinux mode: Enforcing
- Package version: nginx-1.26.1-1.suse

## Problem
nginx fails to start after config file was deployed by automation.

## SELinux Data
### AVC Denial:
<paste from: ausearch -m AVC -ts recent>

### Diagnosis:
<paste from: ausearch -m AVC -ts recent | audit2why>

### Current vs Expected Labels:
$ ls -Z /etc/nginx/conf.d/mysite.conf
unconfined_u:object_r:user_tmp_t:s0       # ACTUAL
$ matchpathcon /etc/nginx/conf.d/mysite.conf
/etc/nginx/conf.d/mysite.conf  httpd_config_t  # EXPECTED
```

---

# 🧪 Demo Setup

**Prerequisites**: openSUSE Tumbleweed with `distrobox` and `podman` installed.

```bash
# From this repo's directory:
$ ./setup-lab.sh

# This will:
# 1. Create a Tumbleweed distrobox named "selinux-lab"
# 2. Install SELinux tools, nginx, audit utilities
# 3. Copy a sample audit log for offline demos

# Enter the lab:
$ distrobox enter selinux-lab
```

All demo commands in the following slides can be run inside this container.
Note: actual enforcement requires a system with SELinux enabled in the kernel (Tumbleweed, SLES 16).

---

# 💥 Demo: nginx Can't Read Its Config

```bash
# 1. Create a config file in /tmp
echo 'server { listen 8080; root /usr/share/nginx/html; }' \
  > /tmp/demo.conf

# 2. Move it (not copy!) to nginx config dir
sudo mv /tmp/demo.conf /etc/nginx/conf.d/

# 3. Check the label — it's WRONG
ls -Z /etc/nginx/conf.d/demo.conf
# → user_tmp_t (should be httpd_config_t)

# 4. On a real enforcing system: nginx would fail to start
#    Check the audit log for the AVC denial

# 5. Fix it
sudo restorecon -v /etc/nginx/conf.d/demo.conf
# → Relabeled to httpd_config_t

# 6. Verify
ls -Z /etc/nginx/conf.d/demo.conf
```

---

# 🚪 Demo: Service on a Non-standard Port

```bash
# 1. Check which ports httpd_t can bind to
sudo semanage port -l | grep http_port
# → http_port_t    tcp    80, 81, 443, 488, ...

# 2. Try to use port 8888 → SELinux would block it
#    The AVC denial would show:
#    denied { name_bind } for ... scontext=...httpd_t...

# 3. Add port 8888 to the allowed list
sudo semanage port -a -t http_port_t -p tcp 8888

# 4. Verify
sudo semanage port -l | grep http_port
# → http_port_t    tcp    8888, 80, 81, 443, ...

# 5. Now the service can bind to port 8888
```

---

### 📋 QA Cheat Sheet

| Task | Command |
|------|---------|
| Check SELinux mode | `getenforce` |
| View file labels | `ls -Z /path/to/file` |
| View process labels | `ps -eZ \| grep <name>` |
| Find recent denials | `ausearch -m AVC -ts recent` |
| Explain a denial | `ausearch -m AVC -ts recent \| audit2why` |
| Fix a wrong label | `restorecon -v /path/to/file` |
| Check expected label | `matchpathcon /path/to/file` |
| Add permanent label rule | `semanage fcontext -a -t <type> '/path(/.*)?'` |
| Toggle boolean | `setsebool -P <bool> on` |
| Quick SELinux test | `setenforce 0` → test → `setenforce 1` |

---

# 🙏 Thank You!

**Questions?**

Andrea Manzini

Software Quality Engineer @ SUSE

Lab setup & slides:
`github.com/andreamanzini/presentations/selinux_the_easy_way`
