# EtherCAT Environment Architecture

## Scope

This document describes the structure, ownership boundaries, and data flow of the Debian 13 EtherCAT and real-time host environment.

**Out of scope:** Step-by-step operation is covered in `docs/operation.md`; install and removal sequences are covered in `docs/install.md` and `docs/removal.md`; live VM and hardware acceptance is covered in `docs/field-readiness.md`.

## System Boundary

This repository owns the Debian 13 host configuration required to run the EtherLab IgH EtherCAT master with a site-controlled real-time host profile. It does not own application-level EtherCAT process data mapping, EPICS IOC database content, or device-specific control logic above host readiness.

The system is organized around four layers.

| Layer | Repository responsibility | Primary files |
| :--- | :--- | :--- |
| Source and build | Acquire the upstream EtherCAT source, verify the pinned revision, configure userspace, and build userspace plus kernel modules. | `configure/RULES_SRC`, `configure/RULES_ETHERCAT`, `configure/RELEASE` |
| Host integration | Render and install systemd, udev, command-path, loader, and runtime configuration artifacts. | `configure/RULES_RUNTIME`, `configure/RULES_SYSTEMD`, `templates/` |
| Real-time host policy | Provision and report Debian 13 RT kernel, limits, GRUB parameters, clock source, service policy, tuned status, and priority diagnostics. | `configure/CONFIG_RT`, `configure/RULES_RT`, `configure/RULES_RTDIAG` |
| Safety and verification | Fail closed before host mutation and prove target graph coverage through dry-run and read-only checks. | `configure/RULES_DOCTOR`, `configure/RULES_REMOVE`, `configure/RULES_VERIFY` |

## Makefile Model

The top-level `Makefile` includes `configure/CONFIG` for variable surfaces and `configure/RULES` for target definitions. The `configure/RULES` aggregator preserves a phase-oriented order: common functions, doctor checks, profile checks, patch handling, source acquisition, build, runtime generation, system integration, RT policy, diagnostics, install, removal, dry-run helpers, verification, and variable inspection.

Configuration values are overridable through `.local` files where the owning `CONFIG_*` or `RULES_*` file provides an include hook. The tracked defaults are Debian 13 oriented and keep the default EtherCAT device profile generic-only.

## Build Data Flow

The source flow starts from `configure/RELEASE`, which names the upstream source repository, branch, and pinned observed revision. `make init` clones or updates `ethercat-src` and finishes with `src.verify`, so an upstream branch movement fails before the build baseline is treated as reproducible.

`build.baseline` runs the repository-local baseline sequence: `src.verify`, `autoconf`, `build`, and `build.modules`. The upstream build install wrapper remains available as `build.install`, separate from the guarded prefix metadata install target named `install`.

## Runtime Data Flow

Runtime configuration is generated, not edited in place. `configure/ethercatmaster.conf` supplies `ETHERCAT_MASTER0`, the selected `WITH_DEV_*` profile variables supply module names, and `templates/ethercat.conf.in` renders to `build/ethercat.conf` through `runtime.generate`.

The generated runtime configuration is validated by `runtime.lint` and displayed by `runtime.config.show`. The current implementation deliberately keeps generation repository-local; live installation and service behavior are validated later through VM and hardware gates.

## Host Integration Data Flow

System integration uses a staging-first model. Templates under `templates/` render into `build/systemd`, and only install targets copy staged artifacts into system locations.

| Artifact | Template or source | Staged path | Installed path |
| :--- | :--- | :--- | :--- |
| systemd unit | `templates/epics-ethercat.service.in` | `build/systemd/epics-ethercat.service` | `/etc/systemd/system/epics-ethercat.service` |
| udev rule | `templates/99-EtherCAT.rules.in` | `build/systemd/99-EtherCAT.rules` | `/etc/udev/rules.d/99-EtherCAT.rules` |
| loader fragment | `LOADER_LIBDIR` from `configure/CONFIG_SITE` | `build/systemd/ethercat.conf` | `/etc/ld.so.conf.d/ethercat.conf` |
| command path | `COMMAND_TARGET` from `configure/CONFIG_SITE` | none | `/usr/bin/ethercat` symlink |

`runtime.status` is the consolidated read-only host view for userspace tool exposure, command link, loader fragment, service state, udev rule, loaded `ec_master` module, configured master device, and selected device modules.

## Safety Contract

Root-affecting targets follow the same safety shape: a scoped `doctor.*` prerequisite verifies required tools, `require-root` runs before mutation, host changes route through `$(SUDO)`, and file writes or removals under controlled prefixes use `guard-path`.

Read-only and repository-local targets do not use root guards. Examples include `runtime.generate`, `runtime.lint`, `runtime.status`, `rt.status`, `remove.audit`, and the `verify.*` checks.

## External Gates

Repository-local verification proves target graph structure, guard presence, idempotent dry-runs, and read-only status behavior. VM execution, hardware adapter discovery, slave-chain operation, reboot persistence, kernel update rebuild behavior, and production approval are external gates tracked in `docs/milestone.md`.
