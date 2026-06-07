# EtherCAT Environment Removal And Rollback

## Scope

This document describes removal, rollback, residue reporting, and the safety contract for destructive targets.

**Out of scope:** Installation is covered in `docs/install.md`; normal status collection is covered in `docs/operation.md`; RT policy details are covered in `docs/rt-tuning.md`; live acceptance is covered in `docs/field-readiness.md`.

## Removal Model

Removal is modeled as an ordered graph rather than a single destructive command. The core sequence is stop, disable, uninstall files and integration artifacts, optionally revert RT host policy, optionally purge residual configuration, then audit.

```bash
make remove.dryrun
make remove.stop
make remove.disable
make remove.uninstall
make remove.rt
make remove.purge
make remove.audit
```

`remove.dryrun` previews the sequence using `make --dry-run` and does not intentionally mutate host state. `remove.audit` is read-only and reports residue with a parseable verdict.

## EtherCAT Removal

`remove.stop` delegates to `sd_stop`, which stops the configured systemd unit only if it is active. `remove.disable` delegates to `sd_disable`, which disables the unit only if it is enabled.

`remove.uninstall` removes installed files, the systemd unit, the udev rule, the command path, and the loader fragment. It delegates file-level cleanup to guarded targets and removes `/usr/bin/ethercat` and `/etc/ld.so.conf.d/ethercat.conf` through guarded paths.

The prefix-tree removal path is `src_uninstall`. It depends on the systemd cleanup targets and removes `$(INSTALL_LOCATION)` after `guard-path` validates that the path remains under `$(INSTALL_PATH)`.

## RT Policy Removal

`remove.rt` reverts the repository-managed RT policy elements.

| State | Removal behavior |
| :--- | :--- |
| GRUB defaults | Restore from the repository-managed backup when present; report absent backup separately. |
| RT limits policy | Remove the configured limits.d policy file. |
| Service allowlist | Unmask each service named in `RT_SERVICE_ALLOWLIST`. |

The RT kernel package itself is treated as an operator-managed package state. `remove.audit` reports it if still installed, but package removal is not folded into the destructive repository target graph.

## Purge Behavior

`remove.purge` runs uninstall and RT removal first, then removes additional state such as the realtime group and remaining GRUB backup file. It remains guarded and root-affecting.

Use `remove.purge` only when the host should no longer carry the repository-managed EtherCAT or RT policy state.

## Residue Report

`remove.audit` checks the prefix tree, systemd unit, udev rule, command path, loader fragment, RT limits file, GRUB backup, RT GRUB parameters, RT kernel package, and masked service allowlist.

The final line is `VERDICT=clean` or `VERDICT=residue`. The verification harness consumes this verdict through `verify.residue`.

## Safety Contract

Destructive targets use the same host mutation contract as install targets: scoped doctor prerequisites, `require-root` before mutation, `$(SUDO)` for host changes, and `guard-path` for file removals under controlled prefixes or exact paths.

No removal target should be treated as hardware validation. VM and hardware acceptance must still prove that removal leaves the host in the expected operational state.
