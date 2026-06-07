# Debian 13 Real-Time Host Tuning

## Scope

This document describes the real-time host configuration owned by this repository for Debian 13.

**Out of scope:** EtherCAT service installation is covered in `docs/install.md`; removal is covered in `docs/removal.md`; hardware and post-reboot evidence are covered in `docs/field-readiness.md`.

## RT Policy Boundary

The repository provides Debian 13 RT kernel provisioning, explicit kernel selection visibility, realtime group and limits policy, GRUB parameter management, clock source reporting, service policy, tuned profile reporting, and priority diagnostics.

The repository does not force the RT kernel as the boot default. It also does not auto-engage tuned. Post-reboot confirmation remains an external gate.

## Kernel Provisioning And Selection

The tracked defaults install Debian RT meta-packages:

| Variable | Default |
| :--- | :--- |
| `RT_KERNEL_PKG` | `linux-image-rt-amd64` |
| `RT_HEADERS_PKG` | `linux-headers-rt-amd64` |
| `RT_KERNEL_FLAVOR` | `rt-amd64` |

`rt.kernel.provision` installs the packages and headers. `rt.kernel.select` reports the running kernel and installed RT candidates without changing GRUB defaults.

## Realtime Limits

The default realtime group is `realtime`, and the default limits file is `/etc/security/limits.d/99-realtime.conf`.

The default policy grants realtime scheduling priority, unlimited memory lock, and a negative nice floor to members of the configured group.

```bash
make rt.limits.install
make rt.limits.audit
```

The install target is root-affecting and guarded. The audit target is read-only.

## GRUB Parameters

The repository-managed GRUB targets operate on `/etc/default/grub` and preserve a backup at `/etc/default/grub.ethercat-rt.bak`.

The tracked default parameter set currently includes `intel_pstate=disable`. CPU isolation values are declared as overridable variables but empty by default so a site can set them in `configure/CONFIG_RT.local`.

```bash
make rt.grub.apply
make rt.grub.audit
make rt.grub.rollback
```

`rt.grub.apply` is idempotent: it preserves the first backup and does not duplicate parameters already present. `rt.grub.rollback` restores the backup and runs `update-grub`.

## Clock Source

`rt.clock.status` reports the expected, current, and available clock sources. The default expected source is `tsc`.

This target is read-only. It does not change the kernel clock source.

## Service Policy

The RT service policy operates only on `RT_SERVICE_ALLOWLIST`. The default allowlist contains `irqbalance.service`, and the default action is `mask`.

```bash
make rt.service.apply
make rt.service.audit
```

No service outside the allowlist is touched. Removal reverses the default service action by unmasking allowlisted services through `remove.rt`.

## tuned Profile

`rt.tuned.status` reports whether `tuned-adm` exists, which profile is selected by repository configuration, and the current active tuned state when available.

The repository never auto-engages tuned. A site must explicitly decide whether tuned is part of the operating host profile.

## Priority And Latency Diagnostics

`rt.priority.show` reports the selected process or IRQ-thread target. `rt.priority.apply` applies `SCHED_FIFO` priority only when `TARGET` is explicitly set and fails closed on empty or wildcard targets.

Latency tools are archive/examples only. `rt.latency.classify` records that tools such as `cyclictest` and `hwlatdetect` are not active runtime inputs and do not gate repository targets. `rt.latency.examples` prints archived invocations without running them.

## Consolidated RT Status

Use `rt.status` for the read-only RT host state summary.

```bash
make rt.status
```

The status report includes kernel selection visibility, GRUB audit, clock source, realtime limits, service policy, and tuned profile state. Running-kernel confirmation after reboot is external evidence.
