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

**Production - Debian packages plus Ansible.** Install the package set
from a local or site apt repository, then provision with Ansible:

```bash
sudo apt install ethercat-host
cd ansible
ansible-playbook playbooks/site.yml -e ethercat_master_device=<iface>
```

`apt install ethercat-host` pulls `ethercat-dkms` (kernel modules,
rebuilt on each kernel update) and `ethercat-tools` (the CLI);
`libethercat1` / `libethercat-dev` are the runtime library and its
development files. The `ethercat_master` role renders
`/etc/ethercat.conf` and starts `ethercat.service`. See
`docs/install.md`.

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
