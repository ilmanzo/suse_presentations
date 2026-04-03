---
paginate: true
marp: true
footer: andrea.manzini@suse.com
theme: default
#theme: gaia
class: invert
backgroundColor: #203020

---
# OpenQA-agnostic testing

## [a proposal]

![bg left fit](../img/opensuse-logo-color.svg)

### Andrea Manzini

---

- https://github.com/os-autoinst/os-autoinst-distri-opensuse/tree/master/data/security/testPolkit

![bg right fit](../img/torvalds_quote.png)


---
# Changelog

 - 31.10.2025 This is v2 of the proposal. Previous version was using a custom test runner and output TAP results, while this one uses standard Go Testing framework and output results in XML format thanks to [gotestsum](https://github.com/gotestyourself/gotestsum)


---
# ingredients 👨‍🍳

- *metadata enabled* test [runner script](https://github.com/os-autoinst/os-autoinst-distri-opensuse/blob/master/data/security/testPolkit/runtest)
- `polkit_test.go` main test program logic
- reusable utility library for process execution
- (optional) a Perl module to run in openQA

---
## The main dish 🍝

### an Array of TestCase

```Go
	testCases := []testCase{
		{"Check polkit rules directory permissions (root:polkitd)", checkPermissions},
		{"Add polkit rule and restart service", addRuleAndRestart},
		{"Change hostname without authentication", changeHostnameWithAuth},
		{"Verify hostname was changed", verifyHostnameChanged},
		{"Remove polkit rule and restart service", removeRuleAndRestart},
		{"Hostname change should fail without authentication", changeHostnameShouldFail},
		{"Verify hostname was not changed", verifyHostnameUnchanged},
	}
```

- Small , testable functions with simple, straightforward logic. 
- You can see the test plan without reading the code.

---
## side dish: Auxiliary libs 🥕 🍅

- **exec helper**:

  run a command in background, reading stdout/stderr and manage timeout

- [gotestsum](https://github.com/gotestyourself/gotestsum) test runner that outputs results in XML format. Used in many big upstream projects (kubernetes, prometheus, telegraf...)

---
# dessert 

- metadata embedded ! 🤖

```yaml
---
test: policykit rules
desc: Verifies functionality of policykit rules
steps:
  - check folder permissions /etc/polkit-1/rules.d/ , bail out if !root:polkitd
  - save original hostname
  - add a permissive polkit rule in /etc/polkit-1/rules.d/ and restart polkit service
  - try to change hostname, should succeed (do not ask root password)
  - ensure hostname has been changed
  - remove polkit rule and restart service
  - try to change hostname, should fail (will ask root password)
  - ensure hostname has NOT been changed
  - restore original hostname
author: <andrea.manzini@suse.com>
maintainer: QE Security <none@suse.de>
expected: no errors raised, user is allowed/denied to change hostname according to the rule
platform: Tumbleweed
tags: security polkit bsc#1249581
```
<!-- footer: "" -->


---
## how do I run it outside of openQA ?

- [start a Tumbleweed vm and access it]
- install packages: `zypper in go git polkit`
- `git clone --depth 1 https://github.com/os-autoinst/os-autoinst-distri-opensuse`
- `cd os-autoinst-distri-opensuse/data/security/testPolkit`
- `sudo ./runtest`

---
### what openQA Perl module does:

- installs `Go` compiler
- download *'data'* files (the real test program)
- creates directories and puts Go libraries in place 
- run actual test with `gotestsum` 
- export results in XML format to openQA, cleanup
- example run : https://openqa.opensuse.org/tests/5404762#step/polkit_rules/27

(see *'external results'*)

---
# 🐪

```Perl
sub run {
    select_serial_terminal;

    my @files = qw(runtest go.mod polkit_test.go utils.go);
    # install go and download test files
    zypper_call 'in go gotestsum';
    assert_script_run 'mkdir -p ~/testPolkit && cd ~/testPolkit';
    my $url = data_url("security/testPolkit/");
    assert_script_run 'curl -s ' . join ' ', map { "-O $url/$_" } @files;

    # run test and generate result file
    assert_script_run("chmod +x ./runtest && ./runtest && mv results.xml /tmp/polkit_rules.xml");

    #cleanup after test
    assert_script_run("cd ~ && rm -rf testPolkit");
    parse_extra_log('XUnit', '/tmp/polkit_rules.xml');
}
```

---
# Pro and cons

✅ strongly typed, catch errors at compile time

✅ can be run independently (e.g. give it to a customer or stakeholder)

✅ compatible with other automated test runners (Jenkins, ArgoCD, Travis CI , Github CI, AWS/Azure ... )

❌ Can't see the test source in openQA webui

❌ Less features than `os-autoinst` (needles ?)

---
# Next steps

- collect feedback, explore the idea adding more tests
- decide files location and project layout
- concurrent/parallel testing ?

---
# Thanks for watching 

## OpenQA-agnostic testing

## [a proposal] v.2

![bg right fit](../img/opensuse-logo-color.svg)

## Andrea Manzini

# ⁉️ Question time! ⁉️ 