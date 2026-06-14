# Delivery Model (Release 1.0.0 Cycle M1)

## Purpose

This document is the release-1.0.0 cycle M1 deliverable (issue #1). It
assigns every wrapper capability a delivery destination - Debian
package, Ansible role, or development-only retention - with a testable
1.0.0 acceptance criterion per capability, and names the package set
and the role set. It is the companion of `docs/parity-matrix.md`: that
matrix is the closed Revision 1 M1 acceptance artifact and stays
unchanged; this document reuses its EC-1..EC-10 and RT-1..RT-10 row IDs
and adds the delivery dimension.

Repository structure decision (2026-06-11): single-repository
evolution - this repository owns the packaging, the roles, and the
retained development wrapper.

## Reading The Columns

- **Row** - the capability row ID from `docs/parity-matrix.md`.
- **Primary destination** - exactly one of `package:<name>`,
  `role:<name>`, `dev-only`. Dev-only rows are owned in 1.0.0 by cycle
  M8: the extended `verify.all` graph keeps the retained wrapper
  surface working.
- **Annotations** - secondary facts: `gate (Revision 1 M16 / R2-13)`
  marks rows whose final evidence is inherited hardware validation;
  `superseded-by-package` marks wrapper mechanisms a package makes
  redundant.
- **1.0.0 acceptance** - the owning cycle milestone (M2-M9) and its
  verification sub, or the named retention vehicle.

Fold-mapping note: the register's 13-row EtherCAT Functional Parity Map
folds into the 10 EC rows - DKMS configuration generation, module build
and install, and the DKMS autoinstall service fold into EC-5; systemd
service installation and udev permission rules fold into EC-9. The DKMS
autoinstall capability resolves to the Debian dkms framework via the
`ethercat-dkms` package. The Real-Time map is 1:1 with RT-1..RT-10.

## Package Set

Source package `ethercat`, built from the pinned upstream revision plus
`debian/` (see Source Traceability).

| Package | Contents | Key decisions |
| --- | --- | --- |
| `ethercat-dkms` | Kernel module source under /usr/src, static `dkms.conf` | dh_dkms convention; `PRE_BUILD` runs bootstrap (autoreconf + configure with recorded options); F4 overrides (`LINUX_SOURCE_DIR`, `abs_builddir`) retained; module set fixed generic-only per the register Profile Policy; dkms_tree relocation limitation recorded on EC-5. |
| `libethercat1` | Runtime shared library (SONAME `libethercat.so.1`) | M4 re-review adopted the conventional library split (precedent: libmodbus, net-snmp, libusb, openssl, and 10 peers all split runtime from -dev). shlibs dependency only; symbols file deferred (see `libethercat1.README.Debian`). |
| `libethercat-dev` | Headers (`ecrt.h`, `ectty.h`), `.so` symlink, static `.a`, pkg-config `.pc`, CMake config | `Depends: libethercat1 (= binary:Version)`. Acceptance: installs, `pkg-config --modversion libethercat` resolves, purges clean. |
| `ethercat-tools` | `ethercat` CLI and bash completion | CLI only and self-contained - it does not link `libethercat1` (verified: no `-lethercat`, no library dependency). The runtime library is a separate deliverable for application authors. Loader: standard multiarch path, so the wrapper ld.so.conf.d fragment is superseded-by-package. |
| `ethercat-host` | systemd unit (ethercat.service), udev rule (99-ethercat.rules), sysusers.d group, ethercatctl, reference config example outside /etc | Group lifecycle per U4 (see Group Lifecycle); ships NO `/etc/ethercat.conf` per U3 (see Configuration Ownership); unit enabled not started, fails closed when config absent. `Depends: ethercat-dkms, ethercat-tools` (ethercatctl uses the module and the CLI). Upstream SysV artifacts (init.d, sysconfig) are not shipped (Debian 13 is systemd-only). |

## Role Set

| Role | Scope | Key decisions |
| --- | --- | --- |
| `rt_host` | RULES_RT semantics: RT kernel and headers (RT-1), realtime group and limits (RT-3), GRUB parameters (RT-4), clock source report (RT-5), service policy (RT-6), tuned report (RT-7); RT-2 (kernel select) and RT-8 (readiness) are covered by the `make rt.status` oracle, not role tasks (cycle M6) | `ansible/roles/rt_host`, vars `rt_host_*` mirror the active CONFIG_RT policy; no GRUB boot-default change (D2); tuned report-only by default (opt-in apply); check-mode accurate; outcomes match `rt.status`. RT-9/RT-10 are dev-only, not in the role. |
| `ethercat_master` | Installs the cycle packages (ethercat-host, pulling dkms+tools), renders `/etc/ethercat.conf` from inventory variables as the sole /etc owner, enables and starts the service (cycle M7) | `ansible/roles/ethercat_master`, vars `ethercat_master_*`; a bound device is required (fail-closed, F3); device drivers are bare names (ethercatctl prepends ec_). Boot-time interface bring-up is package-path behavior (unit + ethercatctl + rendered UPDOWN); the role owns rendering correctness (EC-8). `ansible/playbooks/site.yml` composes rt_host + ethercat_master. |

## EtherCAT Destinations

| Row | Capability | Primary destination | Annotations | 1.0.0 acceptance |
| --- | --- | --- | --- | --- |
| EC-1 | Source checkout | package: ethercat (source) | wrapper clone/init/src.* retained dev-only (M8) | M2.T1: orig generated from the pinned revision; version string embeds the describe output; orig checksum recorded beside `SRC_HASH`. |
| EC-2 | Autoconf and build | package: ethercat (source) | wrapper build.* retained dev-only (M8) | M2.T1/T2: clean `dpkg-buildpackage` on Debian 13; build check joins the verification graph. |
| EC-3 | Device profile selection | package: ethercat-dkms | packaged set is generic-only; native-profile selection retained dev-only (M8) | M3.T1: installed DKMS state covers exactly the generic set; native profiles remain wrapper-built per the Profile Policy. |
| EC-4 | Patch handling | package: ethercat (source) | wrapper registry is the source of truth, retained dev-only (M8); archive class never enters the series | M2.T1: `debian/patches/series` is generated from the active classes; the orig tarball stays pristine. |
| EC-5 | Module lifecycle | package: ethercat-dkms | gate (Revision 1 M16: kernel-update rebuild on hardware); dkms_tree relocation requires conf regeneration; autoinstall via the dkms framework | M3.T1/T2: static `dkms.conf` with `PRE_BUILD` bootstrap and F4 overrides; cross-kernel build for a non-running kernel yields matching vermagic. |
| EC-6 | Userspace command | package: ethercat-tools | the shared library is split out as `libethercat1` plus `libethercat-dev` (see Package Set); wrapper loader fragment superseded-by-package | M4.T1: command resolves on PATH, libraries resolve via the loader, uninstall leaves no residue. Dev: `libethercat-dev` installs and `pkg-config --modversion libethercat` resolves. |
| EC-7 | `ethercat.conf` | role: ethercat_master | package: ethercat-host ships the reference default outside /etc and the fail-closed unit (U3) | M7.T1: role renders a bound master device; M5.T1 (amended): no /etc file shipped, unit fails closed absent the config. |
| EC-8 | NIC preparation | package: ethercat-host | role renders the UPDOWN entries (M7); wrapper iface.* retained dev-only (M8); gate (Revision 1 M16: reboot persistence) | M5.T1: the unit path (ethercatctl + rendered config) brings interfaces up at boot; M7.T1: rendering correctness. |
| EC-9 | systemd and udev | package: ethercat-host | group exists before udev rule load via sysusers.d (U4) | M5.T1: service and udev states report correctly; group precedes rule load. |
| EC-10 | Removal | package: maintainer scripts | removal inherently spans the whole binary set (libethercat1, libethercat-dev, ethercat-dkms, ethercat-tools, ethercat-host); wrapper remove.* retained dev-only (M8); purge retains system groups, audited as notes (U4) | M5.T1/T2: purge audits clean under the amended semantics; M9.T1: VERDICT=clean parity on the package path. |

## Real-Time Destinations

| Row | Capability | Primary destination | Annotations | 1.0.0 acceptance |
| --- | --- | --- | --- | --- |
| RT-1 | RT kernel provisioning | role: rt_host | | M6.T1: outcome parity with `rt.status`. |
| RT-2 | RT kernel selection | role: rt_host | gate (Revision 1 M16: post-reboot confirmation); verified via the rt.status oracle, not a dedicated role task (no set-default) | M6.T1: pre-reboot selection state parity. |
| RT-3 | Realtime limits | role: rt_host | | M6.T1: group and limits state parity. |
| RT-4 | Boot parameters | role: rt_host | gate (Revision 1 M16: reboot persistence) | M6.T1: GRUB parameter and backup state parity. |
| RT-5 | Clock source | role: rt_host | | M6.T1: clock source report parity. |
| RT-6 | Service policy | role: rt_host | | M6.T1: allowlisted service policy parity. |
| RT-7 | tuned support | role: rt_host | | M6.T1: available/selected/active report parity. |
| RT-8 | RT readiness | role: rt_host | gate (Revision 1 M16: post-reboot RT evidence); verified via the rt.status oracle, not a dedicated role task | M6.T1: consolidated readiness report parity. |
| RT-9 | Priority helper | dev-only | interactive-operational tool | M8.T1: retained under the extended verify graph. |
| RT-10 | Latency evidence | dev-only | archive-classified tooling | M8.T1: retained under the extended verify graph. |

## Dev-Only Retention List

The retained wrapper surface stays operational for development and CI;
cycle M8 extends `verify.all` across it. Retained groups:

- Capability halves named above: EC-3 native-profile selection, EC-4
  patch registry, wrapper iface.* (EC-8), wrapper remove.* (EC-10),
  RT-9 priority helper, RT-10 latency tooling, and the wrapper source
  and build target groups (EC-1, EC-2).
- The wrapper mechanisms behind every package-owned row likewise remain
  dev-only retained: dkms.* and module.* (EC-5), command.* and loader.*
  (EC-6), runtime.* (EC-7), systemd.*, sd_*, and udev.* (EC-9).
- Structural groups: `doctor` and the scoped doctors (grub, install,
  kernel, network, package, rtdiag, systemd, tools); the guard macros
  (`guard-path`, `require-root` - macro-based, exercised through
  root-affecting targets); `verify.all`, `verify.dryrun`,
  `verify.doctor-overrides`, `verify.idempotence`,
  `verify.reproducibility`, `verify.residue`.
- Utility surface: `help`, `targets`, `env`, `vars`, `print-%`,
  `PRINT.%`, `ls.%`, `tree.%`, `clean`, `distclean`, `default`,
  `FORCE` (internal helper targets included for sweep completeness).

## Configuration Ownership (U3)

Decision (2026-06-12): role-exclusive /etc ownership, following the
established Debian practice for services without a safe default
configuration (wireguard-tools, openvpn, wpa_supplicant fail-closed
unit conditions, slurm-wlm, ceph orchestration-owned configuration):

- `ethercat-host` ships no `/etc/ethercat.conf`. The reference default
  is shipped as `/usr/share/doc/ethercat-host/examples/ethercat.conf`
  (M5).
- The `ethercat_master` role is the sole writer of the /etc
  configuration; package upgrades cannot touch it and no dpkg conffile
  prompt can occur.
- The unit fails closed when the configuration is absent: ethercatctl
  exits non-zero when `/etc/ethercat.conf` is unreadable, so
  `systemctl start ethercat` fails rather than starting an empty
  master (closes the F3 class).
- Package-only hosts copy the reference example to `/etc/ethercat.conf`
  per the documented operator step in `ethercat-host.README.Debian`.
- Testplan M5.T1 is amended accordingly (Added During Cycle,
  2026-06-12).

## Group Lifecycle (U4)

Decision (2026-06-12): the `ethercat` system group is declared by a
sysusers.d fragment in `ethercat-host`. Creation happens at package
install and at every boot before udev rule processing, which closes the
F2 ordering class structurally. Purge retains system groups per Debian
convention (GID reuse hazard); audits - wrapper `remove.audit` on the
package path and the M9 validation harness - report package-managed
groups as notes outside the verdict, consistent with the F5
operator-package precedent.

## Patch Policy

The wrapper patch registry (`patch/<class>/`) is the single source of
truth. `debian/patches/series` is generated from the active classes
(site, compatibility, hardware) at source-package build; the archive
class never enters the series; no patch applies outside the package
build or the wrapper. The orig tarball stays pristine.

## Source Traceability

The orig tarball is generated from the pinned upstream revision
(`SRC_HASH` in `configure/RELEASE`); its version string embeds the git
describe output and a recorded checksum of the generated orig
accompanies `SRC_HASH` (`ORIG_SHA256` binds the uncompressed tar
stream). The orig excludes the doxygen-layout submodule by git-archive
construction; its content is documentation-styling only and does not
affect the build. The concrete mechanism lands in M2. M2 entry
verification: confirm whether the pinned upstream revision ships its
own `debian/` directory; if it does, this repository's packaging
replaces it (recorded replace-vs-reuse decision).

## Lintian Pass Policy

The M8 lintian gate is `lintian --fail-on error` over the built
.changes (source plus all binaries), wired into `verify.all` as
`verify.lintian` (SKIP-gated; real on the VM). The gate passes when no
error-level tag remains except those carried by a recorded per-package
`debian/<pkg>.lintian-overrides` entry with a one-line justification; a
genuine packaging defect is fixed, not overridden. The M1 no-split
override class is retired: the M4 split makes the runtime package name
match the SONAME, so no package-name override is needed. The
`no-symbols-control-file` tag on `libethercat1` is info-level
(non-fatal under `--fail-on error`), so it needs no override (symbols
file deferred, see `libethercat1.README.Debian`).

## M8 Lintian Override Set

Established by the first real lintian run (M8 phase p16,
`lintian --fail-on error` on the .changes):

- `ethercat source: missing-build-dependency-for-dh-addon installsysusers`
  (`debian/source/lintian-overrides`) - the installsysusers dh addon
  ships in debhelper and is enabled via `--with installsysusers` on
  compat 13; debhelper-compat (= 13) pulls it, so the explicit
  libdebhelper-perl build-dep lintian asks for is redundant.

One genuine defect was fixed rather than overridden:
`libethercat-dev: description-contains-invalid-control-statement` - an
extended-description line began with `.so`; the description was
reworded so no line starts with a period.

## Coverage Cross-Check (M1.T1)

Sweep basis: the full target listing from `configure/RULES_*`
(2026-06-12, 118 targets). Every group maps to a destination row or a
named retention entry:

| Target group | Coverage |
| --- | --- |
| clone, init, deinit, exist, update, src.verify, src.revision, src_init, src_version*, src_autoconf, GIT_VERSION, SRC_VARIABLES | EC-1 |
| autoconf, build, build.baseline, build.install, build.uninstall, build.modules, clean.modules, host.debian13, install, uninstall | EC-2 (module halves EC-5) |
| profile.check, profile.matrix | EC-3 |
| patch.status, patch.apply, patch.reverse, patch.revert, patch.make | EC-4 |
| dkms.conf, module.lifecycle, add.dkms, build.dkms, install.dkms, uninstall.dkms, remove.dkms, install.modules, uninstall.modules | EC-5 |
| command.install, command.audit, loader.render, loader.install, loader.audit | EC-6 |
| runtime.generate, runtime.lint, runtime.config.show, runtime.install, runtime.status | EC-7 (status half EC-9) |
| iface.prepare, iface.unprepare, iface.status | EC-8 |
| systemd.*, sd_clean, sd_disable, sd_stop, udev.* | EC-9 |
| remove.*, src_install, src_uninstall | EC-10 |
| rt.kernel.provision (RT-1), rt.kernel.select (RT-2), rt.limits.* (RT-3), rt.grub.* (RT-4), rt.clock.status (RT-5), rt.service.* (RT-6), rt.tuned.status (RT-7), rt.status (RT-8) | RT-1..RT-8 |
| rt.priority.show, rt.priority.apply | RT-9 |
| rt.latency.classify, rt.latency.examples | RT-10 |
| doctor, doctor.*, verify.* | retention (structural) |
| help, targets, env, vars, print-%, PRINT.%, ls.%, tree.%, clean, distclean, default, FORCE | retention (utility) |

Zero unmapped groups. Bidirectional check: every cycle milestone M2-M9
is referenced by at least one acceptance cell - M2 (EC-1, EC-2, EC-4),
M3 (EC-3, EC-5), M4 (EC-6), M5 (EC-7..EC-10), M6 (RT-1..RT-8), M7
(EC-7, EC-8), M8 (retention vehicle), M9 (EC-10 parity). Every EC/RT
row carries exactly one primary destination from the three M1.T1
categories.
