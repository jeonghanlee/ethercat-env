# EtherCAT Environment Installation

## Scope

This document describes how the Debian 13 EtherCAT environment is
installed on a host. Two delivery paths exist: the production path
(Debian packages plus Ansible provisioning) and the development path
(the Make wrapper). The production path is authoritative for deployed
hosts; the development path is retained for development and CI.

**Out of scope:** Routine status collection is covered in `docs/operation.md`; rollback and removal are covered in `docs/removal.md`; RT-specific policy is covered in `docs/rt-tuning.md`; live execution acceptance is covered in `docs/field-readiness.md`. The destination map (which capability is a package, a role, or development-only) is `docs/delivery-model.md`.

## One Path Per Host

A host uses the production path or the development path, not both. The
two collide on shared host state:

- Command path: `ethercat-tools` installs `/usr/bin/ethercat` as a
  dpkg-owned file; the wrapper `command.install` creates `/usr/bin/ethercat` as a symlink to `/opt/ethercat/bin/ethercat`.
- Device-access group: the package declares the `ethercat` group through sysusers.d; the wrapper `udev.install` creates it imperatively.

Choose one path before installing. Mixing them leaves an ambiguous
command target and conflicting group ownership.

## Production Path: Packages

The package set is built from the source package `ethercat` (the pinned
upstream revision plus `debian/`). The five binary packages are:

| Package | Role |
| :--- | :--- |
| `ethercat-host` | Host integration: the `ethercat.service` systemd unit, the `99-ethercat.rules` udev rule, the `ethercat` system group (sysusers.d), `/usr/sbin/ethercatctl`, and the reference configuration example. |
| `ethercat-dkms` | Kernel module DKMS source (`ec_master` and the generic device module); rebuilt against the target kernel on every kernel update. |
| `ethercat-tools` | The `ethercat` command-line tool and its bash completion; self-contained. |
| `libethercat1` | Runtime shared library (`libethercat.so.1`) for site application authors; the package set has no in-tree consumer. |
| `libethercat-dev` | Development files (`ecrt.h`, `ectty.h`, the `.so` symlink, the static archive, the pkg-config and CMake metadata) for building applications. |

The packages are installed from a local or site apt repository. They
are built in-tree (the validation harness builds them in phases p13 and
p15); there is no public apt source.

```bash
sudo apt install ethercat-host
```

`ethercat-host` declares `Depends: ethercat-dkms, ethercat-tools`, so a
single install pulls the kernel module source and the command-line
tool. Install `libethercat-dev` additionally only on hosts that build
applications against the realtime application interface.

```bash
sudo apt install libethercat-dev
```

The `ethercat.service` unit is enabled but not started at install time:
starting it requires the live `/etc/ethercat.conf` (the service fails
closed without it) and master hardware. `ethercat-dkms` builds the
kernel modules against the running kernel at install and rebuilds them
on every kernel update.

## Production Path: Provisioning With Ansible

The Ansible layer renders the host-specific configuration and brings
the service up. Two roles compose the host: `rt_host` (real-time host
policy) and `ethercat_master` (EtherCAT master configuration and
service). `ansible/playbooks/site.yml` applies both in order.

Run the playbook from the `ansible/` directory so the relative
`ansible.cfg` resolves (`roles_path=./roles`, `inventory=./inventory`).
The `ethercat_master_device` variable is REQUIRED - the master never
starts unbound (fail-closed) - and the shipped `localhost` inventory
does not set it, so supply it on the command line:

```bash
cd ansible
ansible-playbook playbooks/site.yml -e ethercat_master_device=<iface>
```

The `ethercat_master` role installs `ethercat-host`, renders
`/etc/ethercat.conf` (it is the sole owner of that file), and enables
and starts `ethercat.service`. Device drivers are bare names
(`generic`); `ethercatctl` prepends `ec_` at load time.
`ethercat_master_updown` must be interface names, not a MAC. The
`rt_host` role applies the RT host policy described in
`docs/rt-tuning.md`.

To provision the RT host policy or the EtherCAT master alone, use
`playbooks/rt_host.yml` or `playbooks/ethercat_master.yml`.

## Production Path: Operator Install Without Ansible

A package-only host (no Ansible) configures the master by hand. The
package ships the reference configuration as an example outside `/etc`;
copy it into place, set the device, and start the service:

```bash
sudo cp /usr/share/doc/ethercat-host/examples/ethercat.conf /etc/ethercat.conf
sudoedit /etc/ethercat.conf
sudo systemctl enable --now ethercat.service
```

Set `MASTER0_DEVICE` (and `UPDOWN_INTERFACES`) in the copied file. This
operator step is documented in `ethercat-host.README.Debian`. The unit
runs `ethercatctl start`, which brings the configured UPDOWN interfaces
up at service start and at boot (EC-8). An operator that runs the
`ethercat` tool without root must be a member of the `ethercat`
device-access group; membership takes effect at the next login session.

## Development Path: Make Wrapper

The wrapper installs the same capabilities under the `/opt/ethercat`
prefix with the `epics-ethercat.service` unit. It is retained for
development and CI, not for deployed hosts.

The build path starts with reproducible source verification.

```bash
make init
make build.baseline
```

`make init` clones or updates `ethercat-src` and verifies the pinned
source revision. The clone and submodule paths carry a repository-owned
HTTPS pin (a longest-prefix identity insteadOf), so `make init` stays on
HTTPS even on hosts whose global gitconfig rewrites gitlab.com URLs to
SSH. `make build.baseline` verifies the source revision again, runs
autoconf, builds userspace, and builds kernel modules without installing
them.

The upstream userspace install wrapper is `make build.install`. It is
distinct from the guarded prefix metadata target named `make install`,
which writes the repository-generated version file into the prefix tree
and guards `$(INSTALL_LOCATION)` under `$(INSTALL_PATH)`.

The recorded development kernel module lifecycle is DKMS.

```bash
make dkms.conf
make module.lifecycle
make add.dkms
make install.dkms
```

Runtime configuration is generated to `build/ethercat.conf`, linted,
and installed into the prefix configuration path that the wrapper
`ethercatctl` reads (`/opt/ethercat/etc/ethercat.conf`). The wrapper
never writes `/etc/ethercat.conf`.

```bash
make runtime.generate
make runtime.lint
make runtime.install
```

Integration artifacts use a staging-first model: render targets are
non-root, install targets are root-affecting.

```bash
make systemd.render
make systemd.install
make udev.render
make udev.install
make command.install
make loader.render
make loader.install
```

`udev.install` first creates the device access group (`ethercat` by
default) when absent - udev resolves `GROUP` names at rule load time, so
the group must exist before the reload - then copies the rendered udev
rule and reloads rules. After installation and review, service
enablement and start are explicit.

```bash
make systemd.enable
make systemd.start
```

## Install Verification

On the development path, read-only targets confirm the resulting state.

```bash
make runtime.status
make rt.status
make remove.audit
```

`remove.audit` reports remaining installed state as residue by design;
immediately after install, residue is expected because the host is
intentionally configured. On the production path, confirm install state
with `systemctl status ethercat.service`, `dkms status`, and
`ethercat master`; see `docs/operation.md`.
