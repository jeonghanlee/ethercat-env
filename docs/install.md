# EtherCAT Environment Installation

## Scope

This document describes the installation target graph and host state written by the Debian 13 EtherCAT environment.

**Out of scope:** Routine status collection is covered in `docs/operation.md`; rollback and removal are covered in `docs/removal.md`; RT-specific policy is covered in `docs/rt-tuning.md`; live execution acceptance is covered in `docs/field-readiness.md`.

## Installation Boundary

Installation is not a single monolithic target. Build, prefix metadata installation, kernel module lifecycle, runtime configuration staging, systemd, udev, command-path exposure, loader integration, and RT policy are separate targets so each step can be inspected and validated independently.

The default prefix is `/opt/ethercat`. The default command path is `/usr/bin/ethercat`, pointing to `/opt/ethercat/bin/ethercat`. The default service unit is `/etc/systemd/system/epics-ethercat.service`.

## Build And Source Preparation

The build path starts with reproducible source verification.

```bash
make init
make build.baseline
```

`make init` clones or updates `ethercat-src` and verifies the pinned source revision. `make build.baseline` verifies the source revision again, runs autoconf, builds userspace, and builds kernel modules without installing them.

The upstream userspace install wrapper is `make build.install`. It is distinct from the guarded prefix metadata target named `make install`. VM validation must confirm the live behavior of this upstream install path before hardware validation.

## Kernel Module Lifecycle

The recorded production lifecycle is DKMS. `dkms.conf` is generated into the upstream source tree from tracked module identity and selected device modules.

```bash
make dkms.conf
make module.lifecycle
```

The root-affecting DKMS targets are separate.

```bash
make add.dkms
make install.dkms
```

Direct `build.modules` and `install.modules` remain available as the developer path, not the recorded production lifecycle.

## Prefix Metadata Install

The `install` target currently delegates to `src_install`. It writes the repository-generated version file into the prefix tree and sets ownership on `$(INSTALL_LOCATION)`.

```bash
make install
```

`src_install` depends on `doctor.install`, asserts root, and guards `$(INSTALL_LOCATION)` under `$(INSTALL_PATH)`. It does not perform the upstream userspace build install; that remains `build.install`.

## Runtime Configuration Staging

Runtime configuration is generated to `build/ethercat.conf`.

```bash
make runtime.generate
make runtime.lint
```

The generated file contains the master interface, optional backup interface, selected device modules, and interface up/down list. This repository stage does not write `/etc/ethercat.conf` directly.

## systemd, udev, Command, And Loader Integration

Integration artifacts use a staging-first model. Render targets are non-root, and install targets are root-affecting.

```bash
make systemd.render
make systemd.install
make udev.render
make udev.install
make command.install
make loader.render
make loader.install
```

`systemd.install` copies the rendered unit to the system unit directory and reloads systemd. `udev.install` copies the rendered udev rule and reloads rules. `command.install` creates the command symlink. `loader.install` installs the loader fragment and runs `ldconfig`.

## Start And Enable

After installation and review, service enablement and start are explicit.

```bash
make systemd.enable
make systemd.start
```

These targets are root-affecting and operate on the configured systemd unit only.

## Install Verification

Use read-only targets to confirm the resulting state.

```bash
make runtime.status
make rt.status
make remove.audit
```

`remove.audit` reports remaining installed state as residue by design; immediately after install, residue is expected because the host is intentionally configured.
