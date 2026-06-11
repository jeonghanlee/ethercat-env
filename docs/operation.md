# EtherCAT Environment Operation

## Scope

This document describes normal read-only inspection and operator-facing target groups after the repository has been checked out on a Debian 13 host.

**Out of scope:** Installation steps are covered in `docs/install.md`; removal and rollback are covered in `docs/removal.md`; RT policy details are covered in `docs/rt-tuning.md`; acceptance gates are covered in `docs/field-readiness.md`.

## Operating Model

Operation is split into read-only inspection targets and root-affecting targets. Read-only targets are safe to use for routine status collection. Root-affecting targets change host state and are intentionally separated by phase.

| Purpose | Read-only targets | Root-affecting targets |
| :--- | :--- | :--- |
| Host and tool readiness | `doctor`, scoped `doctor.*` targets | none |
| Source and build state | `src.revision`, `host.debian13`, `module.lifecycle` | none |
| Profile and patches | `profile.matrix`, `patch.status` | `patch.apply`, `patch.reverse` |
| Runtime configuration | `runtime.config.show`, `runtime.status`, `iface.status` | `iface.prepare`, `iface.unprepare` |
| RT host state | `rt.kernel.select`, `rt.status`, `rt.clock.status`, `rt.limits.audit`, `rt.service.audit`, `rt.tuned.status` | `rt.kernel.provision`, `rt.limits.install`, `rt.grub.apply`, `rt.grub.rollback`, `rt.service.apply`, `rt.priority.apply` |
| Removal state | `remove.audit`, `remove.dryrun` | `remove.stop`, `remove.disable`, `remove.uninstall`, `remove.rt`, `remove.purge` |

## Standard Read-Only Status Set

Use the following targets to collect a host snapshot without intentionally mutating host state.

```bash
make host.debian13
make profile.matrix
make src.revision
make module.lifecycle
make runtime.status
make rt.status
make remove.audit
```

`runtime.status` reports the EtherCAT host integration state independently: userspace command discovery, `/usr/bin/ethercat` link state, loader fragment, systemd unit state, udev rule, loaded master module, configured master devices, and selected device modules.

`rt.status` consolidates RT kernel selection visibility, GRUB parameter audit, clock source status, realtime limits, service policy, and tuned profile state. It does not prove post-reboot operation; that remains an external gate.

## Runtime Configuration Generation

The runtime configuration is generated from tracked inputs and written under `build/`.

```bash
make runtime.generate
make runtime.lint
make runtime.config.show
```

`runtime.generate` renders `templates/ethercat.conf.in` using `configure/ethercatmaster.conf` and the selected device profile. `runtime.lint` verifies required keys and a non-empty master device. `runtime.config.show` prints the generated artifact for review.

## Interface State

The configured EtherCAT master interface comes from `ETHERCAT_MASTER0` in `configure/ethercatmaster.conf`. `iface.status` reports the resolved interface and current link state without changing it.

`iface.prepare` and `iface.unprepare` are root-affecting link-state controls for the selected interface. They depend on `doctor.network`, assert root, fail closed on an empty interface, and execute `ip link set` through `$(SUDO)`.

## Service Operation

The systemd unit is `epics-ethercat.service` by default. It calls `ethercatctl start`, `ethercatctl stop`, and `ethercatctl restart` through the configured prefix-tree path.

Service lifecycle targets are split by action.

```bash
make systemd.enable
make systemd.start
make systemd.stop
make systemd.disable
```

These targets are root-affecting. The read-only view for service state is `runtime.status`.

## Verification Targets

The verification harness is repository-local. It checks reproducibility, dry-run guard coverage, dry-run idempotence, doctor override failure behavior, and residue reporting.

```bash
make verify.all
```

The harness does not install software, load modules, edit GRUB, restart services, or prove hardware behavior.
