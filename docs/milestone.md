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

Next session entry point: Release 1.0.0 cycle M9 (VM acceptance, issue
#9) on branch `dev/release-1.0.0`. M1 through M8 are closed
(2026-06-12/13, issues #1-#8): delivery model, source package baseline,
ethercat-dkms, the userspace tools split, host integration, the rt_host
and ethercat_master Ansible roles, and the verification umbrella
(verify.all now runs lintian + ansible-lint + a playbook syntax-check,
fresh-VM verified). VM evidence lives in `ethercat-env-validation`
(`evidence/release-1.0.0/m2`-`m8`). M9 extends the standing harness with
package-install and Ansible-provisioning acceptance phases at p1-p9
outcome parity (depends on M8). The cycle work order and verification
subs are in the Release 1.0.0 Cycle section below; procedures are in
`docs/testplan_1.0.0.md`. Milestones M1 through M10 are issues #1 through
#10 under GitHub milestone 1.0.0. R2-13 and Revision 1 M16 remain
external hardware gates and inherit into the cycle unchanged.

The Release 1.0.0 cycle runs remote-authoritative: each milestone issue
carries its verification checkbox list as the status source of truth and
this register mirrors it; M11 is the register-local release gate. For the
closed Revision 1 and Revision 2 records this file remains the source of
truth. Agent memory may keep clone hints for reference repositories, but
milestone status and carry-forward work must be updated here.

## Revision Model

This file tracks development in revisions. Each revision keeps its own
milestone table, status, and external gates.

| Revision | Scope | Status |
| --- | --- | --- |
| Revision 1 | Initial Debian 13 EtherCAT and RT target graph buildout, M1 through M16. | M1-M15 code-complete and repository-local verified; M16 blocked by external validation. |
| Revision 2 | Round 2 hardening after full-code review of Revision 1. | R2-1 through R2-12 closed; R2-12 VM real-execution validated with five live-execution defects fixed; R2-13 remains an external hardware gate. |
| Release 1.0.0 | Successor delivery model: Debian packaging of the upstream master plus Ansible host-configuration roles in this repository. | Open; cycle M1 through M10 tracked as issues #1 through #10, M11 register-local release gate. |

## Current Baseline

| Item | Baseline |
| --- | --- |
| Upstream source | `https://gitlab.com/etherlab.org/ethercat` |
| Source reference | `stable-1.6` |
| Observed upstream revision | `1.6.9-4-g46cc20e6` |
| Source reproducibility | Closed; `configure/RELEASE` pins `SRC_HASH` and `src.verify` fails closed on mismatch (VM-verified under real execution) |
| Host baseline | Debian 13.5, kernel `6.12.88+deb13-amd64` |
| Verified wrapper targets | `make init`, `make autoconf`, `make build`, `make build.modules` |
| Dry-run-verified target surface | Full M1-M14 target graph (`doctor`, `profile.*`, `patch.*`, `src.verify`, `runtime.*`, `systemd.*`, `udev.*`, `rt.*`, `rtdiag.*`, `remove.*`, `verify.*`) resolves under `make --dry-run`; read-only targets run; no host mutation, no hardware test |
| Verified modules | `ec_master.ko`, `ec_generic.ko`, `ec_r8169.ko`, `ec_mini.ko` |
| Default profile under review | `generic` first, native NIC profiles enabled explicitly |
| Target operating system | Debian 13 only |

## Reference Repositories

| Repository | Role | Remote |
| --- | --- | --- |
| `etherlabmaster` | EtherCAT master operation reference | `git@github.com:jeonghanlee/etherlabmaster.git` |
| `realtime-config` | Real-time host configuration reference | `git@github.com:jeonghanlee/realtime-config.git` |
| `ethercat-env-validation` | R2-12 VM real-execution validation harness and evidence | `git@github.com:jeonghanlee/ethercat-env-validation.git` |

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
| Patch, patchset, and legacy OS flows | Declared patch registry with site, compatibility, hardware, and archive classes |
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

## Revision 1 Milestones

| Topic | Work unit | Type | Status | Depends on | Evidence or next action |
| --- | --- | --- | --- | --- | --- |
| Planning | M1 Functional parity inventory | Milestone | Implemented | None | Acceptance criteria and parity matrix are authored here and in `docs/parity-matrix.md`. |
| Source | M2 Upstream source baseline | Milestone | Implemented (repo-local, dry-run verified) | M1 | `configure/RELEASE` pins official upstream `stable-1.6` with `src.verify` / `src.revision` verify-on-checkout policy. |
| Build | M3 Debian 13 build baseline | Milestone | Implemented (repo-local, dry-run verified) | M2 | `build.baseline` chains `src.verify` then autoconf, build, build.modules; repeat under real execution on a Debian 13 VM. |
| Makefile | M4 Makefile target architecture | Milestone | Implemented (repo-local; dry-run verified; M16 hardware gate pending) | M1, M2 | Modular `RULES_*` / `CONFIG_*` split with QUIET and dry-run plumbing; root-affecting targets isolated behind doctor and guards. |
| Doctor | M5 Host and tool doctor | Milestone | Implemented (repo-local; dry-run verified; M16 hardware gate pending) | M4 | `doctor`, scoped tool doctors, `require-root`, and prefix-aware `guard-path` fail closed before root-affecting targets. |
| Profile | M6 Profile and support matrix | Milestone | Implemented (repo-local; dry-run verified; M16 hardware gate pending) | M5 | Tracked default is `generic` only; `profile.matrix` / `profile.check` require kernel and upstream source evidence for native profiles. |
| Patch | M7 Patch architecture | Milestone | Implemented (repo-local; dry-run verified; M16 hardware gate pending) | M4 | Declared patch registry with `patch.status`, `patch.apply`, `patch.reverse` and site/compatibility/hardware/archive classes. |
| Kernel modules | M8 Kernel module lifecycle | Milestone | Implemented (repo-local; dry-run verified; M16 hardware gate pending) | M5, M6 | DKMS lifecycle strategy recorded; `dkms.conf` generated from the template; `module.lifecycle` reports strategy read-only. |
| Runtime config | M9 Runtime configuration generator | Milestone | Implemented (repo-local; dry-run verified; M16 hardware gate pending) | M6 | `runtime.generate` / `runtime.lint` / `runtime.config.show` render and validate `ethercat.conf` from template and profile inputs. |
| System integration | M10 systemd, udev, command path, and loader integration | Milestone | Implemented (repo-local; dry-run verified; M16 hardware gate pending) | M5, M8, M9 | `systemd.*`, `udev.*`, command path, and loader install/enable/start/stop/disable/remove/audit targets exist; render is non-root. |
| Real-time host | M11 Debian 13 real-time host configuration | Milestone | Implemented (repo-local; dry-run verified; M16 hardware gate pending) | M5 | `RULES_RT` reimplements RT packages, kernel selection, limits, boot parameters, clock source, tuned, and service policy. |
| Diagnostics | M12 RT priority and latency diagnostics | Milestone | Implemented (repo-local; dry-run verified; M16 hardware gate pending) | M11 | `RULES_RTDIAG` adds the controlled priority helper, active/optional/archive tool classification, and evidence capture. |
| Rollback | M13 Removal and rollback | Milestone | Implemented (repo-local; dry-run verified; M16 hardware gate pending) | M5, M8, M10, M11 | `RULES_REMOVE` provides stop, disable, uninstall, purge, guard, and audit paths for EtherCAT and RT host policy state. |
| Verification | M14 Repository-local verification harness | Milestone | Implemented (repo-local; dry-run verified; M16 hardware gate pending) | M4, M5 | `verify.all` runs reproducibility, dry-run, idempotence, and residue checks as a non-hardware regression gate. |
| Documentation | M15 Documentation set | Milestone | Implemented (repository-local; VM and hardware gates pending) | M4 through M14 | `docs/architecture.md`, `docs/operation.md`, `docs/install.md`, `docs/removal.md`, `docs/rt-tuning.md`, and `docs/field-readiness.md` complete the system documentation set. |
| Field validation | M16 Hardware, reboot, and production validation | External gate | Blocked | M6, M8, M11, M14 | Requires real adapter, slave chain, reboot persistence, kernel update behavior, unload/reload, and RT readiness evidence on hardware. |

## Revision 2 Milestones

Revision 2 is Round 2 hardening. It preserves Revision 1 as the initial
buildout and closes repository-local safety and consistency gaps before any
VM or hardware execution.

| Topic | Work unit | Type | Status | Depends on | Evidence or next action |
| --- | --- | --- | --- | --- | --- |
| Scope | R2-1 Drop CCAT support | Milestone | Implemented (repo-local; verified) | Revision 1 M6, M8, M9 | Whole option branch removed, including default `--disable-ccat`; profile, runtime-module, DKMS-module, and template-comment references removed. Verified by `make print-ETHERCAT_OPTIONS`, `make profile.matrix`, and generated runtime config. |
| Safety | R2-2 Prefix-aware path guard | Milestone | Implemented (repo-local; verified) | Revision 1 M5 | `guard-path` now requires caller-supplied expected prefix or exact file path. Negative dry-runs for `/etc/passwd`, `/tmp/not-ethercat`, and GRUB file overrides fail before mutation lines. |
| Safety | R2-3 Root-affecting install guards | Milestone | Implemented (repo-local; verified) | R2-2 | `src_install` and `src_uninstall` carry scoped doctor, `require-root`, and prefix guard; `src_version` and `src_version.clean` remain repo-local non-root exact-file guard targets for `$(TOP)/.versions`. |
| Doctor | R2-4 Tool doctor scope correction | Milestone | Implemented (repo-local; verified) | Revision 1 M5 | Added scoped probes for `ip`, `update-grub`, configured package manager, `dpkg`, `chrt`, and install/remove helpers. Broken override verification is covered by `make verify.doctor-overrides`. |
| Verification | R2-5 Verification harness blind-spot closure | Milestone | Implemented (repo-local; verified) | R2-2, R2-3, R2-4 | `verify.dryrun` checks the union of root-affecting and guard-path registries, with explicit repo-local exceptions for `src_version` and `src_version.clean`. |
| Kernel modules | R2-6 DKMS module build consistency | Milestone | Implemented (repo-local; verified) | R2-1, Revision 1 M8 | `dkms.conf` now builds from the upstream top-level module target so master and enabled device modules are produced consistently. |
| Runtime status | R2-7 Complete runtime status reporting | Milestone | Implemented (repo-local; verified) | Revision 1 M10 | `runtime.status` reports userspace tool, command link, loader fragment, service, udev rule, master module, master devices, and selected device modules separately. |
| Removal | R2-8 RT removal flow decoupling | Milestone | Implemented (repo-local; verified) | Revision 1 M13 | `remove.rt` no longer depends on `rt.grub.rollback`; absent backup is reported as a separate skipped rollback while limits and service cleanup remain available. |
| Hygiene | R2-9 ASCII cleanup for code and generated output | Milestone | Implemented (repo-local; verified) | R2-1 through R2-8 | `rg -nP "[^\\x00-\\x7F]" Makefile configure templates patch examples README.md .gitignore` reports no matches after template regeneration. |
| Documentation | R2-10 Documentation and acceptance refresh | Milestone | Implemented (repo-local; verified) | R2-1 through R2-9 | This register, `docs/dev-plan-buildout.md`, and `docs/parity-matrix.md` record Revision 2 scope, guard semantics, doctor scopes, DKMS consistency, runtime status, removal flow, and verification evidence. |
| Regression | R2-11 Repository-local regression pass | Milestone | Implemented (repo-local; verified) | R2-10 | `make verify.all`, `make profile.matrix`, `make patch.status`, `make runtime.status`, `make rt.status`, and `make remove.audit` passed without intended host mutation. |
| VM validation | R2-12 Debian 13 VM real-execution validation | External gate | Closed (VM real-execution validated) | R2-11 | Validation repository `ethercat-env-validation` executed the full root-affecting graph on a Debian 13 VM: build from pinned revision, prefix install, DKMS lifecycle, runtime config install, systemd/udev, RT kernel and policy, PREEMPT_RT reboot service persistence, cross-kernel DKMS rebuild with matching vermagic, and removal ending in `VERDICT=clean`. Five live-execution defects found and fixed (see R2-12 Findings). Hardware cold boot remains in R2-13/M16. |
| Field validation | R2-13 Hardware, reboot, and production validation | External gate | Blocked | R2-12, Revision 1 M16 | Confirm real adapter, slave chain, reboot persistence, kernel-update rebuild, unload/reload, RT readiness, and production approval on target hardware. |

## R2-12 Findings

Live VM execution found five defects that dry-run verification structurally
could not catch. All five are fixed and re-validated by a full clean
acceptance run (phases p1 through p9 pass first-try on a fresh VM). The
original failure signatures of F1 and F4 were observed live during the
discovery run and are recorded in this table; the preserved discovery logs
are post-fix re-runs of the same phases, and the acceptance set is the
authoritative validation evidence.

| Finding | Defect | Fix |
| --- | --- | --- |
| F1 | `rt.limits.install` aborted with a shell syntax error: the pipe-separated `RT_LIMITS_RULES` expanded raw into the recipe shell, which parsed `\|` as a pipe operator before IFS splitting could apply. | `configure/RULES_RT`: pass the rule list single-quoted into a shell variable, split under `set -f` with `IFS='\|'`. |
| F2 | `/dev/EtherCAT0` stayed root-owned: udev resolves `GROUP` names at rule load time (`resolve_names=early`), and no target created the `ethercat` group, so the GROUP assignment was silently dropped. | `configure/RULES_SYSTEMD`: `udev.install` idempotently creates the system group before installing and reloading the rule; `configure/RULES_REMOVE`: `remove.purge` deletes the group and `remove.audit` checks both groups. |
| F3 | No target installed the rendered `ethercat.conf`; `ethercatctl` kept reading the upstream default (empty `MASTER0_DEVICE`) placed by `build.install`, so the service started no master. | `configure/RULES_RUNTIME`: new root-affecting `runtime.install` (doctor, require-root, guard-path) registered in `RULES_VERIFY` and the target listing; `docs/install.md` updated. |
| F4 | DKMS built every module against the configure-time kernel: the upstream Makefile ignores `KDIR` (uses baked `LINUX_SOURCE_DIR`) and bakes `abs_builddir`, so kernel-update builds escaped the DKMS build tree and DKMS installed the stale copied `.ko` (`module_layout` mismatch, `Exec format error` on the PREEMPT_RT boot). | `templates/dkms.conf.in`: force both `LINUX_SOURCE_DIR=/lib/modules/$kernelver/build` and `abs_builddir=/var/lib/dkms/<module>/<version>/build` as make command-line overrides in `MAKE[0]` and `CLEAN`. Cross-kernel rebuild now produces matching vermagic for a kernel that is not running. |
| F5 | `remove.audit` counted the operator-managed RT kernel package as residue, so `verify.residue` could never pass after RT provisioning, contradicting the documented removal scope. | `configure/RULES_REMOVE`: report the package as a note outside the verdict; `docs/removal.md` aligned. |

Observation recorded for D2: installing `linux-image-rt-amd64` makes GRUB
select the RT kernel as the boot default through version ordering even though
no target writes `GRUB_DEFAULT`; the VM reboot therefore ran PREEMPT_RT.
D2 wording (kernel selection is explicit, post-reboot confirmation is M16)
still holds, but operators should expect the RT kernel to win the default
menu entry once installed.

## Release 1.0.0 Cycle

The cycle target is the successor delivery model in this repository: Debian
packaging of the upstream EtherCAT master plus Ansible host-configuration
roles, with the `ethercat-env-validation` phase harness reused as the
acceptance gate. Repository structure decision (2026-06-11):
single-repository evolution - this repository owns the successor
environment; no new repository is opened.

Mode: remote-authoritative. Each milestone M1 through M10 is tracked by one
GitHub issue (#1 through #10, matching M-numbers) whose verification
checkbox list is the status source of truth; this register mirrors issue
state. M11 is the register-local release gate
and has no issue. Cycle M-numbers are cycle-local; cross-cycle references
use revision-qualified names (for example, Revision 1 M16) or issue numbers.

The cycle plan is `docs/testplan_1.0.0.md`; the standing acceptance vehicle
is the `ethercat-env-validation` phase harness. Procedures live in the plan;
this table tracks status only.

M1 delivery-model decisions (2026-06-12, `docs/delivery-model.md`): package
set `ethercat-dkms`, `ethercat-tools`, `ethercat-host` from source package
`ethercat`; role set `rt_host`, `ethercat_master`. Configuration ownership
is role-exclusive - no packaged `/etc/ethercat.conf`, reference default
outside /etc, fail-closed unit (WireGuard-class precedent). The `ethercat`
group is sysusers.d-managed; purge retains system groups and audits report
them as notes (F5 precedent).

Amended 2026-06-13 (M4 re-review): the package set is five, not three -
the M1 "no libethercat1 split" call is reversed at its scheduled M2/M4
re-review, adding `libethercat1` (runtime library) and `libethercat-dev`
(precedent: libmodbus and 13 peers); `ethercat-tools` narrows to the CLI.

| Topic | Work unit | Type | Status | Depends on | Evidence |
| --- | --- | --- | --- | --- | --- |
| Planning | M1 Successor delivery model and parity map | Milestone | Closed (2026-06-12) | None | Issue #1 closed. `docs/delivery-model.md`; cross-check ACCEPT by both reviewers (session rs20260611_235423). |
| | M1.T1 Parity map completeness review | Verification sub | Done | M1 | 118-target sweep, zero unmapped; both reviewers re-verified independently. |
| Packaging | M2 Debian source package baseline | Milestone | Closed (2026-06-12) | M1 | Issue #2 closed. `configure/RULES_PKG`, `debian/`; upstream ships no debian/ at the pin; cross-check ACCEPT by both reviewers (session rs20260612_015044). |
| | M2.T1 Pinned-revision source package build on Debian 13 | Verification sub | Done | M2 | Fresh VM: in-VM orig matches ORIG_SHA256; dpkg-buildpackage -S and -b clean (evidence/release-1.0.0/m2). |
| | M2.T2 Package build check joins the verification graph | Verification sub | Done | M2 | pkg.verify in verify.all, SKIP-gated; harness charter amended. |
| Packaging | M3 DKMS module package | Milestone | Closed (2026-06-12) | M2 | Issue #3 closed. `debian/ethercat-dkms.dkms` plus PRE_BUILD script; cross-check ACCEPT by both reviewers (session rs20260612_121927). |
| | M3.T1 Install state and cross-kernel vermagic (F4 regression) | Verification sub | Done | M3 | Fresh VM: per-module vermagic matches on cloud and RT kernels; exactly-generic set (evidence/release-1.0.0/m3). |
| | M3.T2 Cross-kernel rebuild as permanent regression check | Verification sub | Done | M3 | Validation phase p11 (permanent); testplan M3 row references it. |
| Packaging | M4 Userspace tools package | Milestone | Closed (2026-06-13) | M2 | Issue #4 closed. Three-way split libethercat1/-dev/ethercat-tools (M1 no-split reversed at M2/M4 re-review); cross-check ACCEPT by both reviewers (session rs20260612_204100). |
| | M4.T1 Command path, loader resolution, uninstall residue | Verification sub | Done | M4 | Fresh VM (p12): ethercat on PATH, ldconfig resolves libethercat.so.1, pkg-config resolves, purge no residue (evidence/release-1.0.0/m4). |
| Packaging | M5 Host integration packaging | Milestone | Closed (2026-06-13) | M3, M4 | Issue #5 closed. ethercat-host (systemd unit, udev rule, sysusers.d group, fail-closed config); cross-check ACCEPT by both reviewers (session rs20260613_002432). |
| | M5.T1 Group creation (F2), config ownership (F3), purge audit (F5) | Verification sub | Done | M5 | Fresh VM (p13): sysusers group + udev rule, /dev/EtherCAT0 group ethercat, fail-closed without config, EC-8 interface up, purge retains group (evidence/release-1.0.0/m5). |
| | M5.T2 Install and purge residue checks join the verification graph | Verification sub | Done | M5 | Validation phase p13 (permanent); testplan M5 row references it. |
| | M5.T3 Re-run M3.T1 and M4.T1 per the dependency matrix | Verification sub | Done | M5 | p13 re-asserts dkms install state and tools command/loader after the host maintainer scripts. |
| Ansible | M6 Ansible role: RT host configuration | Milestone | Closed (2026-06-13) | M1 | Issue #6 closed. `ansible/roles/rt_host`; cross-check ACCEPT by both reviewers (session rs20260613_021435). |
| | M6.T1 Idempotent apply, check-mode accuracy, rt.status outcome parity | Verification sub | Done | M6 | Fresh VM (p14): check-mode predicts, second run changed=0, GRUB default unchanged (D2), rt.status parity (evidence/release-1.0.0/m6). |
| | M6.T2 ansible-lint joins the verification graph | Verification sub | Done | M6 | verify.ansible-lint SKIP-gated in verify.all; p14 ran ansible-lint clean (production profile passed). |
| Ansible | M7 Ansible role: EtherCAT master host | Milestone | Closed (2026-06-13) | M5, M6 | Issue #7 closed. `ansible/roles/ethercat_master` + `site.yml`; cross-check ACCEPT by both reviewers (session rs20260613_132255). |
| | M7.T1 Package install, bound master device (F3 regression), active service | Verification sub | Done | M7 | Fresh VM (p15): site.yml binds MASTER0_DEVICE, renders UPDOWN, starts the service, ec_generic loaded, fail-closed negative (evidence/release-1.0.0/m7). |
| | M7.T3 Re-run M6.T1 per the dependency matrix | Verification sub | Done | M7 | site.yml second apply idempotent (rt_host + ethercat_master); rt_host check-mode/rt.status facets verified at M6/p14. |
| Verification | M8 Repository-local verification | Milestone | Closed (2026-06-13) | M2-M7 | Issue #8 closed. verify.syntax-check + verify.lintian wired into verify.all; cross-check ACCEPT by both reviewers (session rs20260613_151250). |
| | M8.T1 Extended verify.all passes with lintian, ansible-lint, syntax-check | Verification sub | Done | M8 | Fresh VM (p16): lintian --fail-on error clean, verify.all green with all lint/check members real (evidence/release-1.0.0/m8). |
| | M8.T2 Verification wiring as permanent suite addition | Verification sub | Done | M8 | verify.all membership (verify.ansible-lint, verify.syntax-check, verify.lintian) is permanent. |
| Verification | M9 VM acceptance | Milestone | Not started | M8 | Issue #9. |
| | M9.T1 New harness phases pass first-try with p1-p9 outcome parity | Verification sub | Not started | M9 | |
| | M9.T4 Standing harness amended with package-install and Ansible phases | Verification sub | Not started | M9 | |
| Documentation | M10 Documentation refresh | Milestone | Not started | M1-M9 | Issue #10. |
| | M10.T1 Install, operation, removal documents match implemented behavior | Verification sub | Not started | M10 | |
| Gate | M11 Release gate 1.0.0 | Release gate (register-local) | Not started | M1-M10 | Gates merge to master, tag 1.0.0, GitHub release. |
| | M11.T1 Cycle batch re-run against the final tree | Verification sub | Not started | M11 | |
| | M11.T2 Full automated suites | Verification sub | Not started | M11 | |
| | M11.T3 Standing plan executed with M9.T4 amendments | Verification sub | Not started | M11 | |

Tally: 11 milestones (10 issue-tracked, 1 register-local gate) and 21
verification subs; closed: 8 milestones (M1-M8), 15 subs (M1.T1,
M2.T1, M2.T2, M3.T1, M3.T2, M4.T1, M5.T1, M5.T2, M5.T3, M6.T1, M6.T2,
M7.T1, M7.T3, M8.T1, M8.T2). Entry point: M9.

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

The Release 1.0.0 cycle is open on branch `dev/release-1.0.0`. Scope: the
successor delivery model in this repository (single-repository evolution,
decided 2026-06-11) - Debian packaging of the upstream master (the R2-12
finding F4 DKMS knowledge feeds the packaging) plus Ansible
host-configuration roles, acceptance-gated by the `ethercat-env-validation`
phase harness. The work order M1 through M11 with verification subs is in
the Release 1.0.0 Cycle section; procedures are in `docs/testplan_1.0.0.md`.
Milestones M1 through M10 are issues #1 through #10 under GitHub milestone
1.0.0. M1 through M8 are closed (2026-06-12/13, issues #1-#8): delivery
model, source package baseline, the ethercat-dkms package (F4 fix,
cross-kernel vermagic verified), the userspace tools split
(libethercat1 / libethercat-dev / ethercat-tools), host integration
(ethercat-host: systemd unit, udev rule, sysusers.d group, fail-closed
config; F2/F3/F5 and EC-8 verified), the rt_host and ethercat_master
Ansible roles (site.yml composes both; idempotent, bound device, active
service verified), and the verification umbrella (verify.all runs
lintian + ansible-lint + a playbook syntax-check, all real on a fresh
VM). VM evidence: `ethercat-env-validation` (`evidence/release-1.0.0/m2`
through `m8`). Next: M9 (issue #9), VM acceptance - extend the standing
harness with package-install and Ansible-provisioning phases at p1-p9
outcome parity.

R2-13 and Revision 1 M16 remain external hardware gates (real adapter, slave
chain, hardware reboot persistence, unload/reload, RT readiness, production
approval) and inherit into the 1.0.0 cycle unchanged; they cannot close
without target hardware. Revision 1 and Revision 2 closure evidence is
recorded in their sections above and merged to master (`1f40451`). Removal
of the superseded partial VM harness in the `cloud-provision` and
`ansible-provision` repositories remains follow-up work in those
repositories.
