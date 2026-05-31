# EtherCAT/RT Buildout — File-Level Development Plan (M1–M14)

## Purpose And Reading Order

This document is the implementer-facing, file-level development plan for
milestones M1 through M14 in `docs/milestone.md`. It is non-hardware: every
verification step in this plan is repository-local (dry-run, `make help`,
variable inspection, lint). No step in this plan installs software, mutates
host state, edits GRUB, loads kernel modules, or runs real-time tuning. Those
actions belong to live execution and the M16 external gate, not to this plan.

For each milestone the plan records:

- **(a) Target files** to create or modify under `configure/` or new directories.
- **(b) New make targets** and their purpose.
- **(c) Classification** — non-root vs root-affecting.
- **(d) Required guards** for root-affecting or destructive targets.
- **(e) Repository-local verification** — dry-run / `make help` / lint only.

## Delegated Decisions (User Authority, Delegated This Session)

These three decisions were delegated to the assistant for this session. They are
marked inline at each milestone where they take effect, and are restated here so
they can be reviewed or reverted later as a set.

- **Delegated decision D1 — Module lifecycle strategy: DKMS.** The recorded
  lifecycle strategy for M8 is DKMS, so that kernel modules auto-rebuild on a
  Debian 13 kernel update. The direct `make build.modules` / `install.modules`
  path is retained as the developer build path, not the production lifecycle.
  Affects M8, and the kernel-update branch of M14.

- **Delegated decision D2 — RT kernel and boot default.** M11 provisions the RT
  kernel and headers but does **not** force the boot default to the RT kernel.
  Kernel selection is explicit, and confirmation of the running kernel is a
  post-reboot external gate (M16), not a repository action. Affects M11.

- **Delegated decision D3 — RT latency tools.** Latency tools (cyclictest and
  similar) are archive/examples only. They are never an active runtime input and
  never gate a repository target. Affects M12.

## Current Broken State (Verified, Pre-M4)

These are confirmed by direct inspection and dry-run on the current tree. M4 and
M5 exist to close them.

| Symptom | Verified observation |
| --- | --- |
| `install` collides | `install` is defined in both `RULES_ETHERCAT` (`install: build`) and `RULES_INSTALL` (`install: src_install`); `make --dry-run install` runs the `src_install` recipe and drops the build recipe. |
| `.versions` writes to `/` | `SITE_TEMPLATE_PATH` is empty, so `src_version` writes `/.versions`. |
| `src_install` dead | `make --dry-run install` aborts: `No rule to make target src_preinst`. |
| Empty DKMS vars | `MODULE_NAME`, `MODULE_VERSION`, `USERID`, `GROUPID`, `WITH_PATCHSET` all resolve empty via `make print-*`. |
| Unguarded `rm -rf` | `src_uninstall` runs `rm -rf $(INSTALL_LOCATION)/` with no non-empty/absolute-path assertion. |
| Name mismatch | `src_uninstall` requires `src_version_clean` (underscore); the defined target is `src_version.clean` (dot). |
| Profile policy violation | `ETHERCAT_OPTIONS` currently contains `--enable-r8169`; `CONFIG_SITE` sets `WITH_DEV_R8169:=YES`, contradicting the generic-only default. |
| Duplicate target | `deinit: distclean` is declared twice in `RULES_SRC`. |

## Ordering Constraints Honored By This Plan

| Constraint | How this plan honors it |
| --- | --- |
| M1 acceptance before broad rework | M1 produces a parity/acceptance matrix doc; no target rework precedes it. |
| M4 is non-root structural only | M4 only splits files, resolves collisions, and defines `*.dryrun` stubs. No host mutation. |
| M5 doctor precedes root-affecting M8/M10/M11/M13 | Every root-affecting target in M8/M10/M11/M13 lists `doctor` (or a scoped doctor) as a hard prerequisite (fails closed): its recipe exits non-zero on any missing required tool. `require-root` runs as the first line of every root-affecting recipe. |
| Destructive guards precede removal | M5 ships `guard-path` / `require-root` macros; M13 removal targets depend on them. |
| M2 reproducibility before M3 durable | M2 adds the verify-on-checkout gate; M3 baseline re-verification consumes it. |
| M14 after M5, as regression gate for M8–M13 | M14 targets are added after M5 and assert dry-run/idempotence/residue for M8–M13. |

## New Directory Layout Introduced By This Plan

```
configure/
  CONFIG, CONFIG_*            existing variable layer (modified in place)
  RULES, RULES_*              existing rule layer (modified / split)
  RULES_DOCTOR     (new)      M5 host/tool doctor + guard macros
  RULES_PROFILE    (new)      M6 profile.matrix and native-profile gate
  RULES_RUNTIME    (new)      M9 ethercat.conf generator + lint
  RULES_SYSTEMD    (new)      M10 systemd/udev/command/loader integration
  RULES_RT         (new)      M11 RT host configuration (provision/limits/boot/clock/service/tuned)
  RULES_RTDIAG     (new)      M12 priority helper + latency tool classification
  RULES_REMOVE     (new)      M13 stop/disable/uninstall/purge/audit with guards
  RULES_VERIFY     (new)      M14 repository-local verification harness
  CONFIG_RT        (new)      M11 RT variable surface (package names, limits, grub params, clocksource)
  CONFIG_DOCTOR    (new)      M5 expected tool path inventory
templates/         (new)      unit/rule/conf templates (no install by themselves)
  epics-ethercat.service.in
  99-EtherCAT.rules.in
  ethercat.conf.in
patch/             (new)      M7 patch registry root with class subdirs
  registry.mk                 declared patch registry (class -> files)
docs/
  milestone.md                existing
  dev-plan-buildout.md        this file
  (M15 doc set lands here later)
```

The aggregators `configure/CONFIG` and `configure/RULES` are the only files that
gain `include` lines for the new modules; targets always live in `RULES_*`,
variables always in `CONFIG_*`, matching the existing layer separation.

---

## M1 — Functional Parity Inventory

**(a) Target files**

- Modify `docs/milestone.md` — mark each EtherCAT and RT acceptance row as
  checked against the two reference repositories.
- Create `docs/parity-matrix.md` — one row per old capability, the new
  repository responsibility, the owning milestone, and the repository-local
  acceptance test name.

**(b) New make targets**

- None. M1 is a documentation/inventory milestone. It defines the acceptance
  vocabulary that later targets (`profile.matrix`, `patch.status`, `runtime.status`,
  `rt.status`) must satisfy, but introduces no recipe.

**(c) Classification** — Non-root (documentation only).

**(d) Guards** — None required.

**(e) Repository-local verification**

- Markdown lint of `docs/parity-matrix.md`.
- Cross-check (one direction): every acceptance row names a milestone that exists
  in this plan. The `milestone.md` Acceptance Criteria tables are
  capability-scoped (EtherCAT + RT), not milestone-scoped, so pure scaffolding or
  documentation milestones (M1, M3, M14) do not each own an acceptance row; the
  cross-check therefore runs acceptance-row -> milestone only, not the reverse.

---

## M2 — Upstream Source Baseline (Reproducibility)

Closes before M3 is treated as durable.

**(a) Target files**

- Modify `configure/RELEASE` — add `SRC_HASH` (the pinned expected revision,
  observed `1.6.9-4-g46cc20e6`) alongside the existing `SRC_TAG`. Assign
  `SITE_TEMPLATE_PATH` a non-empty value (currently empty, so `src_version`
  writes `/.versions`); resolve it to a repository-local default (for example
  `$(TOP)`) so the `.versions` write never targets `/`.
- Modify `configure/RULES_SRC` — add the verify-on-checkout gate and wire it
  into `init`. Guard the `src_version` `.versions` WRITE recipe (not only the
  M13 delete) with a non-empty/absolute `SITE_TEMPLATE_PATH` assertion (promoted
  to the M5 `guard-path` macro once it lands) so a missing or empty
  `SITE_TEMPLATE_PATH` aborts the write before `/.versions` can be created.
- Modify `configure/RULES_FUNC` — add a `verify_revision` macro that compares
  `git -C $(SRC_PATH) rev-parse HEAD` (or `git describe`) against `SRC_HASH`.

**(b) New make targets**

- `src.verify` — assert the checked-out revision matches `SRC_HASH`; mismatch
  fails non-zero. Purpose: make `stable-1.6` reproducible despite being a moving
  branch.
- `src.revision` — print the observed revision and the expected `SRC_HASH` side
  by side (read-only inspection).
- `init` gains `src.verify` as a final prerequisite so `make init` fails if the
  branch has moved off the pinned revision.

**(c) Classification** — Non-root. `git` operations inside the clone directory
only; no host mutation outside `$(SRC_PATH)`.

**(d) Guards** — `src.verify` must fail closed: an empty `SRC_HASH` or an empty
`rev-parse` output is treated as a mismatch, never as a pass.

**(e) Repository-local verification**

- `make print-SRC_HASH` resolves non-empty.
- `make --dry-run src.verify` shows the comparison command.
- `make src.revision` prints both values without mutating anything.

---

## M3 — Debian 13 Build Baseline

Depends on M2.

**(a) Target files**

- Modify `configure/CONFIG_SRC` — keep `OS_NAME`/`OS_VERSION` detection; add a
  Debian-13 assertion variable consumed by a guard target. (Decision to retain
  vs delete the Darwin/CentOS branches is deferred to the user as a cleanup
  question, not pre-decided here.)
- Modify `README.md` — correct the stale Debian 12 reference to Debian 13.

**(b) New make targets**

- `build.baseline` — order-only umbrella that depends on `src.verify` then the
  existing `autoconf`, `build`, `build.modules`; documents the reproducible
  build path as one named entry point.
- `host.debian13` — non-fatal report of detected OS name/version vs expected
  Debian 13 (the hard fail lives in M5 `doctor`; this is the lightweight report).

**(c) Classification** — Non-root (configure + build inside `$(SRC_PATH)`; no
install).

**(d) Guards** — None destructive. Build remains separated from install (M4
enforces the separation structurally).

**(e) Repository-local verification**

- `make --dry-run build.baseline` shows `src.verify` ahead of build.
- `make host.debian13` prints detected vs expected without failing the tree.
- `grep` confirms no remaining Debian 12 string in `README.md`.

---

## M4 — Makefile Target Architecture (Non-Root Structural Only)

Strictly non-root. M4 resolves collisions and separates build from install; it
must not mutate host state.

**(a) Target files**

- Modify `configure/RULES_ETHERCAT` — rename its colliding `install` /
  `uninstall` to build-scoped names (`build.install` / `build.uninstall`, the
  `make -C $(SRC_PATH) install` wrappers) so they no longer collide with the
  prefix-tree install in `RULES_INSTALL`.
- Modify `configure/RULES_INSTALL` — fix the `src_version_clean` ->
  `src_version.clean` prerequisite name; remove the undefined `src_preinst`
  prerequisite from `src_install` and the undefined `sd_*`/`src_postrm`
  prerequisites from `src_uninstall` (these are re-introduced as real targets in
  M10/M13, wired through the aggregator rather than dangling here).
- Modify `configure/RULES_SRC` — remove the duplicate `deinit: distclean`
  declaration.
- Modify `configure/RULES` — confirm include order accommodates the new modules.
- Create `configure/RULES_DRYRUN` (optional thin layer) — pattern rule `%.dryrun`
  that re-invokes `make --dry-run %` for any target, giving every milestone a
  uniform dry-run entry point.

**(b) New make targets**

- `build.install` / `build.uninstall` (renamed from the colliding `install` /
  `uninstall` in `RULES_ETHERCAT`) — purpose: keep the upstream `make install`
  wrapper available without shadowing the prefix-tree installer.
- `targets` — list the structural target graph grouped by phase (acquire,
  configure, build, install, runtime, remove) for review.
- `%.dryrun` pattern target — purpose: uniform `make <name>.dryrun` across all
  milestones.

**(c) Classification** — Non-root only. No recipe in M4 touches anything outside
the repo and `$(SRC_PATH)`.

**(d) Guards** — Not destructive. The guard here is structural: `make --dry-run
install` must no longer drop a recipe or reference an undefined target.

**(e) Repository-local verification**

- `make --dry-run install` completes without `No rule to make target` errors.
- `make help` and `make targets` render the phase-grouped graph.
- `make --dry-run build` and `make --dry-run build.install` show distinct,
  non-overlapping recipes (build separated from install).

---

## M5 — Host And Tool Doctor (+ Destructive Guards)

Precondition for all root-affecting work (M8, M10, M11, M13). M14 may begin
after this.

**(a) Target files**

- Create `configure/CONFIG_DOCTOR` — expected tool path inventory:
  `autoreconf`, `depmod`, `dkms`, `update-grub`/`/usr/sbin/update-grub`,
  `systemctl`, `udevadm`, `ldconfig`, kernel-headers location, module tools.
- Create `configure/RULES_DOCTOR` — the `doctor` target and the reusable guard
  macros.
- Modify `configure/CONFIG` — `include configure/CONFIG_DOCTOR`.
- Modify `configure/RULES` — `include configure/RULES_DOCTOR` early, so the guard
  macros are defined before later modules use them.
- Modify `configure/RULES_FUNC` — host the `guard-path` and `require-root`
  macro definitions if co-locating with existing macros is cleaner than a
  separate file (one of the two; flagged for user preference, not pre-decided).

**(b) New make targets**

- `doctor` — verify each tool in `CONFIG_DOCTOR` exists and is executable; report
  present/absent per tool; read-only, never installs anything. Non-zero exit when
  a required tool for the requested operation is missing.
- `doctor.tools` / `doctor.kernel` / `doctor.systemd` — scoped sub-reports so a
  root-affecting target can depend only on the doctor scope it needs.
- Guard macros (not user targets, consumed by other targets):
  - `guard-path` — assert a path variable is non-empty, absolute, and under an
    expected prefix before any `rm -rf` or install.
  - `require-root` — run as the first line of every root-affecting recipe;
    assert the operation is being run with the privilege it needs (or routed
    through `$(SUDO)`), and fail closed before any partial change. `doctor` (or a
    scoped `doctor.kernel`/`doctor.tools`/`doctor.systemd`) is the companion hard
    prerequisite whose recipe exits non-zero on any missing required tool.

**(c) Classification** — `doctor` itself is non-root (read-only probing). The
guard macros are the safety layer for the root-affecting milestones.

**(d) Guards** — This milestone *is* the guard layer. `guard-path` is the
mandatory precondition for every destructive `rm -rf` in M13 and for the
prefix-tree uninstall; `require-root` precedes every host-mutating recipe in
M8/M10/M11.

**(e) Repository-local verification**

- `make doctor` runs read-only and reports tool presence on the current host.
- `make --dry-run <any destructive target>` shows the `guard-path` check ahead of
  the destructive command.
- Negative test (repository-local): invoke `guard-path` with an empty path
  variable and confirm it fails non-zero before any `rm` is reached.

---

## M6 — Profile And Support Matrix

Depends on M5.

**(a) Target files**

- Modify `configure/CONFIG_SITE` — set the tracked default to generic-only:
  change `WITH_DEV_R8169:=YES` to `:=NO` (or remove from the default set), so the
  default `ETHERCAT_OPTIONS` no longer contains `--enable-r8169`. Native NIC
  flags become opt-in via `CONFIG_SITE.local`.
- Create `configure/RULES_PROFILE` — `profile.matrix` and the native-profile
  evidence gate.
- Modify `configure/RULES` — `include configure/RULES_PROFILE`.

**(b) New make targets**

- `profile.matrix` — print each device flag, whether it is enabled, and whether
  the active kernel plus the upstream source tree provide the matching driver
  (evidence-based availability). Read-only.
- `profile.check` — fail before `autoconf` if a native profile is enabled without
  kernel + upstream-source evidence. Wired as a prerequisite of `autoconf`.

**(c) Classification** — Non-root (inspects kernel version string and the
`$(SRC_PATH)` driver file set; no host mutation).

**(d) Guards** — `profile.check` fails closed: an enabled native profile with no
matching driver evidence is a hard failure before configure, never a warning.

**(e) Repository-local verification**

- `make print-ETHERCAT_OPTIONS` no longer contains `--enable-r8169` by default.
- `make profile.matrix` renders the matrix.
- `make --dry-run autoconf` shows `profile.check` ahead of `./configure`.
- Negative test: enable a native profile with no driver file present and confirm
  `profile.check` fails.

---

## M7 — Patch Architecture

Depends on M4.

**(a) Target files**

- Create `patch/registry.mk` — the declared patch registry: a mapping of patch
  class (`site`, `compatibility`, `hardware`, `archive`) to file lists.
- Create `patch/` class subdirectories as registry anchors.
- Modify `configure/RULES_PATCH` — add `patch.status` and rename/alias
  `patch.revert` to the acceptance-named `patch.reverse` (keep `patch.revert` as
  a deprecated alias for one cycle; the rename-vs-alias choice is flagged for the
  user, not pre-decided).
- Modify `configure/RULES_FUNC` — extend the patch macros to honor class
  selection rather than a single `SRC_TAG*` glob.
- Modify `configure/CONFIG_SITE` or `CONFIG_ETHERCAT` — assign `WITH_PATCHSET`
  an explicit default (currently never assigned, so the RTMUTEX branch is dead).

**(b) New make targets**

- `patch.status` — report pristine vs patched, and which classes are applied.
  Read-only.
- `patch.reverse` — acceptance-named reverse of `patch.apply` (was `patch.revert`).
- `patch.apply` / `patch.make` — retained; now class-aware.

**(c) Classification** — Non-root (operates inside `$(SRC_PATH)` only).

**(d) Guards** — No patch is applied implicitly during checkout. `patch.apply`
must be an explicit target; M2 `init` does not call it.

**(e) Repository-local verification**

- `make patch.status` reports pristine on a fresh clone.
- `make --dry-run patch.apply` and `make --dry-run patch.reverse` show the
  class-scoped p0 loop.
- `make print-WITH_PATCHSET` resolves to an explicit value.

---

## M8 — Kernel Module Lifecycle

Depends on M5, M6. Root-affecting; `doctor` precedes it.

**Delegated decision D1 applies here: DKMS is the recorded production lifecycle;
`build.modules` is retained as the developer path.**

**(a) Target files**

- Modify `configure/CONFIG_MODULE` — define `MODULE_NAME` and `MODULE_VERSION`
  (currently undefined, which makes every DKMS target expand empty). Add DKMS
  source-tree location variables.
- Create `templates/` entry for `dkms.conf.in` (or generate inline) — DKMS
  metadata template parameterized by `MODULE_NAME`/`MODULE_VERSION`.
- Modify `configure/RULES_ETHERCAT` — make the DKMS targets depend on `doctor`
  (specifically `doctor.kernel`/`doctor.tools` for `dkms` + `depmod`), and add a
  `dkms.conf` generation target; record DKMS as the lifecycle in a comment/var.

**(b) New make targets**

- `dkms.conf` — generate the DKMS metadata file from `MODULE_NAME`/`MODULE_VERSION`.
  Non-root (writes into the source tree, not into `/var/lib/dkms`).
- `module.lifecycle` — print the recorded strategy (DKMS) and the kernel-update
  rebuild expectation. Read-only.
- Existing `build.dkms` / `add.dkms` / `install.dkms` / `remove.dkms` /
  `uninstall.dkms` — now functional (non-empty `MODULE_NAME`/`VERSION`) and each
  gains `doctor` as a hard prerequisite (fails closed).
- `build.modules` / `install.modules` retained as the developer path (D1).

**(c) Classification**

- Non-root: `dkms.conf`, `module.lifecycle`, `build.dkms`, `build.modules`.
- Root-affecting: `add.dkms`, `install.dkms`, `remove.dkms`, `uninstall.dkms`,
  `install.modules`, `uninstall.modules` (these touch `/var/lib/dkms`, run
  `depmod -a`, or write to `/lib/modules`).

**(d) Guards** — Each root-affecting module target depends on `doctor` (dkms +
depmod present) as a hard prerequisite (fails closed) and runs `require-root` as
the first recipe line, failing before any partial change if a required tool is
missing. The existing `install.modules` / `uninstall.modules` / `install.dkms` /
`uninstall.dkms` / `add.dkms` / `remove.dkms` targets and `depmod -a` currently
perform their root mutations bare (no `$(SUDO)`); this milestone routes every one
of them through `$(SUDO)`, and `require-root` verifies that routing. `depmod -a`
is never run bare and never without the `doctor` precondition.

**(e) Repository-local verification**

- `make print-MODULE_NAME` and `make print-MODULE_VERSION` resolve non-empty.
- `make --dry-run install.dkms` shows a fully expanded `dkms ... -m <name> -v
  <version>` with `doctor` ahead of it.
- `make module.lifecycle` prints DKMS as the recorded strategy.
- `make --dry-run dkms.conf` shows the generated metadata path.

---

## M9 — Runtime Configuration Generator (`ethercat.conf`)

Depends on M6.

**(a) Target files**

- Create `templates/ethercat.conf.in` — parameterized stanzas for master device,
  backup device, device modules, and up/down interface entries.
- Create `configure/RULES_RUNTIME` — the generator and lint targets.
- Modify `configure/ethercatmaster.conf` — keep as the site input (master device
  names); the generator consumes it rather than the static file being the final
  artifact.
- Modify `configure/RULES` — `include configure/RULES_RUNTIME`.

**(b) New make targets**

- `runtime.generate` — render `ethercat.conf` from `ethercatmaster.conf` site
  inputs + selected profile into a repository-local output (not into `/etc`).
- `runtime.lint` — validate the generated config (required keys present, master
  device named, interface stanzas well-formed). Read-only.
- `runtime.config.show` — print the generated config (dry-run/status).
- `iface.prepare` — owning target for the **NIC preparation** acceptance row:
  bring the NIC for the selected profile up/down per the resolved interface
  stanzas. Root-affecting; depends on `doctor` (ip/link tooling present) as a
  hard prerequisite (fails closed) and runs `require-root` as its first recipe
  line. Operates only on the interface named by the selected profile.
- `iface.status` — report the resolved interface name and current link state for
  the selected profile (dry-run/status). Non-root, read-only.

**(c) Classification**

- Non-root: `runtime.generate`, `runtime.lint`, `runtime.config.show`,
  `iface.status`, all `*.dryrun`. Generation writes to a repo-local build path;
  installation into `/etc` is an M10 root-affecting concern, kept separate here.
- Root-affecting: `iface.prepare` (brings the selected-profile NIC up/down).

**(d) Guards** — `runtime.generate` writes only to the repo-local output path; it
never writes to `/etc/ethercat.conf` directly. Empty master device is a lint
failure. `iface.prepare` depends on `doctor` as a hard prerequisite (fails
closed) and runs `require-root` as its first recipe line; it refuses to act on an
empty or unresolved interface name.

**(e) Repository-local verification**

- `make runtime.generate` produces a repo-local config artifact.
- `make runtime.lint` passes on the generated artifact and fails on a config with
  a missing master device.
- `make runtime.config.show` prints the rendered stanzas.
- `make iface.status` reports the resolved interface and link state, read-only.
- `make --dry-run iface.prepare` shows the up/down commands for the
  selected-profile interface, with `doctor` + `require-root` ahead.

---

## M10 — systemd, udev, Command Path, Loader Integration

Depends on M5, M8, M9. Root-affecting; `doctor` precedes it.

**(a) Target files**

- Create `templates/epics-ethercat.service.in` — systemd unit template.
- Create `templates/99-EtherCAT.rules.in` — udev rule template for the EtherCAT
  character device access policy.
- Create `configure/RULES_SYSTEMD` — install/enable/start/stop/disable/remove for
  the service, install/remove for the udev rule, command-path (`/usr/bin/ethercat`)
  and `ldconfig` loader integration, and `runtime.status`.
- Modify `configure/RULES_INSTALL` — the real `sd_stop` / `sd_disable` /
  `sd_clean` targets (referenced but undefined today) are defined here and wired
  in, so `src_uninstall` resolves.
- Modify `configure/RULES` — `include configure/RULES_SYSTEMD`.

**(b) New make targets**

- `systemd.install` / `systemd.enable` / `systemd.start` / `systemd.stop` /
  `systemd.disable` / `systemd.remove` — service lifecycle.
- `udev.install` / `udev.remove` — udev rule lifecycle.
- `command.install` / `command.audit` — `/usr/bin/ethercat` exposure and discovery.
- `loader.install` / `loader.audit` — `ldconfig` loader integration and audit.
- `runtime.status` — report userspace binary state, service state, loaded module
  state, configured master devices, and selected profile independently. Read-only.
- `sd_stop` / `sd_disable` / `sd_clean` — the previously-dangling prerequisites,
  now real, consumed by M13 removal.

**(c) Classification**

- Non-root: `runtime.status`, `command.audit`, `loader.audit`, all `*.dryrun`.
- Root-affecting: every `*.install` / `*.remove` / `*.enable` / `*.start` /
  `*.stop` / `*.disable`, and the `sd_*` targets.

**(d) Guards** — Each root-affecting target depends on `doctor` (systemctl,
udevadm, ldconfig present) and `require-root`, and fails before partial changes.
Templates are rendered to a repo-local staging path first; only the install
target copies into the system location.

**(e) Repository-local verification**

- `make --dry-run systemd.install` shows the unit being staged then copied, with
  `doctor` ahead.
- `make --dry-run udev.install` shows the rule path and reload command.
- `make runtime.status` runs read-only and reports the five independent states.
- `make --dry-run src_uninstall` resolves (no more undefined `sd_*`).

---

## M11 — Debian 13 Real-Time Host Configuration

Depends on M5. Root-affecting; `doctor` precedes it.

**Delegated decision D2 applies here: provision the RT kernel and headers, but do
not force the boot default. Kernel selection is explicit; running-kernel
confirmation is a post-reboot external gate (M16).**

**(a) Target files**

- Create `configure/CONFIG_RT` — RT variable surface: RT kernel/header package
  names, realtime group name, `/etc/security/limits.d` policy file content,
  GRUB parameter set, expected clock source, service policy allowlist, tuned
  profile name.
- Create `configure/RULES_RT` — RT provisioning, limits, boot-parameter, clock,
  service-policy, and tuned targets, plus `rt.status`.
- Modify `configure/CONFIG` — `include configure/CONFIG_RT`.
- Modify `configure/RULES` — `include configure/RULES_RT`.

**(b) New make targets**

- `rt.kernel.provision` — install RT kernel and headers (does **not** set boot
  default — D2). Root-affecting.
- `rt.kernel.select` — record/expose explicit kernel selection; does not force
  default; post-reboot verification is external (D2).
- `rt.limits.install` / `rt.limits.audit` — realtime group and limits.d policy.
- `rt.grub.apply` / `rt.grub.audit` — GRUB parameter management with backup and
  rollback.
- `rt.clock.status` — current and available clock sources (read-only).
- `rt.service.apply` / `rt.service.audit` — service policy with explicit
  allowlist and dry-run behavior.
- `rt.tuned.status` — report tuned available/selected/active; use only when
  available and explicitly selected.
- `rt.status` — consolidated kernel, boot, clock, service, limits, tuned state.
  Read-only; external reboot evidence noted where required.

**(c) Classification**

- Non-root: `rt.status`, `rt.clock.status`, `rt.limits.audit`, `rt.grub.audit`,
  `rt.service.audit`, `rt.tuned.status`, all `*.dryrun`.
- Root-affecting: `rt.kernel.provision`, `rt.limits.install`, `rt.grub.apply`,
  `rt.service.apply`.

**(d) Guards**

- `rt.kernel.provision` never sets the boot default (D2); boot-default change is
  out of scope for repository targets.
- `rt.grub.apply` backs up the current GRUB config before edit, is idempotent,
  and provides `rt.grub.rollback`; it depends on `doctor` (update-grub present)
  and `require-root`.
- `rt.service.apply` operates only on the explicit allowlist in `CONFIG_RT`;
  anything outside the allowlist is never touched.
- All root-affecting RT targets depend on `doctor` + `require-root` and fail
  before partial changes.

**(e) Repository-local verification**

- `make rt.status` runs read-only and reports each sub-state.
- `make --dry-run rt.grub.apply` shows the backup step ahead of the edit and a
  matching `rt.grub.rollback` path.
- `make --dry-run rt.kernel.provision` shows package install with no
  boot-default mutation.
- `make --dry-run rt.limits.install` shows the realtime group and limits.d
  policy write, with `doctor` + `require-root` ahead and a `guard-path` check on
  the limits.d target path.
- `make --dry-run rt.service.apply` shows only allowlisted services.

---

## M12 — RT Priority And Latency Diagnostics

Depends on M11.

**Delegated decision D3 applies here: latency tools are archive/examples only,
never an active runtime input and never a gate.**

**(a) Target files**

- Create `configure/RULES_RTDIAG` — priority helper and latency-tool
  classification.
- Modify `configure/RULES` — `include configure/RULES_RTDIAG`.
- Create `templates/` or an `examples/` anchor for the archived latency tooling
  (cyclictest invocation examples), explicitly marked archive-only (D3).

**(b) New make targets**

- `rt.priority.show` — identify the candidate process or IRQ-thread target before
  any mutation. Read-only.
- `rt.priority.apply` — controlled priority change for an explicitly named
  process or IRQ thread target only. Root-affecting.
- `rt.latency.classify` — classify latency tools as active / optional / archive;
  records the archive-only status of cyclictest (D3). Read-only. As declared
  metadata (documentation only, consistent with D3 archive-only) it records the
  **Latency evidence** acceptance row's evidence output path (where an operator
  would deposit a latency run, e.g. an `examples/`/archive location) and the
  minimum result set expected (for example min/avg/max latency plus sample
  count). This is recorded as metadata; the repository never produces or gates on
  this evidence.
- `rt.latency.examples` — print the archived example invocations; never runs them
  as a repository step (D3).

**(c) Classification**

- Non-root: `rt.priority.show`, `rt.latency.classify`, `rt.latency.examples`.
- Root-affecting: `rt.priority.apply` (changes scheduling priority).

**(d) Guards** — `rt.priority.apply` requires an explicit named target (process
or IRQ thread); it refuses to run with an empty or wildcard target, identifies
the target first via `rt.priority.show`, and depends on `require-root`. Latency
tools never gate any target (D3).

**(e) Repository-local verification**

- `make rt.priority.show` prints the resolved target without mutating priority.
- `make --dry-run rt.priority.apply TARGET=<name>` shows the change; with no
  `TARGET` it fails closed.
- `make rt.latency.classify` reports cyclictest as archive-only.

---

## M13 — Removal And Rollback

Depends on M5, M8, M10, M11. Destructive; guards precede it.

**(a) Target files**

- Create `configure/RULES_REMOVE` — the consolidated stop/disable/uninstall/
  purge/audit graph for both EtherCAT and RT host state.
- Modify `configure/RULES_INSTALL` — `src_uninstall` now routes its `rm -rf
  $(INSTALL_LOCATION)/` through the M5 `guard-path` macro and depends on the real
  `sd_*` targets from M10 and the corrected `src_version.clean` name.
- Modify `configure/RULES` — `include configure/RULES_REMOVE`.

**(b) New make targets**

- `remove.stop` / `remove.disable` — service and module stop/disable
  (delegates to M10 `sd_*` and M8 module targets).
- `remove.uninstall` — remove installed files, units, udev rules, command path,
  loader entries; each step guarded.
- `remove.rt` — revert the M11 RT host mutations: call `rt.grub.rollback` to
  restore the backed-up GRUB config, remove the installed `/etc/security/limits.d`
  policy file, and undo the `rt.service` allowlist changes. Each sub-step is
  guarded (`guard-path` on the limits.d path; `doctor` + `require-root` on the
  grub-rollback and service steps). Root-affecting.
- `remove.purge` — remove configuration and state in addition to files;
  distinct from `uninstall`.
- `remove.audit` — report residual files/units/rules/config after removal,
  including RT residue (RT kernel/header packages still present, leftover
  limits.d policy file, unreverted GRUB parameters, residual service-allowlist
  entries). Read-only.
- `remove.dryrun` — show the full removal sequence without executing.

**(c) Classification**

- Non-root: `remove.audit`, `remove.dryrun`.
- Root-affecting / destructive: `remove.stop`, `remove.disable`,
  `remove.uninstall`, `remove.rt`, `remove.purge`, and `src_uninstall`.

**(d) Guards**

- Every `rm -rf` (including the existing `src_uninstall` and
  `src_version.clean`) must pass `guard-path`: the path variable is non-empty,
  absolute, and under the expected prefix (`/opt/ethercat`, `/etc`, etc.). An
  empty `INSTALL_LOCATION` or `SITE_TEMPLATE_PATH` aborts before any `rm`.
- Destructive targets depend on `require-root` and fail before partial changes.
- `remove.dryrun` is the recommended first step; the milestone treats removal as
  stop -> disable -> uninstall -> (optional) purge -> audit, not a single blunt
  `rm -rf`.

**(e) Repository-local verification**

- `make --dry-run remove.uninstall` shows `guard-path` ahead of each `rm`.
- Negative test: force `INSTALL_LOCATION` empty and confirm the guard aborts
  before any `rm` is reached.
- `make remove.audit` runs read-only and reports residue.
- `make --dry-run src_uninstall` resolves cleanly with the corrected
  `src_version.clean` prerequisite.

---

## M14 — Repository-Local Verification Harness

Depends on M4, M5. Begins after M5; acts as the regression gate for M8–M13.

**(a) Target files**

- Create `configure/RULES_VERIFY` — the verification harness targets.
- Modify `configure/RULES` — `include configure/RULES_VERIFY`.
- Optionally create `tests/` for any helper scripts the harness shells out to
  (repository-local, no host mutation).

**(b) New make targets**

- `verify.reproducibility` — assert `src.verify` (M2) and that `make init`
  reaches the pinned revision. Non-hardware.
- `verify.dryrun` — assert every root-affecting target produces a non-empty
  dry-run and references `doctor` (or a scoped doctor) plus `require-root`.
  `guard-path` is additionally required only for targets that run `rm` or write
  under a path prefix; targets whose mutation is `depmod -a`, `ldconfig`,
  `update-grub`, or `systemctl` are gated by `doctor` + `require-root` only (no
  `guard-path`).
- `verify.idempotence` — assert that repeated dry-run output for install/apply
  targets is stable (no spurious diffs).
- `verify.residue` — assert `remove.audit` reports no residue after a dry-run
  removal sequence.
- `verify.all` — umbrella over the above; the regression gate for M8–M13.

**(c) Classification** — Non-root. The entire harness is dry-run / inspection /
lint. It performs no install, no module load, no GRUB edit, no service start.

**(d) Guards** — The harness itself is non-destructive by construction. Its job
is to assert that the *other* milestones' guards are present: `verify.dryrun`
fails if any root-affecting target lacks a `doctor` (or scoped doctor) plus
`require-root` precondition, and additionally fails if any `rm`/path-prefix-write
target lacks `guard-path`. Pure `depmod`/`ldconfig`/`update-grub`/`systemctl`
targets are checked for `doctor` + `require-root` only, not `guard-path`.

**(e) Repository-local verification**

- `make verify.all` runs entirely dry-run / read-only and exits non-zero on a
  regression.
- `make verify.dryrun` flags any root-affecting target missing its guard.
- `make help` lists the `verify.*` targets.

---

## Cross-Milestone Hygiene Fixes (Folded Into M4/M7)

These are small defects surfaced during analysis. They are folded into the
milestone that owns the file, not given their own milestone:

- Duplicate `deinit: distclean` in `RULES_SRC` — removed in M4.
- `src_version_clean` vs `src_version.clean` name mismatch — corrected in M4.
- `WITH_PATCHSET` never assigned — given an explicit default in M7.
- Help-awk `regexp escape sequence` warnings — addressed opportunistically in M4
  (leave-as-is vs fix is a user call; flagged, not pre-decided).
- Commented ChannelFinder (`CF_*`) leftovers in `CONFIG_VARS` and Darwin/CentOS
  branches in `CONFIG_SRC` — cleanup vs keep-as-historical is deferred to the
  user as an explicit decision, not silently removed.

## Open Risks

1. **Reference repositories not yet cloned.** M1 acceptance rows must be checked
   against `etherlabmaster` and `realtime-config`; until those are cloned and
   compared, the parity matrix rows are asserted from the milestone doc, not
   verified against the source repos.
2. **`SRC_HASH` pin is a moving-branch snapshot.** The observed revision
   `1.6.9-4-g46cc20e6` pins `stable-1.6` today; if upstream advances the branch,
   `src.verify` will fail by design and the pin must be consciously updated, not
   silently bumped.
3. **DKMS lifecycle (D1) vs direct modules.** Keeping both paths risks drift
   between what the developer builds (`build.modules`) and what production
   rebuilds (DKMS). M14 `verify.*` should assert the two produce the same module
   set, but full proof needs the M16 kernel-update hardware gate.
4. **RT boot default left to the operator (D2).** The repository provisions the
   RT kernel but does not select it at boot; a host can be "provisioned but not
   running RT" with no repository-visible failure. The post-reboot confirmation
   is external (M16), so `rt.status` can report ready-to-select while the running
   kernel is still the stock kernel.
5. **GRUB rollback is repository-local only.** `rt.grub.rollback` restores the
   backed-up config file, but a host that fails to boot after an apply cannot be
   recovered by a repository target. That recovery is an operator/console action
   outside this plan.
6. **Decision points deliberately left open.** Several cleanup choices
   (Darwin/CentOS branch removal, `CF_*` leftovers, `patch.revert` alias
   retention, guard-macro file placement) are flagged for the user rather than
   pre-decided, per the cleanup communication procedure. They are not blockers,
   but they are unresolved until the user rules on them.
