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

## [an introduction]

![bg left fit](../img/opensuse-logo-color.svg)

### Andrea Manzini

---

- https://github.com/os-autoinst/os-autoinst-distri-opensuse/tree/master/data/security/testPolkit

![bg right fit](../img/torvalds_quote.png)

---
# components

- metadata - enabled test [runner script](https://github.com/os-autoinst/os-autoinst-distri-opensuse/blob/master/data/security/testPolkit/runtest)
- main.go test scenario
- reusable utility libraries for
  - process execution
  - output format
- perl module to run in openQA

---
### Array of TestCase

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

---
### openQA perl module

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
## running out of openQA ?

- start a Tumbleweed vm and access it
- `zypper in go git polkit`
- `git clone --depth 1 https://github.com/os-autoinst/os-autoinst-distri-opensuse`
- `cd os-autoinst-distri-opensuse/data/security/testPolkit`
- `./runtest`



---
# OpenQA-agnostic testing

## [an introduction]

![bg left fit](../img/opensuse-logo-color.svg)

### Andrea Manzini
