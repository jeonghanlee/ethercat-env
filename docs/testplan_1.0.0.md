# Release 1.0.0 Cycle Test Plan

## Scope

This plan schedules verification for the release 1.0.0 cycle: the successor
delivery model in this repository, adding Debian packaging of the upstream
EtherCAT master and Ansible host-configuration roles. Draft date: 2026-06-11.

This is a living document. Verification cases discovered during cycle work
are added under Added During Cycle with the date and the milestone that
surfaced them. The release tag preserves this plan; read it back with
`git show 1.0.0:docs/testplan_1.0.0.md`.

## Verification Layers

Two layers apply to every milestone:

1. Change-specific verification (T1, and T3 re-runs): designed per
   milestone, depth chosen by blast radius; recorded as `M<n>.T1` subs and
   re-executed as `M<n>.T3` subs when the dependency re-run matrix triggers.
2. Automated suites (T2): cases demanded by acceptance criteria are added to
   the repository verification graph (`make verify.all`) or the validation
   harness as permanent regression assets, never run as one-off checks.

Suite baseline at cycle start: the Revision 2 close state - `make verify.all`
passing at the master merge `1f40451` and the R2-12 acceptance evidence set
preserved in the `ethercat-env-validation` repository.

## Standing Plan

The version-independent acceptance vehicle is the `ethercat-env-validation`
phase harness (phases p1 through p9). It runs identically at every release
gate. Its expected results change only through a T4 amendment by the
milestone that causes the change; this cycle amends it once (M9.T4) by
adding package-install and Ansible-provisioning phases.

## Per-Milestone Verification

| Milestone | Change-specific verification | Suite coverage |
| --- | --- | --- |
| M1 Successor delivery model and parity map | M1.T1: every wrapper capability row carries a destination (package, role, development-only) and an acceptance criterion; no orphan capability against the Makefile target listing and `docs/parity-matrix.md`. | None. |
| M2 Debian source package baseline | M2.T1: source package builds from the pinned upstream revision on Debian 13; orig source matches the `SRC_HASH` policy. | M2.T2: package build check joins the verification graph. |
| M3 DKMS module package | M3.T1: package install reports installed DKMS state for all enabled modules; cross-kernel build for a non-running kernel produces matching vermagic (F4 regression). | M3.T2: cross-kernel rebuild case recorded as a permanent regression check (validation harness phase p11). |
| M4 Userspace tools package | M4.T1 (validation phase p12): `ethercat` command resolves on PATH, `libethercat1` resolves via the loader, uninstall leaves no residue; supplementary dev evidence: `libethercat-dev` installs and `pkg-config --modversion libethercat` resolves. | None. |
| M5 Host integration packaging | M5.T1 (amended 2026-06-12, M1): the `ethercat` group is sysusers.d-declared and exists before udev rule load (F2); no `/etc/ethercat.conf` is shipped - the reference default lives outside /etc and the unit fails closed when the config is absent (F3); the unit path brings the configured UPDOWN interfaces up at service start (EC-8); service and udev states report correctly; purge retains system groups and audits report them as notes, ending clean (F5 semantics). M5.T3: re-run M3.T1 and M4.T1 per the dependency matrix. | M5.T2 (validation phase p13): install and purge residue checks land as a permanent regression phase. |
| M6 Ansible role: RT host configuration | M6.T1: role applies on a clean host, a second run reports zero changes, check-mode predicts the apply, outcomes match `rt.status` expectations. | M6.T2: ansible-lint joins the verification graph. |
| M7 Ansible role: EtherCAT master host | M7.T1: role installs the cycle packages, deploys the runtime configuration with a bound master device (F3 regression), and reaches an active service. M7.T3: re-run M6.T1 per the dependency matrix. | None. |
| M8 Repository-local verification | M8.T1: extended `verify.all` passes with lintian, ansible-lint, and check-mode wired in. | M8.T2: the wiring itself is the permanent suite addition. |
| M9 VM acceptance | M9.T1: new harness phases pass first-try on a fresh Debian 13 VM with outcome parity against the p1-p9 source-build path. | M9.T4: standing harness amended with package-install and Ansible-provisioning phases. |
| M10 Documentation refresh | M10.T1: install, operation, and removal documents match implemented package and role behavior. | None. |
| M11 Release gate 1.0.0 | M11.T1: cycle batch re-run (see Release Gate). M11.T3: standing plan executed with M9.T4 amendments in effect. | M11.T2: full automated suites. |

## Dependency Re-Run Matrix

| Trigger | Re-runs | Shared surface |
| --- | --- | --- |
| M5 lands or later changes maintainer scripts | M3.T1, M4.T1 | `debian/` control files and maintainer scripts |
| M7 lands or later changes role layout | M6.T1 | Role layout, inventory, and variable model |
| Any post-M3 change to the DKMS fragment | M3.T1 | `dkms.conf` template and package fragment (F4 surface) |
| M8 or M9 findings force packaging or role changes | T1 of every milestone whose surface the change touches | Finding-specific |

## Release Gate

M11 executes in order before the release:

1. Cycle batch re-run: every milestone change-specific verification against
   the final tree, the first state where all changes coexist.
2. Full automated suites: the extended `verify.all` graph.
3. The standing plan executed identically on a fresh VM, with the M9.T4
   amendments in effect.

Gate evidence closes M11; the release sequence (merge, tag `1.0.0`, GitHub
release) follows the git-workflow release reference.

## Added During Cycle

- 2026-06-12 (M1): M5.T1 amended per the U3/U4 delivery-model decisions
  (`docs/delivery-model.md`). Configuration ownership is role-exclusive -
  the conffile-preservation clause is replaced by no-/etc-file shipping,
  a reference default outside /etc, and a fail-closed unit (F3).
  Group lifecycle moves to sysusers.d; purge retains system groups and
  audits report them as notes (F2/F5). M5.T1 also gains the EC-8
  boot-time interface bring-up check (cross-check finding RV1-R2-F2).
  Issue #5 body requires the same amendment before M5 executes.
- 2026-06-12 (M3): validation phase p11 (DKMS package install plus
  cross-kernel vermagic) lands as the M3.T2 permanent regression check,
  following the M2 charter-amendment precedent; the Standing Plan
  M9.T4 amendment stays scoped to the package-install and
  Ansible-provisioning phases. The re-run matrix row "Any post-M3
  change to the DKMS fragment" covers these concrete F4 surfaces:
  templates/dkms.conf.in, debian/ethercat-dkms.dkms,
  debian/debian-prebuild.sh.
- 2026-06-13 (M4): the M1 "no libethercat1 split" decision is reversed
  at its scheduled M2/M4 re-review - the conventional three-way split
  (libethercat1 / libethercat-dev / ethercat-tools) is adopted
  (precedent: libmodbus and 13 peers). Validation phase p12 is the
  M4.T1 vehicle. The cross-check (RV1-R2-F1) established that
  libethercat1 has NO in-cycle consumer - the ethercat CLI is
  self-contained and the host stack does not link it - so the library
  is delivered for external application authors only; there is no
  in-set ABI re-run dependency and the symbols file is deferred.
- 2026-06-13 (M5): host integration packaged into ethercat-host -
  systemd unit ethercat.service (enabled, not started), udev rule
  99-ethercat.rules, the ethercat group via sysusers.d, and ethercatctl.
  U3: no /etc/ethercat.conf shipped; the reference example lives at
  /usr/share/doc/ethercat-host/examples/ethercat.conf and the operator
  copy step is documented; fail-closed is inherent (ethercatctl exits 6
  without the config). Upstream SysV artifacts (init.d, sysconfig) are
  not shipped (Debian 13 systemd-only). ethercat-host Depends:
  ethercat-dkms, ethercat-tools. Validation phase p13 is the permanent
  M5.T2 regression asset.
