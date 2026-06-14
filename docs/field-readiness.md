# Field Readiness And Acceptance

## Scope

This document defines the VM, hardware, reboot, and production acceptance
evidence required after repository-local verification, for both delivery
vehicles (source-build and package/Ansible).

**Out of scope:** Architecture is covered in `docs/architecture.md`; routine operation is covered in `docs/operation.md`; install, removal, and RT policy mechanics are covered in their dedicated documents.

## Readiness Model

Repository-local verification proves target graph structure and guarded
behavior. Field readiness requires execution evidence from environments
that can mutate host state and exercise real EtherCAT hardware.

Acceptance proceeds in two stages.

| Stage | Environment | Purpose | State |
| :--- | :--- | :--- | :--- |
| VM acceptance | Debian 13 VM | Execute the root-affecting install, module, systemd, udev, GRUB, service-policy, and removal behavior for real, on both acceptance vehicles. | Complete (release-1.0.0 cycle M9). |
| R2-13 / Revision 1 M16 | Target hardware | Prove real adapter behavior, slave discovery, reboot persistence, kernel update behavior, unload/reload, RT readiness, and production acceptance. | Blocked (hardware gate). |

## Repository-Local Precondition

Before VM execution, the repository should have a clean repository-local
verification pass.

```bash
make verify.all
make profile.matrix
make patch.status
make runtime.status
make rt.status
make remove.audit
```

These targets do not replace VM or hardware execution. They establish
that the target graph and read-only reporting surface are coherent
before host mutation.

## VM Execution Evidence

The VM validation environment is a separate validation repository, not
additional state inside this repository: [ethercat-env-validation](https://github.com/jeonghanlee/ethercat-env-validation) carries the qemu/KVM driver, the phase scripts, and the recorded evidence sets. The VM is Debian 13 and runs the root-affecting targets in dependency order behind the doctor and guard checks.

Two acceptance vehicles run on the VM at outcome parity (the operational
end-state is identical; the master service unit differs by route -
source `epics-ethercat.service`, package `ethercat.service`). The
durable parity record is the Source-vs-Package Acceptance Parity table
in `docs/testplan_1.0.0.md`.

| Vehicle | Phases | Evidence |
| :--- | :--- | :--- |
| Source-build path | p1-p9 | Build from the pinned upstream source, install, DKMS, runtime, systemd/udev, RT, post-reboot, removal (the R2-12 vehicle). |
| Package/Ansible path | p10-p18 | Package-install phases (p10 build, p11 DKMS, p12 tools, p13 host), Ansible-provisioning phases (p14 `rt_host`, p15 `ethercat_master` via `site.yml`), the lint/check gate p16, and the acceptance run p17 (pre-reboot parity) - host-driven reboot - p18 (post-reboot parity, removal). |

Minimum VM evidence per vehicle:

| Area | Evidence |
| :--- | :--- |
| Source and build / package build | Source build or `dpkg-buildpackage` produces the expected artifacts; source revision and orig checksum verified. |
| Prefix/userspace or command | Command path resolves; `ethercat-tools` is self-contained (`libethercat1` is not installed - no in-cycle consumer); loader state recorded. |
| DKMS | `dkms.conf`/DKMS source, add/install behavior, cross-kernel vermagic, and resulting module state recorded. |
| Runtime config | Configuration is linted/rendered with a bound `MASTER0_DEVICE`; the installed config path recorded. |
| systemd and udev | Unit and rule installation, reload, enable/start/stop/disable behavior, the `ethercat` group, and status output recorded. |
| RT policy | Kernel provisioning, limits, GRUB apply/audit/rollback, service policy, clock status, and tuned status recorded; `rt.status` parity. |
| Removal | Purge/uninstall and residue audit outcomes recorded; the `ethercat` group retained as a note (U4). |

The recorded evidence sets are in `ethercat-env-validation`
(`evidence/release-1.0.0/m2` through `m9`).

## Hardware Acceptance Evidence

Hardware acceptance requires a real EtherCAT adapter and at least one
known slave chain. The following gates come from `docs/milestone.md`.

| Gate | Required evidence |
| :--- | :--- |
| Real hardware discovery | `ethercat slaves` works against at least one known slave chain. |
| Native NIC profile acceptance | Adapter driver, kernel version, loaded module, selected profile, and link behavior are recorded. |
| Debian 13 RT readiness | RT readiness is recorded after reboot on target hardware. |
| Reboot persistence | The system starts from cold boot without manual module or service repair. |
| Kernel update behavior | DKMS rebuild or package update behavior is demonstrated after a kernel update. |
| Production deployment approval | Site owner accepts install, rollback, and removal behavior. |

## Status Classification

Repository-local milestones can be complete while hardware gates remain
blocked. A milestone is not field-complete until the required VM or
hardware evidence exists in the appropriate validation record.

VM acceptance is complete for both vehicles (cycle M9). The current next
execution entry point is R2-13 / Revision 1 M16 hardware acceptance on
target hardware with a real adapter and slave chain.
