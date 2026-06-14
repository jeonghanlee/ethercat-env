# EtherCAT Environment Removal And Rollback

## Scope

This document describes removal, rollback, residue reporting, and the
safety contract for destructive actions on both delivery paths: the
production path (Debian packages) and the development path (the Make
wrapper).

**Out of scope:** Installation is covered in `docs/install.md`; normal status collection is covered in `docs/operation.md`; RT policy details are covered in `docs/rt-tuning.md`; live acceptance is covered in `docs/field-readiness.md`.

## Production Path: Package Removal

Remove the package set with apt. Purge removes the packages and their
package-owned configuration.

```bash
sudo apt purge ethercat-host ethercat-tools ethercat-dkms libethercat1 libethercat-dev
```

`apt purge ethercat-host` alone leaves `ethercat-dkms` and
`ethercat-tools` installed (they are dependencies, not reverse
dependencies); name the full set, or follow with `apt autoremove`, to
remove everything.

Two pieces of host state are deliberately not removed by purge, and
neither is residue:

- `/etc/ethercat.conf` - the package never ships or owns this file (U3).
  The upstream default is moved into the reference example at
  `/usr/share/doc/ethercat-host/examples/ethercat.conf` during the build,
  and the live file is role-rendered or operator-created state. Purge
  does not touch it. Remove it by hand if the host should no longer carry
  the configuration.
- The `ethercat` system group - declared through sysusers.d (U4). System
  groups are retained on purge per Debian convention (GID-reuse hazard).
  Audits report it as a note, not residue.

## Development Path: Wrapper Removal Model

The wrapper models removal as an ordered graph rather than a single
destructive command, operating on the `/opt/ethercat` prefix and the
`epics-ethercat.service` unit. The core sequence is stop, disable,
uninstall files and integration artifacts, optionally revert RT host
policy, optionally purge residual configuration, then audit.

```bash
make remove.dryrun
make remove.stop
make remove.disable
make remove.uninstall
make remove.rt
make remove.purge
make remove.audit
```

`remove.dryrun` previews the sequence using `make --dry-run` and does
not intentionally mutate host state. `remove.audit` is read-only and
reports residue with a parseable verdict.

`remove.stop` and `remove.disable` act on the configured unit only when
it is active or enabled. `remove.uninstall` removes installed files, the
systemd unit, the udev rule, the command path (`/usr/bin/ethercat`), and
the loader fragment through guarded paths; the prefix-tree removal path
`src_uninstall` removes `$(INSTALL_LOCATION)` after `guard-path`
validates that it remains under `$(INSTALL_PATH)`.

## RT Policy Removal (Development Path)

`remove.rt` reverts the repository-managed RT policy elements.

| State | Removal behavior |
| :--- | :--- |
| GRUB defaults | Restore from the repository-managed backup when present; report absent backup separately. |
| RT limits policy | Remove the configured limits.d policy file. |
| Service allowlist | Unmask each service named in `RT_SERVICE_ALLOWLIST`. |

The RT kernel package itself is operator-managed package state.
`remove.audit` reports it as a note if still installed, without counting
it as residue; package removal is not folded into the destructive
repository target graph.

`remove.purge` runs uninstall and RT removal first, then removes
additional state: the realtime group, the EtherCAT device access group
created by `udev.install`, and the remaining GRUB backup file. It remains
guarded and root-affecting.

## Residue Report (Development Path)

`remove.audit` checks the prefix tree, systemd unit, udev rule, command
path, loader fragment, RT limits file, realtime and device access
groups, GRUB backup, RT GRUB parameters, RT kernel package, and masked
service allowlist. The final line is `VERDICT=clean` or
`VERDICT=residue`; the verification harness consumes this verdict
through `verify.residue`. On the package path the same residue audit
runs inline during the validation harness purge phase and ends clean,
with the retained `ethercat` group reported as a note (U4).

## Safety Contract

Wrapper destructive targets use the same host mutation contract as
install targets: scoped doctor prerequisites, `require-root` before
mutation, `$(SUDO)` for host changes, and `guard-path` for file removals
under controlled prefixes or exact paths. The package path relies on
dpkg maintainer scripts for the equivalent guarantees.

No removal action is hardware validation. VM and hardware acceptance
must still prove that removal leaves the host in the expected
operational state (`docs/field-readiness.md`).
