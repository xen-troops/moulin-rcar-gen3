# Minimal Renesas RCAR Gen3 BSP with Xen support

This repository contains
[Moulin](https://moulin.readthedocs.io/en/latest/) project file along
with Yocto meta-layer to enable Xen support on Renesas RCAR Gen3
boards. It enables very minimal support - minimal BSP + Xen. Advanced
features like OP-TEE virtualization, GPU sharing, DRM, audio, camera
PV backends are not implemented.

# Building
## Requirements

1. Ubuntu 18.0+ or any other Linux distribution which is supported by Poky/OE
2. Development packages for Yocto. Refer to [Yocto
   manual](https://www.yoctoproject.org/docs/current/mega-manual/mega-manual.html#brief-build-system-packages).
3. You need `Moulin` installed in your PC. Recommended way is to
   install it for your user only: `pip3 install --user
   git+https://github.com/xen-troops/moulin`. Make sure that your
   `PATH` environment variable includes `${HOME}/.local/bin`.
4. Ninja build system: `sudo apt install ninja-build` on Ubuntu

## Building

Moulin is used to generate Ninja build file: `moulin
rcar-gen.yaml`. This project have provides a way to chose SoC and
machine using additional options. You can use check them with
`--help-config` command line option:

```
# moulin rcar-gen3.yaml --help-config
usage: moulin rcar-gen3.yaml [--SOC_FAMILY {r8a7795,r8a7796,r8a77965}]
                             [--MACHINE {salvator-x,h3ulcb,m3ulcb,m3nulcb}]

Config file description: Minimal Renesas RCAR Gen3 hardware BSP with Xen
hypervisor

optional arguments:
  --SOC_FAMILY {r8a7795,r8a7796,r8a77965}
                        RCAR Gen3-based SOC
  --MACHINE {salvator-x,h3ulcb,m3ulcb,m3nulcb}
                        RCAR Gen3 Board/Machine
```

Default SoC is `r8a7795` and machine is `salvator-x`.

To build for another SoC, like `r8a7796` use the following command:

`moulin rcar-gen3.yaml --SOC_FAMILY r8a7796`.

Moulin will generate `build.ninja` file. After that - run `ninja` to
build the images. This will fetch all required code and Renesas BSP.

## Running

This build will perform the same as described by Renesas on [eLinux
wiki](https://elinux.org/R-Car/Boards/Yocto-Gen3/v5.1.0). You can
refer to [Runing Yocto Images
section](https://elinux.org/R-Car/Boards/Yocto-Gen3/v5.1.0#Running_Yocto_images)
for more information. There are some differences, which are described below.

All build artifacts can be found at `yocto/build/tmp/deploy/images/${MACHINE}/`.

This build provides own DTB files with additional entries required by
Xen Hypervisor. They have `-xen` suffix in a
filename. `r8a77960-salvator-xs-xen.dtb` for example.

`bootargs` now are handled by Xen, not by Linux kernel. Xen will fail
to boot if U-Boot variable `bootargs` hold values for Linux
kernel. Either clear this variable, or set it to something like
`dom0_mem=2G console=dtuart dtuart=serial0 loglvl=info hmp-unsafe=true
xsm=flask`.

Linux bootargs are provided via DTB file. By default there is no root
device set, so kernel will not be able to boot userspace. You __need__
to edit kernel bootargs. You can decompile DTB file using `dtc -I dtb
-O dts $your.dtb -o $your.dts` command. Then find `xen,dom0-bootargs`
property in `chosen` node and make needed edits, as described in
eLinux Wiki. Compile DTB back using `dtc -O dtb -I dts -o $your.dtb
$your.dts`. Alternatively, you can edit DTB in U-Boot, using `fdt ...`
commands. Just bear in mind, that all changes will be lost after
reboot, so it is a good idea to write some sort of U-boot script.

You need to re-flash ARM TF images `bl2` and `bl3` because Xen needs
to be booted at EL2, while default ARM TF boots system at EL1. ARM TF
images found at `yocto/build/tmp/deploy/images/${MACHINE}/` already
have required changes. Just flash them. How to do this is described at
eLinux wiki on corresponding board page. For example, there are
instructions for [H3ULCB/Starter Kit
Premiere](https://elinux.org/R-Car/Boards/H3SK#Flashing_firmware).

U-Boot boot script also requires changes. Xen expects to find Linux
kernel at address `0x8a000000` and own xenpolicy file at
`0x8c000000`. Also, Xen Hypervisor image is loaded instead of Linux kernel
image. Minimal boot command for TFTP boot looks like this: `tftp
0x48080000 xen-uImage; tftp 0x48000000 r8a77960-salvator-x-xen.dtb;
tftp 0x8a000000 Image; tftp 0x8c000000 xenpolicy-4.16-unstable; bootm
0x48080000 - 0x4800000`.

After successful boot you can use `xl info` command to check that you
indeed are running Xen-based system:

```
xl info
host                   : salvator-x
release                : 5.10.0-yocto-standard
version                : #1 SMP PREEMPT Thu Jul 15 12:11:21 UTC 2021
machine                : aarch64
nr_cpus                : 6
max_cpu_id             : 5
nr_nodes               : 1
cores_per_socket       : 1
threads_per_core       : 1
cpu_mhz                : 8.320
hw_caps                : 00000000:00000000:00000000:00000000:00000000:00000000:00000000:00000000
virt_caps              : hvm hap
total_memory           : 8064
free_memory            : 6111
sharing_freed_memory   : 0
sharing_used_memory    : 0
outstanding_claims     : 0
free_cpus              : 0
xen_major              : 4
xen_minor              : 16
xen_extra              : -unstable
xen_version            : 4.16-unstable
xen_caps               : xen-3.0-aarch64 xen-3.0-armv7l
xen_scheduler          : credit2
xen_pagesize           : 4096
platform_params        : virt_start=0x200000
xen_changeset          : Mon Jun 14 19:09:19 2021 +0300 git:eaea64ac49-dirty
xen_commandline        : dom0_mem=1G console=dtuart dtuart=serial0 dom0_max_vcpus=4 bootscrub=1 loglvl=all xsm=dummy hmp-unsafe=true guest_loglvl=all console_timestamps=boot
cc_compiler            : aarch64-poky-linux-gcc (GCC) 9.3.0
cc_compile_by          : xen-4.16.0+gitA
cc_compile_domain      : poky
cc_compile_date        : 2021-06-14
build_id               : 032ff4097265402eae06c8f132f41da9944f12c4
xend_config_format     : 4
```
