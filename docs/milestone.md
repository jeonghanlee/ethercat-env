# EtherCAT Environment Development Milestones

## Scope

This document is the repository-local development plan for building one
Debian 13 only repository that combines EtherCAT master host operation and
real-time host configuration.

Functional parity means that the combined repository must provide the same
EtherCAT master operational capabilities as the older `etherlabmaster`
repository, not the same target names or internal file layout. The older
`etherlabmaster` repository is the reference implementation and experience
archive.

The `realtime-config` repository is also a functional parity source. Its
real-time host configuration capabilities must be implemented in the combined
repository with the same operational outcomes. Debian 9, CentOS 7, and ESS VM
mechanics are not copied as operating system targets; they are translated into
Debian 13 equivalents where they represent required functionality.

The integration strategy is function-centered. Existing repository history,
directory names, target names, and script names are references, not compatibility
requirements. The combined repository should expose a coherent Debian 13
operational model even when the original functionality came from separate
repositories.

The plan covers source acquisition, build policy, kernel module profile
selection, patch handling, installation structure, systemd integration, runtime
operation, removal, and documentation. Live field acceptance on production
hardware is tracked as an external gate because it cannot be completed by
repository changes alone.

The final operating system is produced from one repository after the migration.
That repository owns EtherCAT master kernel operation, real-time host tuning,
runtime readiness checks, and field deployment prerequisites for Debian 13.

## Canonical Work Register

Next session entry point: finish M1 acceptance criteria in `docs/milestone.md`,
then start M2 source reproducibility and M4 non-root target graph cleanup in
`configure/RULES`, `configure/RULES_SRC`, and `configure/RULES_ETHERCAT`.
Do not start root-affecting install, module install, systemd, udev, GRUB,
service policy, or removal targets until M5 doctor and destructive-target
guards exist.

This file is the repository source of truth for milestone status. Agent memory
may keep clone hints for reference repositories, but milestone status and
carry-forward work must be updated here.

## Current Baseline

| Item | Baseline |
| --- | --- |
| Upstream source | `https://gitlab.com/etherlab.org/ethercat` |
| Source reference | `stable-1.6` |
| Observed upstream revision | `1.6.9-4-g46cc20e6` |
| Source reproducibility | Not closed; `stable-1.6` is a moving branch and needs a pinned revision or verify-on-checkout policy |
| Host baseline | Debian 13.5, kernel `6.12.88+deb13-amd64` |
| Verified wrapper targets | `make init`, `make autoconf`, `make build`, `make build.modules` |
| Verified modules | `ec_master.ko`, `ec_generic.ko`, `ec_r8169.ko`, `ec_mini.ko` |
| Default profile under review | `generic` first, native NIC profiles enabled explicitly |
| Target operating system | Debian 13 only |

## Reference Repositories

| Repository | Role | Remote |
| --- | --- | --- |
| `etherlabmaster` | EtherCAT master operation reference | `git@github.com:jeonghanlee/etherlabmaster.git` |
| `realtime-config` | Real-time host configuration reference | `git@github.com:jeonghanlee/realtime-config.git` |

These repositories are functional references for this plan. They may be cloned
again when implementation details need to be compared, but their target names,
script names, directory layout, and old distribution-specific command flows are
not compatibility requirements.

## Review Convergence Summary

A multi-agent review convergence (session rs20260530_012525) was used as
local working evidence and is not tracked in this repository. The accepted
findings are absorbed into this register below:

| Finding | Status | Milestone impact |
| --- | --- | --- |
| Functional parity needs testable acceptance criteria | Accepted | M1 |
| Source baseline must be reproducible | Accepted | M2, M3 |
| Tracked default must be generic-only | Accepted | M6 |
| Kernel module lifecycle strategy is a blocking decision | Accepted | M8 |
| Userspace command and loader integration need criteria | Accepted | M8, M10, M13 |
| Debian 13 RT package, boot, clock, service, and rollback criteria are needed | Accepted | M11, M13 |
| Tool path doctor must precede root mutation | Accepted | M5 |
| Repository-local verification is needed before hardware gates | Accepted | M14 |
| External gates need milestone traceability | Accepted | M16 |
| Destructive removal targets need guards | Accepted | M5, M13 |

## Single Repository Assembly Model

| Domain | Owns | Exposes |
| --- | --- | --- |
| EtherCAT master operation | Upstream EtherCAT source, kernel module profile, module lifecycle, `ethercat.conf`, systemd, udev, host diagnostics | Master service state, module state, adapter/profile state, generated host configuration |
| Real-time host configuration | Debian 13 RT kernel readiness, realtime group and limits, boot parameters, clock source, service policy, tuning checks | RT readiness state, boot parameter state, service policy state, latency and priority diagnostics |
| Field deployment readiness | Combined checks across EtherCAT and RT host state | Operational EtherCAT master ready for field use |

## EtherCAT Functional Parity Map

| Old capability | New repository responsibility |
| --- | --- |
| Source checkout from fixed upstream revision | Git source checkout from official upstream reference |
| Autoconf and build orchestration | Debian 13 aware source preparation, configure, userspace build, and module build |
| Device option variables | Evidence-based profile model for generic and native NIC drivers |
| Patch, patchset, CentOS, and CCAT flows | Declared patch registry with site, compatibility, hardware, and archive classes |
| DKMS configuration generation | Kernel module lifecycle strategy with generated module metadata when DKMS is selected |
| Module build and install | Reproducible `ec_master` and device module build, install, uninstall, and depmod flow |
| `ethercat.conf` generation | Runtime configuration generator for master devices, backups, device modules, and up/down interfaces |
| NIC activation before master start | Explicit interface preparation for generic profile operation |
| systemd service installation | Debian 13 systemd unit installation, enable, disable, start, stop, and status handling |
| DKMS autoinstall service | Kernel update rebuild path or documented replacement strategy |
| udev permission rules | EtherCAT character device access policy with install and removal paths |
| `/usr/bin/ethercat` and loader setup | Command path and shared library integration policy |
| Setup cleanup script | Stop, disable, remove, purge, and audit targets with dry-run support |

## Real-Time Functional Parity Map

| Existing capability | Debian 13 only responsibility |
| --- | --- |
| RT kernel installation | Debian 13 RT kernel and header provisioning policy |
| RT kernel selection | Debian 13 default kernel selection and boot verification |
| Realtime group and limits file | Debian 13 realtime group and `/etc/security/limits.d` policy |
| Boot parameter tuning | Debian 13 GRUB parameter management with backup and audit |
| Clock source check | Debian 13 clock source diagnostics and expected-state reporting |
| Service masking | Debian 13 service policy with explicit allowlist and dry-run behavior |
| tuned realtime profile | Debian 13 support check; use only when available and selected |
| RT readiness check | Consolidated `doctor` or `status` target for RT kernel, clock, boot, services, and tuned state |
| RT priority adjustment | Controlled priority helper for selected process or IRQ thread names |
| Latency result files | Archive or examples only, not active runtime inputs |

Functional parity is measured by operating outcomes: the host can be prepared
for real-time operation, the expected kernel and boot state can be verified,
runtime limits are installed, disruptive services are controlled by policy, and
priority or latency evidence can be collected. It is not measured by preserving
Debian 9 or CentOS 7 package commands.

## Acceptance Criteria

EtherCAT acceptance criteria:

| Capability | Repository-local acceptance | Verification or gate |
| --- | --- | --- |
| Source checkout | Source track and pinned revision or verify-on-checkout policy are recorded. | `make init`; `git rev-parse HEAD`; mismatch fails. |
| Autoconf and build | Configure executes once and build targets are separated from install targets. | `make autoconf`; `make build`; `make build.modules`. |
| Device profile selection | Tracked default enables `generic` only; native profiles require explicit selection. | `make profile.matrix`; unsupported native profile fails before configure. |
| Patch handling | Patch status, dry-run, apply, reverse, and archive classes are visible. | `make patch.status`; `make patch.apply`; `make patch.reverse`. |
| Module lifecycle | Direct install, DKMS, Debian package, or staged strategy is recorded before root targets. | Module install and kernel update behavior are verified or gated. |
| Userspace command | `ethercat` command exposure and library loader policy are explicit and reversible. | Command discovery, loader audit, and uninstall audit. |
| `ethercat.conf` | Generated config includes master device, backup, device modules, and up/down interfaces. | Config lint plus dry-run/status output. |
| NIC preparation | Interface up/down behavior is tied to selected profile. | Dry-run and runtime status show intended interface operations. |
| systemd and udev | Service and udev install, enable, start, stop, disable, remove, and audit paths exist. | `make runtime.status`; service and udev state are reported separately. |
| Removal | Destructive targets assert non-empty absolute paths under expected prefixes. | Dry-run and guard failure tests. |

Real-time host acceptance criteria:

| Capability | Repository-local acceptance | Verification or gate |
| --- | --- | --- |
| RT kernel provisioning | Debian 13 RT package and header policy is recorded. | Package status check; no install without explicit root target. |
| RT kernel selection | Boot default and current kernel verification policy is recorded. | Pre-reboot status and post-reboot external gate. |
| Realtime limits | Realtime group and limits file are installed, audited, and reversible or audit-only. | Group/limits status check. |
| Boot parameters | GRUB edit policy includes backup, idempotence, and rollback or audit behavior. | Dry-run; `/usr/sbin/update-grub` doctor; reboot gate. |
| Clock source | Current and available clock sources are reported. | `rt.status` reports expected and actual values. |
| Service policy | Debian 13 service policy distinguishes default services from archived site-specific services. | Status, dry-run, apply, and rollback or audit-only behavior. |
| tuned support | tuned realtime profile is used only when available and explicitly selected. | Doctor reports available, selected, and active state. |
| RT readiness | Kernel, boot, clock, service, limits, and tuned state are consolidated. | `make rt.status`; external reboot evidence where required. |
| Priority helper | Priority changes require explicit process or IRQ thread target and dry-run/status support. | Helper identifies target before mutation. |
| Latency evidence | Active, optional, and archive-only tools are classified. | Evidence output path and minimum result set are recorded. |

## Ordering Constraints

| Constraint | Applies to |
| --- | --- |
| M1 must define acceptance criteria before broad target rework. | M4 through M16 |
| M4 may start only as non-root structural cleanup. | `configure/RULES*`, `configure/CONFIG*` |
| M5 doctor must precede root-affecting install, module, systemd, udev, GRUB, service, and removal targets. | M8, M10, M11, M13 |
| M2 source reproducibility must close before M3 is treated as durable. | M2, M3 |
| M14 repository-local verification may begin after M5 and should act as a regression gate for M8 through M13. | M8 through M13 |
| M14 repository-local verification must exist before field validation is considered the only test path. | M15, M16 |

## Milestones

| Topic | Work unit | Type | Status | Depends on | Evidence or next action |
| --- | --- | --- | --- | --- | --- |
| Planning | M1 Functional parity inventory | Milestone | In progress | None | Acceptance criteria are now summarized here; finish by checking each row against both reference repositories. |
| Source | M2 Upstream source baseline | Milestone | In progress | M1 | `configure/RELEASE` points to official upstream `stable-1.6`; add pinned revision or verify-on-checkout policy. |
| Build | M3 Debian 13 build baseline | Milestone | In progress | M2 | Build passed on current checkout; repeat after M2 source reproducibility closes. |
| Makefile | M4 Makefile target architecture | Milestone | Not started | M1, M2 | Start with non-root structural split only; do not mutate host state. |
| Doctor | M5 Host and tool doctor | Milestone | Not started | M4 | Add tool paths, kernel headers, module tools, systemd, udev, GRUB, root-only action checks, and destructive-target guards. |
| Profile | M6 Profile and support matrix | Milestone | Not started | M5 | Make tracked default `generic` only; native profiles require kernel and upstream source evidence. |
| Patch | M7 Patch architecture | Milestone | Not started | M4 | Add declared patch registry with dry-run, apply, reverse, status, and archive behavior. |
| Kernel modules | M8 Kernel module lifecycle | Milestone | Not started | M5, M6 | Record module lifecycle strategy before root module install targets; include depmod and kernel update behavior. |
| Runtime config | M9 Runtime configuration generator | Milestone | Not started | M6 | Generate and validate `ethercat.conf` from site and profile inputs. |
| System integration | M10 systemd, udev, command path, and loader integration | Milestone | Not started | M5, M8, M9 | Install, enable, start, stop, disable, remove, and audit service, udev, command, and loader state. |
| Real-time host | M11 Debian 13 real-time host configuration | Milestone | Not started | M5 | Reimplement `realtime-config` outcomes for RT packages, kernel selection, limits, boot parameters, clock source, tuned, and service policy. |
| Diagnostics | M12 RT priority and latency diagnostics | Milestone | Not started | M11 | Add controlled priority helper, active/optional/archive tool classification, and readiness evidence capture. |
| Rollback | M13 Removal and rollback | Milestone | Not started | M5, M8, M10, M11 | Stop, disable, uninstall, purge, guard, and audit EtherCAT and RT host policy state. |
| Verification | M14 Repository-local verification harness | Milestone | Not started | M4, M5 | Begin after M5 as a regression gate for M8 through M13; add non-hardware checks for reproducibility, dry-run output, idempotence, and residue audit. |
| Documentation | M15 Documentation set | Milestone | Not started | M4 through M14 | Add architecture, status, profile, operation, install, removal, RT tuning, and field readiness documents. |
| Field validation | M16 Hardware, reboot, and production validation | External gate | Blocked | M6, M8, M11, M14 | Requires real adapter, slave chain, reboot persistence, kernel update behavior, unload/reload, and RT readiness evidence on hardware. |

## Profile Policy

The default profile should remain `generic` unless a native NIC profile is
selected explicitly. Native profile availability must be derived from the
current kernel version and the upstream driver file set, not from general
"possibly supported" assumptions.

For Debian 13, `r8169` is no longer an automatic default. It is a supported
candidate only when the active kernel and upstream source tree include the
matching driver implementation.

## Patch Policy

Patch handling should be treated as a first-class architecture even if no patch
is required on day one. The wrapper should distinguish site policy patches,
Debian or kernel compatibility patches, hardware profile patches, and archived
historical patches.

No patch should be applied implicitly as part of source checkout. A build should
be able to report whether it is using pristine upstream source or a declared
patch set.

## Install And Operation Policy

Installation targets should avoid mixing build, kernel module installation,
systemd setup, runtime start, and removal into one path. Each target should have
a dry-run form where practical, and root-only targets should fail before making
partial changes.

The runtime view should report userspace binary state, service state, loaded
module state, configured master devices, and selected profile independently.

## Host Operation Boundary

This repository owns the Debian 13 host operating state required by the final
EtherCAT master system:

- Kernel module build, installation, removal, and rebuild policy.
- Selection of generic or native device modules.
- `ethercat.conf` generation and validation.
- Network interface preparation required before the master starts.
- systemd unit installation and service lifecycle.
- udev rules and command path integration.
- Runtime status reporting for modules, service, configuration, and adapters.
- Real-time kernel readiness checks.
- Realtime group and process limit policy.
- Boot parameter and clock source diagnostics.
- Service policy needed for predictable real-time operation.
- Priority and latency diagnostics.

Application-level EtherCAT process data mapping remains outside this milestone
document unless it is needed to prove host readiness on real hardware.

## External Gates

| Gate | Responsible milestone | Repository-local precondition | Required field evidence |
| --- | --- | --- | --- |
| Real hardware discovery | M9, M16 | Generated `ethercat.conf` and runtime status path exist. | `ethercat slaves` works against at least one known slave chain. |
| Native NIC profile acceptance | M6, M16 | Profile matrix proves kernel and source support for the selected driver. | Adapter driver, kernel version, loaded module, and link behavior are recorded. |
| Debian 13 RT readiness | M11, M12, M16 | `rt.status` reports kernel, boot, clock, service, limits, and tuned state. | RT readiness is recorded after reboot on target hardware. |
| Reboot persistence | M8, M10, M11, M16 | Service, module, config, and RT policy states are auditable before reboot. | System starts from a cold boot without manual module or service repair. |
| Kernel update behavior | M8, M14, M16 | Module lifecycle strategy and local verification harness exist. | Module rebuild or package update behavior is demonstrated after a kernel update. |
| Production deployment approval | M13, M15, M16 | Install, rollback, removal, and documentation are complete. | Site owner accepts install, rollback, and removal behavior. |

## Next Session Entry Point

Start with M1 acceptance criteria, M2 source reproducibility, and narrow M4
non-root target graph cleanup. Do not start root-affecting module install,
systemd, udev, GRUB, service policy, or removal targets until M5 doctor and
destructive-target guards exist.
