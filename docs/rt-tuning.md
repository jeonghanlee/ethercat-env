# Debian 13 Real-Time Host Tuning

## Scope

This document describes the real-time host configuration owned by this
repository for Debian 13. The same RT policy is delivered by two
vehicles at outcome parity: the production `rt_host` Ansible role
(variables `rt_host_*`) and the development Make wrapper (`RULES_RT`
targets). Both agree against the `rt.status` oracle.

**Out of scope:** EtherCAT service installation is covered in `docs/install.md`; removal is covered in `docs/removal.md`; hardware and post-reboot evidence are covered in `docs/field-readiness.md`.

## RT Policy Boundary

The repository provides Debian 13 RT kernel provisioning, explicit
kernel selection visibility, realtime group and limits policy, GRUB
parameter management, clock source reporting, service policy, tuned
profile reporting, and priority diagnostics.

The repository does not force the RT kernel as the boot default (D2),
and it does not auto-engage tuned. Both properties hold on the role and
the wrapper. Post-reboot confirmation remains an external gate.

## Vehicle Map

| RT capability | `rt_host` role (production) | Wrapper target (development) | Oracle |
| :--- | :--- | :--- | :--- |
| RT kernel provisioning | `tasks/kernel.yml` | `rt.kernel.provision` | `rt.status` |
| RT kernel selection | `rt.status` oracle (no set-default) | `rt.kernel.select` | `rt.status` |
| Realtime limits | `tasks/limits.yml` | `rt.limits.install` / `rt.limits.audit` | `rt.status` |
| Boot parameters | `tasks/grub.yml` | `rt.grub.apply` / `rt.grub.audit` / `rt.grub.rollback` | `rt.status` |
| Clock source | `tasks/clock.yml` | `rt.clock.status` | `rt.status` |
| Service policy | `tasks/services.yml` | `rt.service.apply` / `rt.service.audit` | `rt.status` |
| tuned | `tasks/tuned.yml` | `rt.tuned.status` | `rt.status` |
| RT readiness | `rt.status` oracle | `rt.status` | `rt.status` |

RT-9 (priority helper) and RT-10 (latency tooling) are development-only
and are not part of the `rt_host` role.

## Kernel Provisioning And Selection

The tracked defaults install Debian RT meta-packages:

| Variable | Default |
| :--- | :--- |
| `RT_KERNEL_PKG` / `rt_host_kernel_pkg` | `linux-image-rt-amd64` |
| `RT_HEADERS_PKG` / `rt_host_headers_pkg` | `linux-headers-rt-amd64` |
| `RT_KERNEL_FLAVOR` / `rt_host_kernel_flavor` | `rt-amd64` |

The role `kernel.yml` and the wrapper `rt.kernel.provision` install the
packages and headers without changing the GRUB default (D2). The RT
kernel may still win the default menu entry through version ordering once
installed; post-reboot confirmation is a hardware gate (Revision 1 M16).
The wrapper `rt.kernel.select` reports the running kernel and installed
RT candidates.

## Realtime Limits

The default realtime group is `realtime`, and the default limits file is
`/etc/security/limits.d/99-realtime.conf`. The default policy grants
realtime scheduling priority, unlimited memory lock, and a negative nice
floor to members of the configured group. The role `limits.yml` and the
wrapper `rt.limits.install` write the same policy; `rt.limits.audit`
reports it read-only.

## GRUB Parameters

The repository-managed GRUB targets operate on `/etc/default/grub` and
preserve a backup at `/etc/default/grub.ethercat-rt.bak`. The tracked
default parameter set currently includes `intel_pstate=disable`. CPU
isolation values are declared as overridable variables but empty by
default so a site can set them.

The role `grub.yml` backs up once, appends parameters when absent, and
triggers `update-grub` through a handler; the wrapper `rt.grub.apply` is
idempotent in the same way (preserves the first backup, does not
duplicate parameters). `rt.grub.rollback` restores the backup and runs
`update-grub`.

## Clock Source

`rt.clock.status` (and the role `clock.yml` report) reports the
expected, current, and available clock sources. The default expected
source is `tsc`. This is read-only on both vehicles; it does not change
the kernel clock source.

## Service Policy

The RT service policy operates only on the allowlist
(`RT_SERVICE_ALLOWLIST` / `rt_host_service_allowlist`). The default
allowlist contains `irqbalance.service`, and the default action is
`mask`. No service outside the allowlist is touched. Removal reverses
the action by unmasking allowlisted services (wrapper `remove.rt`).

## tuned Profile

`rt.tuned.status` and the role `tuned.yml` report whether `tuned-adm`
exists, which profile repository configuration selects, and the current
active tuned state when available. The repository never auto-engages
tuned. On the role, set `rt_host_tuned_apply: true` to apply the
realtime profile; on the wrapper, applying tuned is an explicit opt-in.

## Priority And Latency Diagnostics

These are development-only (not in the `rt_host` role).
`rt.priority.show` reports the selected process or IRQ-thread target;
`rt.priority.apply` applies `SCHED_FIFO` priority only when `TARGET` is
explicitly set and fails closed on empty or wildcard targets. Latency
tools are archive/examples only: `rt.latency.classify` records that
tools such as `cyclictest` and `hwlatdetect` are not active runtime
inputs and do not gate repository targets; `rt.latency.examples` prints
archived invocations without running them.

## Consolidated RT Status

`rt.status` is the read-only RT host state summary and the parity oracle
for both vehicles. Run it from a checkout of this repository.

```bash
make rt.status
```

The status report includes kernel selection visibility, GRUB audit,
clock source, realtime limits, service policy, and tuned profile state.
Running-kernel confirmation after reboot is external evidence
(`docs/field-readiness.md`).
