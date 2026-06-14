# Changelog

## 1.0.0 — Delivery Model Release

First release of the successor delivery model: the EtherCAT master and
real-time host environment delivered as Debian packages plus Ansible
roles, alongside the retained development Make wrapper.

### Packaging

- Debian source package `ethercat` built from the pinned upstream
  revision (#2).
- `ethercat-dkms`: kernel modules via DKMS, rebuilt on kernel update,
  cross-kernel vermagic verified (#3).
- Userspace split into `libethercat1`, `libethercat-dev`, and the
  self-contained `ethercat-tools` CLI (#4).
- `ethercat-host`: systemd unit, udev rule, the `ethercat` group via
  sysusers.d, and a fail-closed service; no `/etc/ethercat.conf` shipped
  (#5).

### Provisioning

- `rt_host` Ansible role: RT kernel, limits, GRUB parameters, clock,
  service policy, and tuned, at parity with `rt.status` (#6).
- `ethercat_master` Ansible role with `site.yml`: installs the packages,
  renders `/etc/ethercat.conf` with a bound device, and starts the
  service (#7).

### Verification and documentation

- `verify.all` umbrella extended with lintian, ansible-lint, and a
  playbook syntax-check (#8).
- VM acceptance: the package/Ansible path reaches outcome parity with
  the source-build path on a fresh Debian 13 VM, post-reboot included
  (#9).
- System documentation refreshed to the two-path delivery model (#10).

### Fixes

- Pin the upstream clone to HTTPS against a global insteadOf rewrite
  (#11).

### Notes

- The `1.0.0` tag is the repository release; the Debian package version
  (`1.6.9+...`) tracks the pinned upstream and diverges across releases.
- Hardware acceptance (real adapter, slave chain, reboot persistence)
  remains an external gate beyond 1.0.0.
