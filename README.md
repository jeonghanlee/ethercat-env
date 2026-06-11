# EtherCAT Master Configuration Environment

Configuration Environment for EtherLab IgH EtherCAT Master at https://gitlab.com/etherlab.org/ethercat

## History
The long history behind this repository is https://github.com/jeonghanlee/etherlabmaster. Most of the options are identical, but I redesign the old repository to finish the same jobs. However, only **Debian** is the supported platform.

## Packages

One should install relevant packages before trying to setup this repository. After this, one should reboot the system once in order to match the running kernel version and kernel header files. If one has its own customized kernel version, one should configure them properly. The following guide is only valid for a **Vanilla Kernel** of Debian Linux 13.

* Debian 13
 ```
 $ apt install -y linux-headers-$(uname -r) build-essential libtool automake tree dkms
 ```

## Quick Start

```bash
$ make init
$ make autoconf
$ make build
$ make build.modules
```

The full target surface (doctor, profiles, patches, DKMS lifecycle, runtime
configuration, systemd/udev, RT host policy, removal, verification) is listed
by `make help` and documented under `docs/`.

## Documentation

| Document | Scope |
| :--- | :--- |
| `docs/architecture.md` | System architecture and target graph design |
| `docs/install.md` | Installation target graph and host state |
| `docs/operation.md` | Read-only status collection and routine operation |
| `docs/removal.md` | Removal, rollback, and residue audit |
| `docs/rt-tuning.md` | Debian 13 real-time host policy |
| `docs/field-readiness.md` | VM and hardware acceptance evidence model |
| `docs/milestone.md` | Canonical work register and milestone status |

## Related Repositories

| Repository | Role |
| :--- | :--- |
| [ethercat-env-validation](https://github.com/jeonghanlee/ethercat-env-validation) | VM real-execution validation harness and evidence for this repository (R2-12) |
| [etherlabmaster](https://github.com/jeonghanlee/etherlabmaster) | Historical reference implementation |
| [realtime-config](https://github.com/jeonghanlee/realtime-config) | Real-time host configuration reference |
