# EtherCAT Master Configuration Environment

Configuration Environment for EtherLab IgH EtherCAT Master at https://gitlab.com/etherlab.org/ethercat

## History
The long history behind this repository is https://github.com/jeonghanlee/etherlabmaster. Most of the options are identical, but I redesign the old repository to finish the same jobs. However, only **Debian** is the supported platform.

## Packages

One should install relevant packages before trying to setup this repository. After this, one should reboot the system once in order to match the running kernel version and kernel header files. If one has its own customized kernel version, one should configure them properly. The following guide is only valid for a **Vanilla Kernel** of Debian Linux 12.

* Debian 12
 ```
 $ apt install -y linux-headers-$(uname -r) build-essential libtool automake tree dkms
 ```

##

```bash
$ make init
$ make autoconf
$ make build
$ make build.modules
```
