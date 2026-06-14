# rt_host

Real-time host configuration for the Debian 13 EtherCAT environment
(release-1.0.0 cycle M6). The role reproduces the operational outcomes
of the wrapper `RULES_RT` target graph so that `make rt.status` and the
role agree on the RT host state.

## Scope

| RT row | Coverage |
| --- | --- |
| RT-1 RT kernel provisioning | `tasks/kernel.yml` (install kernel + headers, no boot-default change, D2) |
| RT-2 RT kernel selection | covered by the `make rt.status` oracle, not a role task (no set-default) |
| RT-3 realtime limits | `tasks/limits.yml` (group + `/etc/security/limits.d/99-realtime.conf`) |
| RT-4 boot parameters | `tasks/grub.yml` (backup-once, append-when-absent, `update-grub` handler) |
| RT-5 clock source | `tasks/clock.yml` (read-only report vs `tsc`) |
| RT-6 service policy | `tasks/services.yml` (mask the allowlist only) |
| RT-7 tuned | `tasks/tuned.yml` (report-only by default; opt-in apply) |
| RT-8 RT readiness | covered by the `make rt.status` oracle |

RT-9 (priority helper) and RT-10 (latency tooling) are dev-only and are
NOT part of this role.

## Policy notes

- The role never changes the GRUB boot default (D2). The RT kernel may
  still win the default menu entry through version ordering once
  installed; post-reboot confirmation is a hardware gate (Revision 1
  M16).
- tuned is report-only by default, matching the wrapper policy that
  tuned is never auto-engaged. Set `rt_host_tuned_apply: true` to apply the
  realtime profile.
- check-mode predicts the apply; the read-only report tasks (clock,
  tuned query) are `changed_when: false` and `check_mode: false`.

## Variables

See `defaults/main.yml`; the values mirror the active `configure/CONFIG_RT`
policy.
