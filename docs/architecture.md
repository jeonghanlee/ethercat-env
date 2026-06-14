# EtherCAT Environment Architecture

## Scope

This document describes the structure, ownership boundaries, and data
flow of the Debian 13 EtherCAT and real-time host environment. It covers
the two delivery vehicles - the production package and role set, and the
development Make wrapper - and the capability model they share.

**Out of scope:** Step-by-step operation is covered in `docs/operation.md`; install and removal sequences are covered in `docs/install.md` and `docs/removal.md`; live VM and hardware acceptance is covered in `docs/field-readiness.md`. The authoritative capability-to-destination map is `docs/delivery-model.md`.

## System Boundary

This repository owns the Debian 13 host configuration required to run
the EtherLab IgH EtherCAT master with a site-controlled real-time host
profile. It does not own application-level EtherCAT process data
mapping, EPICS IOC database content, or device-specific control logic
above host readiness.

## Delivery Structure

The production vehicle is a Debian package set plus an Ansible role set.
The development vehicle is the Make wrapper. Both deliver the same
capability model (`docs/delivery-model.md` carries the per-capability
destination map and acceptance criteria).

| Package | Responsibility |
| :--- | :--- |
| `ethercat-host` | Host integration: `ethercat.service`, the `99-ethercat.rules` udev rule, the `ethercat` group (sysusers.d), `ethercatctl`, and the reference configuration example. `Depends: ethercat-dkms, ethercat-tools`. |
| `ethercat-dkms` | Kernel module DKMS source (`ec_master` and the generic device module); rebuilt on kernel update. |
| `ethercat-tools` | The `ethercat` command-line tool and bash completion; self-contained. |
| `libethercat1` | Runtime shared library (`libethercat.so.1`) for application authors; no in-tree consumer. |
| `libethercat-dev` | Development files for building against the realtime application interface. |

| Role | Responsibility |
| :--- | :--- |
| `rt_host` | Real-time host policy (kernel, limits, GRUB, clock, service, tuned), variables `rt_host_*`, agreeing with the `rt.status` oracle. |
| `ethercat_master` | EtherCAT master configuration and service: installs `ethercat-host`, renders `/etc/ethercat.conf` (sole owner), starts `ethercat.service`, variables `ethercat_master_*`. |

`ansible/playbooks/site.yml` composes `rt_host` then `ethercat_master`
into a complete real-time EtherCAT master host.

## Capability Layers

Both vehicles are organized around four capability layers; the file
references below are the development wrapper implementation, which the
package set and roles mirror.

| Layer | Repository responsibility | Primary files |
| :--- | :--- | :--- |
| Source and build | Acquire the upstream EtherCAT source, verify the pinned revision, configure userspace, and build userspace plus kernel modules. | `configure/RULES_SRC`, `configure/RULES_ETHERCAT`, `configure/RELEASE`, `debian/rules`, `debian/ethercat-dkms.dkms` |
| Host integration | Render and install systemd, udev, command-path, loader, and runtime configuration artifacts. | `configure/RULES_RUNTIME`, `configure/RULES_SYSTEMD`, `templates/`, `debian/ethercat-host.*` |
| Real-time host policy | Provision and report Debian 13 RT kernel, limits, GRUB parameters, clock source, service policy, tuned status, and priority diagnostics. | `configure/CONFIG_RT`, `configure/RULES_RT`, `configure/RULES_RTDIAG`, `ansible/roles/rt_host` |
| Safety and verification | Fail closed before host mutation and prove target graph coverage through dry-run and read-only checks. | `configure/RULES_DOCTOR`, `configure/RULES_REMOVE`, `configure/RULES_VERIFY` |

## Development Wrapper Model

The top-level `Makefile` includes `configure/CONFIG` for variable
surfaces and `configure/RULES` for target definitions. The
`configure/RULES` aggregator preserves a phase-oriented order: common
functions, doctor checks, profile checks, patch handling, source
acquisition, build, runtime generation, system integration, RT policy,
diagnostics, install, removal, dry-run helpers, verification, and
variable inspection.

Configuration values are overridable through `.local` files where the
owning `CONFIG_*` or `RULES_*` file provides an include hook. The
tracked defaults are Debian 13 oriented and keep the default EtherCAT
device profile generic-only. The wrapper installs under the
`/opt/ethercat` prefix with the `epics-ethercat.service` unit; the
package set installs into the system layout with `ethercat.service` (see
`docs/install.md` for the do-not-mix caveat).

## Build Data Flow

The source flow starts from `configure/RELEASE`, which names the
upstream source repository, branch, and pinned observed revision.
`make init` clones or updates `ethercat-src` and finishes with
`src.verify`, so an upstream branch movement fails before the build
baseline is treated as reproducible. `build.baseline` runs the
repository-local baseline sequence: `src.verify`, `autoconf`, `build`,
and `build.modules`.

On the production vehicle the same source becomes the `ethercat` source
package: `debian/rules` builds userspace only (`--disable-kernel`), and
`ethercat-dkms` ships the kernel module source that DKMS rebuilds on the
target host.

## Runtime Data Flow

Runtime configuration is generated, not edited in place. On the wrapper,
`configure/ethercatmaster.conf` supplies `ETHERCAT_MASTER0`, the
selected `WITH_DEV_*` profile variables supply module names, and
`templates/ethercat.conf.in` renders to `build/ethercat.conf` through
`runtime.generate`, validated by `runtime.lint`.

On the production vehicle the `ethercat_master` role is the sole owner
of `/etc/ethercat.conf` and renders it from `ethercat_master_*`
variables; the package ships no `/etc/ethercat.conf` (U3) and the unit
fails closed when it is absent. The two renderers (the wrapper `.in`
template and the role `.j2` template) produce the same configuration
shape.

## Host Integration Data Flow

System integration uses a staging-first model on the wrapper. Templates
under `templates/` render into `build/systemd`, and only install targets
copy staged artifacts into system locations.

| Artifact | Wrapper installed path | Package installed path |
| :--- | :--- | :--- |
| systemd unit | `/etc/systemd/system/epics-ethercat.service` | `ethercat.service` (dh_installsystemd, enabled not started) |
| udev rule | `/etc/udev/rules.d/99-EtherCAT.rules` | `99-ethercat.rules` (dh_installudev, priority 99) |
| loader fragment | `/etc/ld.so.conf.d/ethercat.conf` | not needed (`ethercat-tools` is self-contained; `libethercat1` uses the multiarch path) |
| command path | `/usr/bin/ethercat` symlink | `/usr/bin/ethercat` (dpkg-owned, `ethercat-tools`) |
| device-access group | created by `udev.install` | `ethercat` group via sysusers.d (`ethercat-host`) |

`runtime.status` is the consolidated read-only host view on the wrapper;
on the production vehicle, host state is read through
`systemctl status ethercat.service`, `dkms status`, and `ethercat
master` (`docs/operation.md`).

## Safety Contract

Wrapper root-affecting targets follow the same safety shape: a scoped
`doctor.*` prerequisite verifies required tools, `require-root` runs
before mutation, host changes route through `$(SUDO)`, and file writes
or removals under controlled prefixes use `guard-path`. The package path
relies on dpkg maintainer scripts and `Rules-Requires-Root: no` for the
equivalent guarantees. Read-only and repository-local targets do not use
root guards.

## External Gates

Repository-local verification proves target graph structure, guard
presence, idempotent dry-runs, and read-only status behavior. VM
execution is covered by both acceptance vehicles (source-build and
package/Ansible) at outcome parity; hardware adapter discovery,
slave-chain operation, reboot persistence, kernel update rebuild
behavior, and production approval are external gates tracked in
`docs/milestone.md` and `docs/field-readiness.md`.
