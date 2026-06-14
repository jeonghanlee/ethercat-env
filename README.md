# EtherCAT Master Configuration Environment

Configuration environment for the EtherLab IgH EtherCAT Master
(https://gitlab.com/etherlab.org/ethercat) on Debian 13.

## History

The long history behind this repository is
https://github.com/jeonghanlee/etherlabmaster. Most of the options are
identical, but the old repository was redesigned to finish the same
jobs. Only **Debian** is the supported platform.

## Delivery Model

The environment delivers the same capability through two paths; a host
uses one path, not both (they collide on `/usr/bin/ethercat` and the
`ethercat` group). The capability-to-destination map is
`docs/delivery-model.md`.

**Production - Debian packages plus Ansible.** There is no public apt
source: build the package set from a checkout into a local apt
repository first, then either provision with Ansible or install by hand.

```bash
git clone https://github.com/jeonghanlee/ethercat-env
cd ethercat-env
make init && make pkg.orig
# then dpkg-buildpackage + index a local apt repo - see docs/install.md
```

Provision with Ansible - the `ethercat_master` role installs the
packages from the local repo, renders `/etc/ethercat.conf`, and starts
`ethercat.service`:

```bash
cd ansible
ansible-playbook playbooks/site.yml -e ethercat_master_device=<iface>
```

Without Ansible, install and configure by hand: `sudo apt install
ethercat-host` (pulls `ethercat-dkms` and `ethercat-tools`), copy the
reference example to `/etc/ethercat.conf`, set `MASTER0_DEVICE`, and
`systemctl enable --now ethercat.service`. `libethercat1` /
`libethercat-dev` are the runtime library and its development files. See
`docs/install.md` for the full build and local-repo steps.

**Development - Make wrapper.** The retained wrapper builds and installs
under the `/opt/ethercat` prefix for development and CI:

```bash
sudo apt install -y linux-headers-$(uname -r) build-essential libtool automake dkms
make init
make build.baseline
```

The full wrapper target surface (doctor, profiles, patches, DKMS
lifecycle, runtime configuration, systemd/udev, RT host policy, removal,
verification) is listed by `make help`.

## Documentation

| Document | Scope |
| :--- | :--- |
| `docs/delivery-model.md` | Package and role delivery model: the capability-to-destination map |
| `docs/architecture.md` | System architecture, delivery structure, and data flow |
| `docs/install.md` | Installation - production (packages + Ansible) and development (wrapper) |
| `docs/operation.md` | Routine operation and read-only status collection |
| `docs/removal.md` | Removal, rollback, and residue audit |
| `docs/rt-tuning.md` | Debian 13 real-time host policy (role and wrapper at parity) |
| `docs/field-readiness.md` | VM and hardware acceptance evidence model |
| `docs/testplan_1.0.0.md` | Release 1.0.0 cycle test plan |
| `docs/milestone.md` | Canonical work register and milestone status |

## Related Repositories

| Repository | Role |
| :--- | :--- |
| [ethercat-env-validation](https://github.com/jeonghanlee/ethercat-env-validation) | VM real-execution validation: the source-build and package/Ansible acceptance vehicles and recorded evidence |
| [etherlabmaster](https://github.com/jeonghanlee/etherlabmaster) | Historical reference implementation |
| [realtime-config](https://github.com/jeonghanlee/realtime-config) | Real-time host configuration reference |
