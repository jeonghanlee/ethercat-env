# EtherCAT Environment Operation

## Scope

This document describes normal read-only inspection and operator-facing
actions after the host has been installed. It covers both delivery
paths: the production path (packages plus Ansible) and the development
path (the Make wrapper).

**Out of scope:** Installation steps are covered in `docs/install.md`; removal and rollback are covered in `docs/removal.md`; RT policy details are covered in `docs/rt-tuning.md`; acceptance gates are covered in `docs/field-readiness.md`.

## Production Path: Service And State

On a packaged host the EtherCAT master runs as `ethercat.service`
(a oneshot unit that calls `ethercatctl start`, `stop`, and `restart`).
Inspect and control it through systemd.

```bash
systemctl status ethercat.service
sudo systemctl restart ethercat.service
```

The master and bus state are read through the `ethercat` command-line
tool. An operator in the `ethercat` device-access group runs it without
root.

```bash
ethercat master
ethercat slaves
```

Kernel module state is read through DKMS and the kernel.

```bash
dkms status
lsmod | grep ec_
```

The live configuration is `/etc/ethercat.conf`. On an Ansible-managed
host it is rendered by the `ethercat_master` role and must be changed
through the role, not edited in place; on a package-only host it is the
operator-owned file created during install (`docs/install.md`).

## Production Path: RT Host State

The real-time host policy applied by the `rt_host` role is reported by
the same `rt.status` oracle the wrapper uses (run from a checkout of
this repository), and by the underlying system tools.

```bash
systemctl status
chrt -p 1
cat /sys/devices/system/clocksource/clocksource0/current_clocksource
```

RT policy mechanics and the variable model are in `docs/rt-tuning.md`.

## Development Path: Read-Only Status Set

The wrapper splits operation into read-only inspection targets and
root-affecting targets. Read-only targets are safe for routine status
collection on a development host; they report on the `/opt/ethercat`
prefix and the `epics-ethercat.service` unit, not the packaged layout.

| Purpose | Read-only targets | Root-affecting targets |
| :--- | :--- | :--- |
| Host and tool readiness | `doctor`, scoped `doctor.*` targets | none |
| Source and build state | `src.revision`, `host.debian13`, `module.lifecycle` | none |
| Profile and patches | `profile.matrix`, `patch.status` | `patch.apply`, `patch.reverse` |
| Runtime configuration | `runtime.config.show`, `runtime.status`, `iface.status` | `iface.prepare`, `iface.unprepare` |
| RT host state | `rt.kernel.select`, `rt.status`, `rt.clock.status`, `rt.limits.audit`, `rt.service.audit`, `rt.tuned.status` | `rt.kernel.provision`, `rt.limits.install`, `rt.grub.apply`, `rt.grub.rollback`, `rt.service.apply`, `rt.priority.apply` |
| Removal state | `remove.audit`, `remove.dryrun` | `remove.stop`, `remove.disable`, `remove.uninstall`, `remove.rt`, `remove.purge` |

Use the following targets to collect a development-host snapshot without
intentionally mutating host state.

```bash
make host.debian13
make profile.matrix
make src.revision
make module.lifecycle
make runtime.status
make rt.status
make remove.audit
```

`runtime.status` reports the wrapper host integration state: userspace
command discovery, `/usr/bin/ethercat` link state, loader fragment,
systemd unit state, udev rule, loaded master module, configured master
devices, and selected device modules. `rt.status` consolidates RT kernel
selection visibility, GRUB parameter audit, clock source status,
realtime limits, service policy, and tuned profile state. Neither proves
post-reboot operation; that remains an external gate.

## Development Path: Runtime And Service Targets

The wrapper runtime configuration is generated from tracked inputs and
written under `build/`.

```bash
make runtime.generate
make runtime.lint
make runtime.config.show
```

The configured EtherCAT master interface comes from `ETHERCAT_MASTER0`
in `configure/ethercatmaster.conf`. `iface.status` reports the resolved
interface and link state without changing it; `iface.prepare` and
`iface.unprepare` are root-affecting link-state controls that depend on
`doctor.network`, assert root, and fail closed on an empty interface.

The development service unit is `epics-ethercat.service`. Lifecycle
targets are split by action.

```bash
make systemd.enable
make systemd.start
make systemd.stop
make systemd.disable
```

## Verification Targets

The repository-local verification harness is shared by both paths and
run from a checkout. It checks reproducibility, dry-run guard coverage,
dry-run idempotence, doctor override failure behavior, residue
reporting, package build, lintian, ansible-lint, and a playbook
syntax-check.

```bash
make verify.all
```

The harness does not install software, load modules, edit GRUB, restart
services, or prove hardware behavior; SKIP-gated members run for real
only on the VM (`docs/field-readiness.md`).
