# ethercat_master

End-to-end EtherCAT master host provisioning for the Debian 13
environment (release-1.0.0 cycle M7): install the cycle packages,
render `/etc/ethercat.conf` from inventory variables, and bring the
master service to active.

## What it does

1. Asserts `ethercat_master_device` is set (fail-closed, F3 - the
   master never starts unbound).
2. Installs `ethercat-host` (which pulls `ethercat-dkms` and
   `ethercat-tools` via Depends).
3. Renders `/etc/ethercat.conf` (the role is the sole /etc owner, U3)
   with `MASTER0_DEVICE`, `MASTER0_BACKUP`, `DEVICE_MODULES`,
   `UPDOWN_INTERFACES`; restarts the service on change.
4. Enables and starts `ethercat.service`.

## Boundaries

- The package (`ethercat-host`) owns the systemd unit and boot-time
  interface bring-up (via `ethercatctl` + the rendered config, EC-8);
  this role owns the configuration content (EC-7) and service state.
- Device drivers are BARE names (`generic`): `ethercatctl` prepends
  `ec_` at load time.
- `ethercat_master_updown` must be interface NAMES, not a MAC.

## Variables

See `defaults/main.yml`. `ethercat_master_device` is required.

## Composition

`ansible/playbooks/site.yml` applies `rt_host` then `ethercat_master`
to provision a complete real-time EtherCAT master host.
