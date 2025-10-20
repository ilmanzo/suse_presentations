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
# ingredients

- *metadata enabled* test [runner script](https://github.com/os-autoinst/os-autoinst-distri-opensuse/blob/master/data/security/testPolkit/runtest)
- `testPolkit.go` main test program logic
- reusable utility libraries for
  - process execution
  - output format
- (optional) a Perl module to run in openQA

---
## The main dish 

### an Array of TestCase

```Go
	testCases := map[int]tap.TestCase{
		1: {"Save original hostname", nil},
		2: {"Check polkit rules directory permissions (root:polkitd)", checkPermissions},
		3: {"Add polkit rule and restart service", addRuleAndRestart},
		4: {"Change hostname without authentication", changeHostnameWithAuth},
		5: {"Verify hostname was changed", verifyHostnameChanged},
		6: {"Remove polkit rule and restart service", removeRuleAndRestart},
		7: {"Hostname change should fail without authentication", changeHostnameShouldFail},
		8: {"Verify hostname was not changed", verifyHostnameUnchanged},
		9: {"Restore original hostname", nil},
	}
```

Simple, straightforward logic. You can see the test plan without reading the code.

---
## side dish: Auxiliary libs

- **TAP** (Test Anything Protocol) runner and formatter:

  receives an array of tests and run it, properly formatting the output 

- **exec helper**:

  run a command in background, reading stdout/stderr and manage timeout

---
# dessert 

- metadata included ! 

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
expected: no errors raised, connection succeed
platform: Tumbleweed
tags: security polkit bsc#1249581
```
<!-- footer: "" -->


---
## how I run it outside of openQA ?

- [start a Tumbleweed vm and access it]
- install packages: `zypper in go git polkit`
- `git clone --depth 1 https://github.com/os-autoinst/os-autoinst-distri-opensuse`
- `cd os-autoinst-distri-opensuse/data/security/testPolkit`
- `sudo ./runtest`
- `cat testPolkit.tap`



---
### openQA perl module

- installs Go compiler
- download 'data' files (the real test program)
- creates directories and puts libraries in place 
- run test
- export results in TAP format to openQA

---
###

```Perl
sub run {
    select_serial_terminal;

    # install go and download test files
    zypper_call 'in go';
    my @files = qw(runtest go.mod main.go utils/utils.go tap/tap.go);
    assert_script_run("mkdir -p ~/testPolkit && cd ~/testPolkit");
    foreach my $file (@files) {
        assert_script_run "curl -O -v --create-dirs " . data_url("security/testPolkit/$file");
    }
    assert_script_run 'mkdir utils tap && mv utils.go utils/ && mv tap.go tap/';

    # run test and generate result file
    assert_script_run("chmod +x ./runtest && ./runtest && mv results.tap /tmp");

    #cleanup after test
    assert_script_run("cd ~ && rm -rf testPolkit");
    parse_extra_log('TAP', '/tmp/results.tap');
}
```


---
# OpenQA-agnostic testing

## [an introduction]

![bg left fit](../img/opensuse-logo-color.svg)

### Andrea Manzini
