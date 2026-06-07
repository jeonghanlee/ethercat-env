# Field Readiness And Acceptance

## Scope

This document defines the VM, hardware, reboot, and production acceptance evidence required after repository-local verification.

**Out of scope:** Architecture is covered in `docs/architecture.md`; routine operation is covered in `docs/operation.md`; install, removal, and RT policy mechanics are covered in their dedicated documents.

## Readiness Model

Repository-local verification proves target graph structure and guarded behavior. Field readiness requires execution evidence from environments that can mutate host state and exercise real EtherCAT hardware.

Acceptance proceeds in two stages.

| Stage | Environment | Purpose |
| :--- | :--- | :--- |
| R2-12 | Debian 13 VM | Execute root-affecting install, module, systemd, udev, GRUB, service-policy, and removal targets for real. |
| R2-13 / M16 | Target hardware | Prove real adapter behavior, slave discovery, reboot persistence, kernel update behavior, unload/reload, RT readiness, and production acceptance. |

## Repository-Local Precondition

Before VM execution, the repository should have a clean repository-local verification pass.

```bash
make verify.all
make profile.matrix
make patch.status
make runtime.status
make rt.status
make remove.audit
```

These targets do not replace VM or hardware execution. They establish that the target graph and read-only reporting surface are coherent before host mutation.

## VM Execution Evidence

The VM validation environment should be a separate validation repository or provisioning workspace, not additional state inside this repository. The VM should be Debian 13 and should run the root-affecting targets in dependency order behind the doctor and guard checks.

Minimum VM evidence:

| Area | Evidence |
| :--- | :--- |
| Source and build | `make init`, `make build.baseline`, and source revision verification succeed. |
| Prefix and userspace | Prefix install path, upstream userspace install path, command link, and loader state are recorded. |
| DKMS | `dkms.conf`, DKMS add/install behavior, and resulting module state are recorded. |
| Runtime config | Generated EtherCAT configuration is linted and the installed or staged config path is recorded. |
| systemd and udev | Unit and rule installation, reload behavior, enable/start/stop/disable behavior, and status output are recorded. |
| RT policy | Kernel package provisioning, limits, GRUB apply/audit/rollback, service policy, clock status, and tuned status are recorded. |
| Removal | `remove.dryrun`, `remove.uninstall`, `remove.rt`, `remove.purge`, and `remove.audit` outcomes are recorded. |

## Hardware Acceptance Evidence

Hardware acceptance requires a real EtherCAT adapter and at least one known slave chain. The following gates come from `docs/milestone.md`.

| Gate | Required evidence |
| :--- | :--- |
| Real hardware discovery | `ethercat slaves` works against at least one known slave chain. |
| Native NIC profile acceptance | Adapter driver, kernel version, loaded module, selected profile, and link behavior are recorded. |
| Debian 13 RT readiness | RT readiness is recorded after reboot on target hardware. |
| Reboot persistence | The system starts from cold boot without manual module or service repair. |
| Kernel update behavior | DKMS rebuild or package update behavior is demonstrated after a kernel update. |
| Production deployment approval | Site owner accepts install, rollback, and removal behavior. |

## Status Classification

Repository-local milestones can be complete while hardware gates remain blocked. A milestone is not field-complete until the required VM or hardware evidence exists in the appropriate validation record.

The current next execution entry point is R2-12 Debian 13 VM real-execution validation. After VM evidence is complete, proceed to R2-13 / M16 hardware acceptance.
