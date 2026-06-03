# Functional Parity / Acceptance Matrix (M1)

## Purpose

This matrix is the M1 acceptance artifact required by
`docs/dev-plan-buildout.md` ("Create `docs/parity-matrix.md` — one row per old
capability, the new repository responsibility, the owning milestone, and the
repository-local acceptance test name"). It pairs each acceptance criterion in
`docs/milestone.md` ("Acceptance Criteria") with the milestone(s) that own it,
the planned make target(s) that satisfy it, and the repository-local acceptance
test that demonstrates it.

Every test named here is repository-local: dry-run, `make help`, variable
inspection (`make print-*`), generator output, or lint. No row in this matrix
installs software, mutates host state, edits GRUB, loads a kernel module, or
runs real-time tuning. Live hardware and post-reboot evidence is out of scope
here and is tracked by the M16 external gate (see `docs/milestone.md`,
"External Gates").

## Reading The Columns

- **Criterion** — the acceptance row as named in `docs/milestone.md`.
- **Owning milestone(s)** — the milestone(s) in `docs/dev-plan-buildout.md`
  responsible for the criterion. Rows that legitimately span two milestones are
  marked and explained in "Multi-Milestone Rows" below.
- **Planned target name(s)** — the make target(s) the dev plan introduces to
  satisfy the criterion. `print-*` denotes variable inspection, not a recipe.
- **Repository-local acceptance test** — the dry-run / status / lint / inspection
  command that demonstrates the criterion without host mutation.

## EtherCAT Acceptance Criteria

| # | Criterion | Owning milestone(s) | Planned target name(s) | Repository-local acceptance test |
| --- | --- | --- | --- | --- |
| EC-1 | Source checkout | M2 | `src.verify`, `src.revision`, `init` | `make print-SRC_HASH` non-empty; `make --dry-run src.verify` shows the rev compare; `make src.revision` prints observed vs expected. |
| EC-2 | Autoconf and build | M3 (M4 separation) | `build.baseline`, `host.debian13`, `build.install` | `make --dry-run build.baseline` shows `src.verify` ahead of build; `make --dry-run build` and `make --dry-run build.install` show distinct, non-overlapping recipes. |
| EC-3 | Device profile selection | M6 | `profile.matrix`, `profile.check` | `make print-ETHERCAT_OPTIONS` has no `--enable-r8169` by default; `make profile.matrix` renders; `make --dry-run autoconf` shows `profile.check` ahead of `./configure`; negative test fails on unsupported native profile. |
| EC-4 | Patch handling | M7 | `patch.status`, `patch.apply`, `patch.reverse`, `patch.make` | `make patch.status` reports pristine on a fresh clone; `make --dry-run patch.apply` and `make --dry-run patch.reverse` show the class-scoped p0 loop; `make print-WITH_PATCHSET` resolves explicit. |
| EC-5 | Module lifecycle | M8 + R2-6 + M16 | `module.lifecycle`, `dkms.conf`, `install.dkms`, `build.modules` | M8/R2 repo-local: `make print-MODULE_NAME` / `print-MODULE_VERSION` non-empty; `make module.lifecycle` prints DKMS; `make dkms.conf` emits top-level `MAKE[0]="make modules ..."` and device module entries matching enabled profiles; `make --dry-run install.dkms` shows expanded `dkms ... -m <name> -v <version>` with `doctor` ahead. M16 gate: kernel-update rebuild demonstrated on hardware. |
| EC-6 | Userspace command | M10 (command/loader) + M13 (uninstall) | `command.install`, `command.audit`, `loader.install`, `loader.audit`, `remove.audit` | M10: `make command.audit` and `make loader.audit` run read-only and report discovery; `make --dry-run command.install` / `loader.install`. M13: `make remove.audit` reports residual command path / loader entries after a dry-run removal sequence. |
| EC-7 | `ethercat.conf` | M9 | `runtime.generate`, `runtime.lint`, `runtime.config.show` | `make runtime.generate` produces a repo-local artifact; `make runtime.lint` passes on it and fails on a missing master device; `make runtime.config.show` prints master, backup, device modules, and up/down interface stanzas. |
| EC-8 | NIC preparation | M9 (generator) + M10 (runtime.status) | `iface.prepare` (root-affecting), `iface.status`, `runtime.generate`, `runtime.status` | `make --dry-run iface.prepare` shows the root-affecting up/down operations tied to the selected profile with `doctor` + `require-root` ahead and the link change routed through `$(SUDO) ip link set`; `make iface.status` reports interface state read-only; the up/down stanzas appear in `make runtime.config.show` and are reported by `make runtime.status`. |
| EC-9 | systemd and udev | M10 + R2-7 | `systemd.install`/`enable`/`start`/`stop`/`disable`/`remove`, `udev.install`/`udev.remove`, `runtime.status` | `make --dry-run systemd.install` shows stage-then-copy with `doctor` ahead; `make --dry-run udev.install` shows rule path and reload; `make runtime.status` reports userspace, command link, loader fragment, service, udev rule, module, master, and profile state separately, read-only. |
| EC-10 | Removal | M13 + R2-2/R2-5/R2-8 | `remove.uninstall`, `remove.purge`, `remove.audit`, `remove.dryrun`, `src_uninstall`, `remove.rt` | `make --dry-run remove.uninstall` shows `guard-path` ahead of each `rm`; negative tests force `/tmp/not-ethercat` and `/etc/passwd` path overrides and the guard aborts before any mutation line; `make --dry-run remove.rt` reports missing GRUB backup separately; `make remove.audit` reports residue read-only. |

## Real-Time Host Acceptance Criteria

| # | Criterion | Owning milestone(s) | Planned target name(s) | Repository-local acceptance test |
| --- | --- | --- | --- | --- |
| RT-1 | RT kernel provisioning | M11 | `rt.kernel.provision`, `rt.status` | `make --dry-run rt.kernel.provision` shows package install with no boot-default mutation and `doctor` + `require-root` ahead; `make rt.status` reports the package state read-only. |
| RT-2 | RT kernel selection | M11 (repo) + M16 (reboot gate) | `rt.kernel.select`, `rt.status` | M11: `make rt.kernel.select` records/exposes explicit selection without forcing default; `make rt.status` reports pre-reboot kernel state. M16: post-reboot running-kernel confirmation on hardware (D2). |
| RT-3 | Realtime limits | M11 | `rt.limits.install`, `rt.limits.audit` | `make --dry-run rt.limits.install` shows the realtime group and `limits.d` policy with `doctor` + `require-root` ahead; `make rt.limits.audit` reports group/limits state read-only. |
| RT-4 | Boot parameters | M11 (apply/audit) + R2-4/R2-8 + M16 (reboot gate) | `rt.grub.apply`, `rt.grub.audit`, `rt.grub.rollback`, `remove.rt` | M11/R2: `make --dry-run rt.grub.apply` shows scoped GRUB doctor before backup/edit, exact-file guards, idempotence, and a matching `rt.grub.rollback`; `make rt.grub.audit` read-only; `make --dry-run remove.rt` does not require a backup to continue cleanup. M16: reboot persistence gate on hardware. |
| RT-5 | Clock source | M11 | `rt.clock.status`, `rt.status` | `make rt.clock.status` reports current and available clock sources read-only; `make rt.status` reports expected vs actual. |
| RT-6 | Service policy | M11 (apply/audit) + M13/R2-8 (rollback) | `rt.service.apply`, `rt.service.audit`, `remove.rt`, `remove.audit` | M11: `make --dry-run rt.service.apply` shows only allowlisted services; `make rt.service.audit` read-only. M13/R2: `remove.rt` unblocks service cleanup even when GRUB rollback is absent; `make remove.audit` reports service policy residue. |
| RT-7 | tuned support | M11 | `rt.tuned.status` | `make rt.tuned.status` reports tuned available / selected / active; used only when available and explicitly selected (D3-adjacent: never auto-engaged). |
| RT-8 | RT readiness | M11 (consolidation) + M16 (reboot evidence) | `rt.status` | M11: `make rt.status` consolidates kernel, boot, clock, service, limits, and tuned state read-only. M16: external reboot evidence recorded on target hardware. |
| RT-9 | Priority helper | M12 | `rt.priority.show`, `rt.priority.apply` | `make rt.priority.show` prints the resolved process/IRQ-thread target without mutation; `make --dry-run rt.priority.apply TARGET=<name>` shows the change; with no `TARGET` it fails closed. |
| RT-10 | Latency evidence | M12 | `rt.latency.classify`, `rt.latency.examples` | `make rt.latency.classify` reports cyclictest as archive-only (D3); `make rt.latency.examples` prints archived invocations and never runs them as a repository step. |

## Multi-Milestone Rows (Explicit Spans)

Four rows are owned by two milestones each. They are called out here so the
boundary is unambiguous and so M14 `verify.*` can assert both halves.

| Row | First milestone (repository-local) | Second milestone | Why it spans |
| --- | --- | --- | --- |
| EC-5 Module lifecycle | M8 — lifecycle record, `dkms.conf` generation, expanded DKMS dry-run, `MODULE_NAME`/`MODULE_VERSION` non-empty | M16 — kernel-update rebuild demonstrated on hardware | M8 records and proves the DKMS strategy repository-locally; the actual rebuild-after-kernel-update outcome can only be demonstrated on hardware. The dev plan and `docs/milestone.md` "Review Convergence Summary" both attribute this to M8, and the "Kernel update behavior" external gate names M8, M14, M16. |
| EC-6 Userspace command | M10 — `command.install`/`command.audit`, `loader.install`/`loader.audit` | M13 — `remove.audit` proves command path and loader entries are reversible | "Userspace command and loader integration" is M8/M10/M13 per `docs/milestone.md` "Review Convergence Summary". M10 establishes exposure and discovery; M13 proves the uninstall/audit reversibility the criterion requires ("explicit and reversible"). |
| EC-8 NIC preparation | M9 — `iface.prepare` (root-affecting NIC up/down) and `iface.status` (read-only) driven by the selected profile, up/down stanzas rendered into `ethercat.conf` | M10 — `runtime.status` reports interface operations alongside service/module state | NIC preparation is generated from the profile-driven runtime config (M9) but its operational state surfaces through the consolidated runtime view (M10). `iface.prepare` performs the actual link-state change and is root-affecting (`doctor` + `require-root` + `$(SUDO) ip link`); `iface.status` is read-only. See "New NIC Preparation Row" below. |
| RT-6 Service policy | M11 — `rt.service.apply`/`rt.service.audit` with explicit allowlist | M13 — service-policy rollback/audit folded into `remove.audit` | The criterion requires "apply, and rollback or audit-only behavior". M11 owns apply/audit; M13 owns the removal/rollback path. |

Additional rows carry a repository-local plus external-gate split rather than two
repository milestones — EC-10 leans on the M5 guard layer, and RT-2 / RT-4 / RT-8
each pair an M11 repository target with an M16 reboot/hardware gate. These are
shown in the per-criterion tables above and are not duplicated here.

## New NIC Preparation Row (`iface.prepare` / `iface.status`)

`docs/milestone.md` lists "NIC preparation — Interface up/down behavior is tied
to selected profile" as a distinct EtherCAT acceptance criterion (EC-8) and the
"EtherCAT Functional Parity Map" lists "NIC activation before master start ->
Explicit interface preparation for generic profile operation". The current dev
plan (`docs/dev-plan-buildout.md`) covers interface up/down only implicitly,
inside the M9 `ethercat.conf` generator ("up/down interface entries") and the
M10 `runtime.status` adapter/profile reporting. This matrix names the row
explicitly and assigns two dedicated targets so the criterion has its own
acceptance handle:

- `iface.prepare` (M9, root-affecting) — bring the profile-selected interface
  up/down via `$(SUDO) ip link set`. It is wired with `doctor` as a normal
  prerequisite (fail-closed) and `require-root` as its first recipe line, and it
  refuses to act on an empty/unresolved interface name. The `up/down` stanzas it
  acts on are also rendered into the repository-local `ethercat.conf` artifact by
  `runtime.generate`; only `iface.prepare` performs the live link-state change.
- `iface.status` (M9/M10, non-root, read-only) — report current interface state
  for the configured master/backup devices, consumed by `runtime.status`.

Acceptance: `make --dry-run iface.prepare` shows the root-affecting interface
operations tied to the active profile with `doctor` + `require-root` ahead of the
`$(SUDO) ip link set` mutation; `make iface.status` reports interface state
read-only; the operations are visible in `make runtime.config.show` and
`make runtime.status`. Hardware link-up behavior is deferred to the M16 "Real
hardware discovery" gate.

## Revision 2 Hardening Coverage

Revision 2 strengthens existing acceptance rows rather than adding new
functional parity rows. Its repository-local coverage is:

| R2 unit | Acceptance rows strengthened | Verification |
| --- | --- | --- |
| R2-1 Profile retirement | EC-3, EC-5, EC-7 | `make print-ETHERCAT_OPTIONS`, `make profile.matrix`, `make runtime.config.show`, and generated `dkms.conf`. |
| R2-2 Prefix-aware path guards | EC-10, RT-3, RT-4, RT-6 | Negative dry-runs for `/etc/passwd`, `/tmp/not-ethercat`, and GRUB file overrides fail before mutation lines. |
| R2-3 Root install guards | EC-10 | `make verify.dryrun` reports `src_install` and `src_uninstall` as doctor + require-root + guard-path, and reports `src_version*` as repo-local guard-path only. |
| R2-4 Tool doctor scope | EC-8, RT-1, RT-4, RT-9 | `make verify.doctor-overrides` proves broken `ip`, `update-grub`, package-manager, and `chrt` paths fail closed. |
| R2-5 Harness coverage | EC-10, RT-3, RT-4, RT-6 | `make verify.dryrun` checks the root/guard union and explicit non-root exceptions. |
| R2-6 DKMS consistency | EC-5 | `make dkms.conf` aligns DKMS `MAKE[0]` with the upstream top-level module build path. |
| R2-7 Runtime status completeness | EC-6, EC-8, EC-9 | `make runtime.status` reports command, loader, service, udev, module, master, and profile state separately. |
| R2-8 RT removal decoupling | EC-10, RT-4, RT-6 | `make --dry-run remove.rt` handles absent GRUB backup separately from limits and service cleanup. |
| R2-9 ASCII cleanup | All generated-output rows | The non-ASCII scan over Makefiles, templates, examples, README, patch metadata, and generated command output reports no matches. |
| R2-10 Documentation refresh | M15 support | This matrix, `docs/milestone.md`, and `docs/dev-plan-buildout.md` describe the same R2 contracts as the code. |
| R2-11 Regression pass | M14 support | `make verify.all`, `make profile.matrix`, `make patch.status`, `make runtime.status`, `make rt.status`, and `make remove.audit` pass repository-locally. |

## Coverage Cross-Check (M1 Verification)

Per `docs/dev-plan-buildout.md` M1 verification ("every acceptance row names a
milestone that exists in this plan, and every milestone in this plan maps to at
least one acceptance row"):

- All 20 acceptance rows map to a milestone in M1–M16. No row is orphaned.
- Milestone-to-row coverage: M2 (EC-1), M3 (EC-2), M6 (EC-3), M7 (EC-4),
  M8 (EC-5), M9 (EC-7, EC-8), M10 (EC-6, EC-8, EC-9), M11 (RT-1..RT-8),
  M12 (RT-9, RT-10), M13 (EC-6, EC-10, RT-6), M16 (EC-5, RT-2, RT-4, RT-8).
- Plan milestones without a direct acceptance row are structural/process
  milestones, not capability rows: M1 (this inventory), M4 (non-root target
  architecture, consumed by EC-2 separation), M5 (doctor + guard layer, consumed
  by EC-10 and every root-affecting row), M14 (verification harness asserting the
  other rows' guards), M15 (documentation set). Each is referenced by at least
  one capability row's guard or test, satisfying the bidirectional check.
