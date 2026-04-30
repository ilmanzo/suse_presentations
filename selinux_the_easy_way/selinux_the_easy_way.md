---
marp: true
theme: default
paginate: true
backgroundColor: #fff
backgroundImage: url('https://marp.app/assets/hero-background.jpg')
---

# Introduction to SELinux
### Security-Enhanced Linux

### Andrea Manzini
#### Software Quality Engineer @ SUSE

May 2026

---

# Agenda

1.  What is SELinux & Principles
2.  SELinux vs. AppArmor
3.  DAC vs. MAC
4.  Core Concepts: Contexts & Types
5.  SELinux Modes & Booleans
6.  Practical Management
7.  Troubleshooting Workflow
8.  Case Studies & Best Practices

---

# Why SELinux? (Principles)

*   **Principle of Least Privilege**: Every process gets exactly the permissions it needs and nothing more.
*   **Default Deny**: If it's not explicitly allowed by the policy, it's blocked.
*   **Defense in Depth**: Even if a process is compromised (e.g., `httpd`), the attacker inherits the "sandbox" limits.
*   **Isolation**: Processes are isolated from each other regardless of the user running them.

---

# SELinux vs. AppArmor

| Feature | SELinux | AppArmor |
| :--- | :--- | :--- |
| **Approach** | Label-based (Contexts) | Path-based (Profiles) |
| **Complexity** | High (Steep learning curve) | Moderate (Easier to read) |
| **Flexibility** | Extremely high (Fine-grained) | Lower (File path focus) |
| **Protection** | System-wide by default | Program-specific profiles |
| **Ecosystem** | RHEL, Fedora, CentOS | Ubuntu, Debian, SUSE |

---

# DAC vs. MAC

*   **DAC (Discretionary Access Control):**
    *   "I own this file, so I decide who can read it."
    *   Based on User/Group IDs.
*   **MAC (Mandatory Access Control):**
    *   "The system policy says only web servers can read files in `/var/www/html`."
    *   Based on security labels (Contexts).

---

# The SELinux Decision Process

1.  A Subject (Process) tries to perform an Action on an Object (File/Socket).
2.  The Kernel checks standard DAC permissions first.
3.  If DAC allows, the Kernel queries the **SELinux Policy**.
4.  If the policy allows, the action proceeds. Otherwise, it's denied and logged.

---

# SELinux Modes

*   **Enforcing**: Full protection. Blocks and logs unauthorized actions.
*   **Permissive**: Diagnosis mode. Logs unauthorized actions but does **not** block them.
*   **Disabled**: Kernel support is off. Requires a reboot to re-enable (and usually a full disk relabel).

---

# SELinux Labels (Contexts)

Everything has a label: `user:role:type:level`

*   **User**: SELinux user (mapping to Linux users).
*   **Role**: Defines what roles a user can assume.
*   **Type**: **The most important part.** Defines the "domain" for processes and the "type" for files.
*   **Level**: Used for MLS (Multi-Level Security).

---

# Type Enforcement (TE)

*   This is the core of most SELinux usage.
*   Rule example:
    `allow httpd_t httpd_sys_content_t : file { read getattr };`
*   "Processes running in the `httpd_t` domain can `read` and `get attributes` of files labeled `httpd_sys_content_t`."

---

# SELinux Booleans

*   Modify policy behavior at runtime without writing code.
*   Example: Allow Apache to send email.
*   `getsebool -a | grep httpd`
*   `setsebool -P httpd_can_sendmail on`
*   The `-P` flag makes it persistent across reboots.

---

# Managing File Contexts

*   **`ls -Z`**: View contexts.
*   **`chcon`**: Changes context (temporary, lost after relabel).
*   **`semanage fcontext`**: Adds a rule to the policy database (permanent).
*   **`restorecon`**: Applies the rules from the database to the files.

---

# The "Moving vs. Copying" Trap

*   **Copying** a file (`cp`): The new file inherits the context of the destination directory.
*   **Moving** a file (`mv`): The file **keeps its original context**.
*   Common issue: Creating a config in `/tmp` and moving it to `/etc/nginx/`. Nginx will be denied access because the file is still labeled `tmp_t`.

---

# Network Security: Port Labeling

*   SELinux also controls which processes can bind to which ports.
*   If you move SSH to port 2222, it will fail to start.
*   `semanage port -l | grep ssh`
*   `semanage port -a -t ssh_port_t -p tcp 2222`

---

# Multi-Category Security (MCS)

*   Standard in modern Linux (Fedora, RHEL).
*   Allows further isolation within the same type.
*   Crucial for **Containers**.
*   Container A and Container B both have type `container_t`, but different categories (e.g., `s0:c1,c2` vs `s0:c3,c4`), so they cannot see each other's files.

---

# Case Study: Web Server

*   `httpd` runs as `httpd_t`.
*   Can read `/var/www/html` (`httpd_sys_content_t`).
*   Cannot read `/home/user` (`user_home_t`).
*   Cannot write to `/var/www/html` unless labeled `httpd_sys_rw_content_t`.
*   Impact: A compromised web server cannot steal your SSH keys.

---

# Case Study: Containers (Podman)

*   Podman uses SELinux to isolate containers from the host.
*   If you volume mount a host directory:
    `podman run -v /data:/data:Z ...`
*   The `:Z` flag tells Podman to relabel the volume so the container can access it.

---

# Troubleshooting 101

1.  Is it really SELinux?
    `setenforce 0` (Switch to Permissive).
    If it works now, it's SELinux. **Switch back to Enforcing immediately!**
2.  Find the denial in `/var/log/audit/audit.log` or `journalctl -t audit`.

---

# The Audit Log

Anatomy of a denial:
`type=AVC msg=audit(...): avc:  denied  { read } for  pid=1234 comm="nginx" name="test.conf" dev="sda1" ino=5678 scontext=system_u:system_r:httpd_t:s0 tcontext=unconfined_u:object_r:user_home_t:s0 tclass=file`

*   **scontext**: The process (Subject).
*   **tcontext**: The file (Target).

---

# Tools: audit2why & audit2allow

*   **`audit2why < /var/log/audit/audit.log`**: Explains the denial in plain English.
*   **`audit2allow -a`**: Shows the Type Enforcement rule that would have allowed the action.
*   **`audit2allow -a -M my_fix`**: Creates a custom policy module to fix the issue.

---

# Tools: setroubleshoot

*   A GUI and CLI tool (`sealert`) that provides suggestions.
*   `sealert -a /var/log/audit/audit.log`
*   Gives you specific commands to run (e.g., "Run `restorecon`" or "Flip this Boolean").

---

# Best Practices

*   **Don't disable it!** If you have issues, use Permissive mode while you fix the policy.
*   Prefer Booleans over custom modules.
*   Prefer `semanage fcontext` over `chcon`.
*   Use labels correctly instead of "allowing everything".

---

# Summary

*   SELinux is a powerful MAC system.
*   It protects the system even if a process is compromised.
*   Learning to read the Audit log is key.
*   Labels and Types are your best friends.

---

# Thank You!

**Questions?**

Andrea
@yourhandle / website.com
