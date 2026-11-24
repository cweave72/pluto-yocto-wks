# Pluto SDR Yocto Workspace: Project Plan and Reference

This document has three functions:

- Project plan for the Pluto SDR Yocto workspace (sections 1, 3, 4, 8 to 14).
- Yocto how-to for the procedures in this workspace (sections 5 to 7, 15).
- Yocto reference for terms, syntax, and commands (sections 2, 16 to 18).

## Contents

- [1. Scope and goals](#1-scope-and-goals)
  - [1.1 End state](#11-end-state)
  - [1.2 Phase 1 target](#12-phase-1-target)
  - [1.3 Constraints](#13-constraints)
- [2. Yocto concepts](#2-yocto-concepts)
  - [2.1 Terms](#21-terms)
  - [2.2 Build flow](#22-build-flow)
  - [2.3 Configuration sequence](#23-configuration-sequence)
  - [2.4 Configuration responsibilities](#24-configuration-responsibilities)
- [3. Hardware summary](#3-hardware-summary)
  - [3.1 QSPI partition map](#31-qspi-partition-map)
  - [3.2 Boot sequence](#32-boot-sequence)
- [4. Yocto release and layers](#4-yocto-release-and-layers)
  - [4.1 Release](#41-release)
  - [4.2 Submodules](#42-submodules)
  - [4.3 Function of each layer](#43-function-of-each-layer)
  - [4.4 Excluded layers](#44-excluded-layers)
  - [4.5 Submodule procedures](#45-submodule-procedures)
- [5. Workspace layout](#5-workspace-layout)
  - [5.1 Build directory](#51-build-directory)
  - [5.2 `init_build.sh`](#52-init_buildsh)
  - [5.3 Templates and `TEMPLATECONF`](#53-templates-and-templateconf)
  - [5.4 Template `bblayers.conf`](#54-template-bblayersconf)
  - [5.5 Template `local.conf`](#55-template-localconf)
  - [5.6 Build caches](#56-build-caches)
- [6. `meta-pluto-platform` layer design](#6-meta-pluto-platform-layer-design)
  - [6.1 Make the layer](#61-make-the-layer)
  - [6.2 `layer.conf`](#62-layerconf)
  - [6.3 Machine: `pluto.conf`](#63-machine-plutoconf)
  - [6.4 Distro: `pluto.conf`](#64-distro-plutoconf)
  - [6.5 Kernel: `linux-pluto`](#65-kernel-linux-pluto)
  - [6.6 Kernel configuration procedure](#66-kernel-configuration-procedure)
  - [6.7 Out-of-tree module: `zynq-remoteproc`](#67-out-of-tree-module-zynq-remoteproc)
- [7. Firmware image (FIT)](#7-firmware-image-fit)
  - [7.1 FIT contents](#71-fit-contents)
  - [7.2 Device tree post-processing](#72-device-tree-post-processing)
  - [7.3 Output files](#73-output-files)
  - [7.4 Recipe outline](#74-recipe-outline)
  - [7.5 Image settings](#75-image-settings)
  - [7.6 Default bitstream](#76-default-bitstream)
- [8. AMP design](#8-amp-design)
  - [8.1 Remoteproc driver](#81-remoteproc-driver)
  - [8.2 Inter-processor interrupt](#82-inter-processor-interrupt)
  - [8.3 Kernel configuration fragments](#83-kernel-configuration-fragments)
  - [8.4 Device tree additions](#84-device-tree-additions)
  - [8.5 Zephyr requirements](#85-zephyr-requirements)
- [9. FPGA personality model](#9-fpga-personality-model)
  - [9.1 Responsibilities](#91-responsibilities)
  - [9.2 Personality contents](#92-personality-contents)
  - [9.3 Manifest: `personality.conf`](#93-manifest-personalityconf)
  - [9.4 Package format](#94-package-format)
  - [9.5 Host pack script: `pluto-personality-pack`](#95-host-pack-script-pluto-personality-pack)
  - [9.6 Target tool: `pluto-personality`](#96-target-tool-pluto-personality)
  - [9.7 Load and unload sequences](#97-load-and-unload-sequences)
  - [9.8 Storage](#98-storage)
  - [9.9 Platform contract](#99-platform-contract)
  - [9.10 Limits](#910-limits)
- [10. AD9363 ownership](#10-ad9363-ownership)
  - [10.1 Driver compatibility](#101-driver-compatibility)
  - [10.2 Personality types](#102-personality-types)
  - [10.3 SPI controller](#103-spi-controller)
  - [10.4 Control GPIOs](#104-control-gpios)
  - [10.5 Project PL peripheral for Zephyr I/O](#105-project-pl-peripheral-for-zephyr-io)
- [11. JTAG with the HS3](#11-jtag-with-the-hs3)
  - [11.1 Cable](#111-cable)
  - [11.2 Tools](#112-tools)
  - [11.3 Procedures](#113-procedures)
- [12. Phases](#12-phases)
- [13. Risks](#13-risks)
- [14. Target procedures](#14-target-procedures)
  - [14.1 DFU RAM boot (no QSPI write)](#141-dfu-ram-boot-no-qspi-write)
  - [14.2 QSPI write](#142-qspi-write)
  - [14.3 Serial console](#143-serial-console)
- [15. Development procedures](#15-development-procedures)
  - [15.1 First build](#151-first-build)
  - [15.2 Change a recipe from a different layer](#152-change-a-recipe-from-a-different-layer)
  - [15.3 Change source code with `devtool`](#153-change-source-code-with-devtool)
  - [15.4 Add a new recipe with `devtool`](#154-add-a-new-recipe-with-devtool)
  - [15.5 Add a package to the image](#155-add-a-package-to-the-image)
  - [15.6 Find a build failure](#156-find-a-build-failure)
  - [15.7 Find the value of a variable](#157-find-the-value-of-a-variable)
- [16. Metadata syntax reference](#16-metadata-syntax-reference)
  - [16.1 Assignment operators](#161-assignment-operators)
  - [16.2 Overrides](#162-overrides)
  - [16.3 Important recipe variables](#163-important-recipe-variables)
- [17. Command reference](#17-command-reference)
  - [17.1 Workspace](#171-workspace)
  - [17.2 BitBake](#172-bitbake)
  - [17.3 Layers and recipes](#173-layers-and-recipes)
  - [17.4 Devtool and package data](#174-devtool-and-package-data)
- [18. External references](#18-external-references)

## 1. Scope and goals

### 1.1 End state

- Linux runs on Zynq CPU0.
- Zephyr runs on Zynq CPU1.
- Linux loads FPGA personalities at runtime. A personality contains:
  - one FPGA bitstream
  - one Zephyr ELF (optional)
  - one Linux device tree overlay (optional)
  - one manifest
- Projects deliver personalities as `.ipk` packages. Linux installs them into
  the RAM root filesystem. A flash partition can store them through a reboot.
- This workspace is the platform for many projects. It supplies the personality
  infrastructure. It does not know the function of a personality.

The device tree overlay is for Linux only. Zephyr uses a device tree at build
time only. The Zephyr ELF contains the result. Zephyr does not export a device
tree file.

### 1.2 Phase 1 target

Yocto builds `core-image-minimal` for the ADALM-PLUTO. The image boots from
the stock Pluto bootloader.

### 1.3 Constraints

| Constraint                                             | Effect                                                                                             |
| ------------------------------------------------------ | -------------------------------------------------------------------------------------------------- |
| Projects build Zephyr outside Yocto with `west`.       | Yocto does not build Zephyr. The workspace does not use `meta-zephyr`.                             |
| Projects supply their own HDL.                         | The workspace does not use the ADI `hdl` repository or `meta-adi`.                                 |
| The project ports the Xilinx `zynq_remoteproc` driver. | A Yocto recipe builds the driver as an out-of-tree kernel module.                                  |
| The project uses a Digilent JTAG-HS3.                  | The JTAG procedures use `xsdb` or OpenOCD with the HS3.                                            |
| Projects deliver personalities as `.ipk` packages.     | Projects do not need Yocto. The platform supplies the pack script and the target tool (section 9). |

## 2. Yocto concepts

### 2.1 Terms

| Term                        | Definition                                                                                                                                               |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Yocto Project               | The umbrella project. It supplies the tools, the Poky distro, and the release schedule.                                                                  |
| OpenEmbedded-Core (oe-core) | The core metadata layer (`meta`). It contains the base recipes, classes, and machine tunes.                                                              |
| Poky distro                 | The Yocto Project reference distro (`DISTRO = "poky"`). The file is `meta-yocto/meta-poky/conf/distro/poky.conf`. The Pluto distro uses it as its base.  |
| poky repository             | A former git repository that combined `bitbake`, `openembedded-core`, and `meta-yocto`. It has no branch after Walnascar. The workspace does not use it. |
| BitBake                     | The task executor. It reads metadata, makes a task graph, and runs the tasks.                                                                            |
| Metadata                    | All recipes, classes, and configuration files. BitBake reads only metadata.                                                                              |
| Layer                       | A directory of metadata with a `conf/layer.conf` file. Layer names start with `meta-` by convention.                                                     |
| Recipe (`.bb`)              | Instructions to fetch, configure, compile, install, and package one software component.                                                                  |
| Append (`.bbappend`)        | A file that changes a recipe from a different layer. The file name must match the recipe name.                                                           |
| Class (`.bbclass`)          | Shared logic. A recipe uses a class with `inherit <class>`.                                                                                              |
| Include (`.inc`)            | A metadata fragment. A file uses it with `require` (error if missing) or `include` (no error).                                                           |
| Machine                     | The target hardware definition. `MACHINE` selects a file `conf/machine/<name>.conf`.                                                                     |
| Distro                      | The policy definition: init system, C library, features. `DISTRO` selects `conf/distro/<name>.conf`.                                                     |
| Image                       | A recipe that makes a root filesystem from a list of packages.                                                                                           |
| Task                        | One step of a recipe, for example `do_compile`. Each task has a log and a stamp.                                                                         |
| Package                     | An output of a recipe, for example an `.ipk` file. One recipe can make many packages.                                                                    |
| sstate                      | Shared state cache. It keeps task outputs. BitBake reuses them when the task inputs do not change.                                                       |
| Native recipe               | A recipe that builds a tool for the build host, for example `dtc-native`.                                                                                |
| `virtual/` provider         | An abstract name, for example `virtual/kernel`. `PREFERRED_PROVIDER` selects the recipe.                                                                 |
| Override                    | A suffix that makes a variable value conditional, for example `VAR:pluto`.                                                                               |
| Initramfs                   | A root filesystem in a `cpio` archive. The kernel loads it into RAM at boot.                                                                             |
| FIT                         | Flattened Image Tree. A u-boot container with kernel, device trees, ramdisk, and bitstream.                                                              |

### 2.2 Build flow

BitBake runs these tasks for a typical recipe, in this sequence:

| Task                   | Operation                                                                         |
| ---------------------- | --------------------------------------------------------------------------------- |
| `do_fetch`             | Downloads the source to `DL_DIR`.                                                 |
| `do_unpack`            | Extracts the source to the work directory `S`.                                    |
| `do_patch`             | Applies the patches in `SRC_URI`.                                                 |
| `do_configure`         | Runs the configure step, for example `cmake` or kernel `defconfig`.               |
| `do_compile`           | Runs the compile step.                                                            |
| `do_install`           | Copies the output to the staging directory `D`.                                   |
| `do_package`           | Splits the files in `D` into packages.                                            |
| `do_package_write_ipk` | Writes the package files.                                                         |
| `do_deploy`            | Copies files to `DEPLOY_DIR_IMAGE`. Only some classes and recipes have this task. |

An image recipe installs packages into a root filesystem (`do_rootfs`). Then it
writes the filesystem in each format in `IMAGE_FSTYPES` (`do_image_*`).

### 2.3 Configuration sequence

BitBake reads the configuration files in this sequence. A later file can
change a value from an earlier file.

1. `conf/bblayers.conf` in the build directory. This file lists the layers.
2. `conf/layer.conf` in each layer.
3. `conf/local.conf` in the build directory. This file sets `MACHINE` and `DISTRO`.
4. The machine file `conf/machine/${MACHINE}.conf`.
5. The distro file `conf/distro/${DISTRO}.conf`.
6. The global classes, for example `base.bbclass`.

BitBake then reads each recipe, its classes, and its appends.

### 2.4 Configuration responsibilities

Put each setting in one location only:

| Setting type | File in this workspace                                                                             | Contents                  | Example                                               |
| ------------ | -------------------------------------------------------------------------------------------------- | ------------------------- | ----------------------------------------------------- |
| Machine file | `meta-pluto-platform/conf/machine/pluto.conf`                                                      | Hardware settings         | CPU tune, console, kernel provider, device trees      |
| Distro file  | `meta-pluto-platform/conf/distro/pluto.conf`                                                       | Policy settings           | Init system, distro features, package format          |
| Image recipe | `meta-pluto-platform/recipes-core/images/core-image-minimal.bbappend`                              | Package selection         | `IMAGE_INSTALL`, `IMAGE_FSTYPES`                      |
| Recipe       | `meta-pluto-platform/recipes-<category>/<name>/<name>_<version>.bb`                                | Component build           | Source, patches, build commands                       |
| `local.conf` | `build/conf/local.conf` (template: `meta-pluto-platform/conf/templates/default/local.conf.sample`) | Local build host settings | `DL_DIR`, `SSTATE_DIR`, `TMPDIR`, `BB_NUMBER_THREADS` |

Do not put hardware or policy settings in `local.conf`. Other users and other
build hosts do not get `local.conf`.

## 3. Hardware summary

| Item           | Value                                                         |
| -------------- | ------------------------------------------------------------- |
| Board          | ADALM-PLUTO                                                   |
| SoC            | Zynq XC7Z010-1CLG225, dual Cortex-A9                          |
| RAM            | 512 MB DDR3L                                                  |
| RF transceiver | AD9363                                                        |
| Boot flash     | 32 MB QSPI                                                    |
| SD card        | None                                                          |
| USB            | OTG: DFU, mass storage, CDC-Ethernet (stock firmware)         |
| Console        | PS UART (`ttyPS0`, 115200) through the ADALM-UARTJTAG adapter |
| JTAG           | ADALM-UARTJTAG adapter, 10-pin ribbon                         |

### 3.1 QSPI partition map

Source: `arch/arm/boot/dts/xilinx/zynq-pluto-sdr.dtsi` in the ADI kernel.

| Label             | Offset     | Size   | Content                      |
| ----------------- | ---------- | ------ | ---------------------------- |
| `qspi-fsbl-uboot` | `0x000000` | 1 MB   | FSBL and u-boot (`boot.bin`) |
| `qspi-uboot-env`  | `0x100000` | 128 KB | u-boot environment           |
| `qspi-nvmfs`      | `0x120000` | 896 KB | Persistent configuration     |
| `qspi-linux`      | `0x200000` | 30 MB  | FIT firmware image           |

The platform Linux device tree divides `qspi-linux` into two partitions. The
stock u-boot does not change (section 9.8.2).

| Label          | Offset      | Size  | Content                             |
| -------------- | ----------- | ----- | ----------------------------------- |
| `qspi-linux`   | `0x200000`  | 14 MB | FIT firmware image                  |
| `qspi-persist` | `0x1000000` | 16 MB | Stored personality packages (JFFS2) |

### 3.2 Boot sequence

1. The Zynq BootROM reads `boot.bin` from `qspi-fsbl-uboot`.
2. The FSBL initializes the DDR and the clocks. Then it starts u-boot.
3. u-boot reads the environment from `qspi-uboot-env`.
4. u-boot reads `fit_size` bytes of the FIT image from `qspi-linux` into RAM.
5. u-boot loads the bitstream from the FIT image into the FPGA.
6. u-boot selects the device tree for the hardware revision.
7. u-boot starts the kernel with the initramfs.
8. The kernel mounts the initramfs as the root filesystem (`ramfs`).
9. `pluto-personality-restore` installs the stored personality packages.
10. `pluto-personality-restore` loads the default personality, if one is set.

Phases 1 to 3 change steps 4 to 10 only. Steps 1 to 3 use the stock files.

## 4. Yocto release and layers

### 4.1 Release

The workspace uses **Wrynose (Yocto 6.0 LTS)**. Support continues to April 2030.

Rationale:

- Scarthgap support stops in April 2028.
- The constraints remove `meta-adi` and `meta-zephyr`. These layers were the
  only reasons to stay on Scarthgap.
- The poky repository has no branch after Walnascar. The workspace uses
  `bitbake`, `openembedded-core`, and `meta-yocto` as separate submodules.

Each Yocto release has a code name. All layers in one build must support the
same code name. Each layer declares its supported code names in
`LAYERSERIES_COMPAT_<layer>`. BitBake stops with an error if a layer does not
declare the current code name.

Note: the term "Poky" has two meanings.

| Term            | Status on Wrynose                                        | Use in this workspace                                                                  |
| --------------- | -------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| poky repository | Discontinued. No branch after Walnascar.                 | Not used. Three submodules replace it: `bitbake`, `openembedded-core`, `meta-yocto`.   |
| Poky distro     | Active. In `meta-yocto/meta-poky/conf/distro/poky.conf`. | Used. `meta-pluto-platform/conf/distro/pluto.conf` requires `poky.conf` (section 6.4). |

In this document, "poky repository" means the former git repository. "Poky
distro" means the distro configuration.

### 4.2 Submodules

| Path                  | URL                                              | Branch    | Layers used           |
| --------------------- | ------------------------------------------------ | --------- | --------------------- |
| `bitbake`             | `https://git.openembedded.org/bitbake`           | `2.18`    | (tool)                |
| `openembedded-core`   | `https://git.openembedded.org/openembedded-core` | `wrynose` | `meta`                |
| `meta-yocto`          | `https://git.yoctoproject.org/meta-yocto`        | `wrynose` | `meta-poky`           |
| `meta-openembedded`   | `https://git.openembedded.org/meta-openembedded` | `wrynose` | `meta-oe`             |
| `meta-pluto-platform` | new repository (project-owned)                   | `main`    | `meta-pluto-platform` |

`openembedded-core` on Wrynose requires bitbake 2.18.0 or later.

### 4.3 Function of each layer

| Layer                 | Function in this workspace                                                                                             |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `meta` (oe-core)      | Base recipes: BusyBox, glibc, GCC, kernel classes, image classes, `u-boot-tools-native`, `dtc-native`. Cortex-A9 tune. |
| `meta-poky`           | The Poky distro file (`poky.conf`). `meta-pluto-platform` uses it as the base distro.                                  |
| `meta-oe`             | `libiio`, `dfu-util-native`, and other recipes that oe-core does not have.                                             |
| `meta-pluto-platform` | Machine, distro, kernel, FIT image, remoteproc module, personalities.                                                  |

The `meta-openembedded` repository contains many layers. The workspace uses
`meta-oe` only. Add other layers, for example `meta-python`, when a recipe needs them.

### 4.4 Excluded layers

| Layer                     | Reason                                                                                                                            |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `meta-adi`                | Supports Scarthgap only. Targets PetaLinux. Has no Pluto machine. Depends on the ADI HDL flow.                                    |
| `meta-zephyr`             | The project builds Zephyr outside Yocto.                                                                                          |
| `meta-xilinx`, `meta-arm` | Phases 1 to 3 do not need them. The `oe-core` Cortex-A9 tune is sufficient. Phase 4 can add them for `bootgen` and `u-boot-xlnx`. |

### 4.5 Submodule procedures

Clone the workspace and its submodules:

```
git clone <workspace-url> pluto-yocto-wks
cd pluto-yocto-wks
git submodule update --init
```

Add a submodule that follows a branch:

```
git submodule add -b wrynose https://git.openembedded.org/meta-openembedded meta-openembedded
```

Move all submodules to the newest commit on their branches:

```
git submodule update --remote
git add <submodule paths>
git commit
```

The workspace commit records one commit for each submodule. Commit after each
submodule update. This keeps the build reproducible.

## 5. Workspace layout

```
pluto-yocto-wks/
  .gitmodules
  .gitignore                build/, settings.cfg
  README.md
  init_build.sh
  docs/
    Yocto_overview.md
  bitbake/                  submodule
  openembedded-core/        submodule
  meta-yocto/               submodule
  meta-openembedded/        submodule
  meta-pluto-platform/      submodule (project-owned repository)
  scripts/
    dfu-ram-boot.sh         loads pluto.dfu into RAM through DFU
    flash-frm.sh            writes firmware to QSPI through DFU
    pluto-personality-pack  makes a personality .ipk (projects use it)
    jtag/                   xsdb TCL and OpenOCD configuration for the HS3
  build/                    generated, not in git
```

### 5.1 Build directory

`oe-init-build-env` makes the build directory and changes to it.

```
build/
  conf/
    local.conf            local build host settings
    bblayers.conf         layer list
    templateconf.cfg      path of the template that made conf/
  deploy/                 DEPLOY_DIR: build output
    images/pluto/         final images: zImage, DTBs, cpio.gz, pluto.itb
    ipk/                  package feed
  tmp/                    TMPDIR, if local.conf does not move it
    work/                 one work directory for each recipe
  downloads/              DL_DIR, if local.conf does not move it
  sstate-cache/           SSTATE_DIR, if local.conf does not move it
```

Put `DL_DIR` and `SSTATE_DIR` outside the workspace. Then many workspaces can
share them. `TMPDIR` must be on a local disk, not on a network share. Section
5.6 gives the cache locations for this workspace.

### 5.2 `init_build.sh`

The script combines the two reference scripts:

| Feature                                     | Source                            |
| ------------------------------------------- | --------------------------------- |
| `--init` option sets `TEMPLATECONF`         | `../beaglebone_lab/init_build.sh` |
| `--dl_dir`, `--sstate`, `--tmpdir` options  | `../cora_z7_yocto/init_build.sh`  |
| `settings.cfg` keeps the last option values | `../cora_z7_yocto/init_build.sh`  |

Changes from the reference scripts:

- The script sources `openembedded-core/oe-init-build-env`, not `poky/oe-init-build-env` (poky repository path).
- `TEMPLATECONF` points to `meta-pluto-platform/conf/templates/default`.
- The default cache locations come from section 5.6.1.
- The script does not set `BITBAKEDIR`. `oe-init-build-env` finds `openembedded-core/../bitbake` automatically.

You must source the script (`. init_build.sh`). Do not execute it. The script
changes the environment of the current shell.

Usage:

```
. init_build.sh [-h] [-p] [--init] [--dl_dir=PATH] [--sstate=PATH] [--tmpdir=PATH] [build_dir]
```

| Option             | Function                                                                                                |
| ------------------ | ------------------------------------------------------------------------------------------------------- |
| `-h`, `--help`     | Shows the usage.                                                                                        |
| `-p`, `--printenv` | Shows the settings. Does not start the environment.                                                     |
| `--init`           | Makes `build_dir/conf` from the template. The script also does this if `build_dir/conf` does not exist. |
| `--dl_dir=PATH`    | Sets `DL_DIR`.                                                                                          |
| `--sstate=PATH`    | Sets `SSTATE_DIR`.                                                                                      |
| `--tmpdir=PATH`    | Sets `TMPDIR`.                                                                                          |
| `build_dir`        | Build directory name in the workspace. Default: `build`.                                                |

`settings.cfg` keeps the last values as `PLUTO_DL_DIR`, `PLUTO_SSTATE_DIR`,
`PLUTO_TMPDIR`, and `PLUTO_BUILD_DIR`. The names have a prefix because a
`TMPDIR` variable in the shell changes the temporary directory of other tools.

Each run writes the three cache locations into `build_dir/conf/local.conf`.

### 5.3 Templates and `TEMPLATECONF`

`oe-init-build-env` makes `conf/` only when `conf/` does not exist. It copies
the files from the `TEMPLATECONF` directory:

| Template file          | Result in `build/conf/`                |
| ---------------------- | -------------------------------------- |
| `local.conf.sample`    | `local.conf`                           |
| `bblayers.conf.sample` | `bblayers.conf`                        |
| `conf-notes.txt`       | Text that the script shows after setup |

To apply a changed template, remove `build/conf/`. Then run `. init_build.sh --init`.

### 5.4 Template `bblayers.conf`

```
LCONF_VERSION = "7"

BBPATH = "${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \
  ##OEROOT##/meta \
  ##OEROOT##/../meta-yocto/meta-poky \
  ##OEROOT##/../meta-openembedded/meta-oe \
  ##OEROOT##/../meta-pluto-platform \
  "
```

`oe-init-build-env` replaces `##OEROOT##` with the absolute path of
`openembedded-core` when it makes `conf/bblayers.conf`. The paths are then
correct for any build directory location.

### 5.5 Template `local.conf`

Main lines of `meta-pluto-platform/conf/templates/default/local.conf.sample`:

```
MACHINE ??= "pluto"
DISTRO ?= "pluto"
DL_DIR = "${TOPDIR}/downloads"
SSTATE_DIR = "${TOPDIR}/sstate-cache"
TMPDIR = "${TOPDIR}/tmp"
DEPLOY_DIR = "${TOPDIR}/deploy"
BB_HASHSERVE_DB_DIR ?= "${HOME}/yocto/hashserv"
INHERIT += "rm_work"
BB_GENERATE_MIRROR_TARBALLS = "1"
PLUTO_BITSTREAM ?= ""
EXTRA_IMAGE_FEATURES ?= "allow-empty-password empty-root-password allow-root-login"
CONF_VERSION = "2"
```

| Line                             | Function                                                                             |
| -------------------------------- | ------------------------------------------------------------------------------------ |
| `DL_DIR`, `SSTATE_DIR`, `TMPDIR` | `init_build.sh` replaces these lines (section 5.6.1). Use `=`, not `?=` (see below). |
| `DEPLOY_DIR`                     | Puts the build output in `build/deploy/`. The default is `${TMPDIR}/deploy`.         |
| `PLUTO_BITSTREAM`                | Path of the platform default `.bit` file. `pluto-fit` needs it (section 7.6).        |
| `EXTRA_IMAGE_FEATURES`           | Development only: root login without a password. Remove for a release image.         |
| `CONF_VERSION`                   | Format version of `local.conf`. oe-core requires `2`.                                |

Use `=` for `TMPDIR` in `local.conf`. `bitbake.conf` sets `TMPDIR ?=
"${TOPDIR}/tmp"` before it reads `local.conf`. The first `?=` assignment
wins, so `TMPDIR ?=` in `local.conf` has no effect. The workspace uses `=` for
all three cache variables for the same result in all cases.

BitBake records the first `TMPDIR` in `${TMPDIR}/saved_tmpdir`. If `TMPDIR`
moves, the sanity check stops the build with "TMPDIR has changed location".
Then remove the old `TMPDIR` directory or move it back.

`DEPLOY_DIR` is not in the task signatures. If `DEPLOY_DIR` changes after a
build, BitBake does not run the deploy tasks again. The new `DEPLOY_DIR` stays
empty, and image tasks fail with "Couldn't find license information". Remove
`TMPDIR` after a `DEPLOY_DIR` change. The next build restores all tasks from
sstate.

The sstate manifests in `TMPDIR` record the files in `DEPLOY_DIR`. Always remove
`TMPDIR` and `DEPLOY_DIR` together. If `DEPLOY_DIR` keeps old files, setscene
tasks fail with "trying to install files into a shared area when those files
already exist".

#### Build host load limits

BitBake starts one task for each CPU. Each task runs `make -j <CPUs>`. On a
host with less than approximately 2 GB RAM for each CPU, these defaults fill
the RAM. The host then swaps and stops responding.

The template sets these limits for a 12-CPU, 12 GB host:

```
BB_NUMBER_THREADS = "4"
PARALLEL_MAKE = "-j 4 -l 12"
BB_TASK_NICE_LEVEL = "19"
BB_TASK_IONICE_LEVEL = "2.7"
BB_PRESSURE_MAX_MEMORY = "20000"
```

| Variable                 | Effect                                                                                                                                          |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `BB_NUMBER_THREADS`      | Maximum number of tasks at the same time.                                                                                                       |
| `PARALLEL_MAKE`          | `-j`: maximum compile jobs in each task. `-l`: `make` starts no new job while the load average is above the value.                              |
| `BB_TASK_NICE_LEVEL`     | CPU priority of the tasks. `19` is the lowest priority.                                                                                         |
| `BB_TASK_IONICE_LEVEL`   | Disk priority of the tasks, `class.priority`. `2.7` is the lowest best-effort priority.                                                         |
| `BB_PRESSURE_MAX_MEMORY` | BitBake starts no new task while the memory stall time is above the value, in microseconds per second (`/proc/pressure/memory`). `20000` is 2%. |

The maximum number of compile jobs is `BB_NUMBER_THREADS` multiplied by the
`PARALLEL_MAKE` `-j` value. Allow approximately 0.75 GB RAM for each compile job.

BitBake reads `local.conf` only when it starts. To change the limits during a
build:

1. Push Ctrl-C one time. BitBake completes the active tasks and stops.
2. Change `local.conf`.
3. Start the same `bitbake` command again. BitBake does not run the completed tasks again.

### 5.6 Build caches

#### 5.6.1 Locations

| Variable              | Default location          | Storage       | Content                                   |
| --------------------- | ------------------------- | ------------- | ----------------------------------------- |
| `DL_DIR`              | `~/netshare/yocto_dl`     | Network share | Source archives and git mirrors           |
| `SSTATE_DIR`          | `~/netshare/yocto_sstate` | Network share | Task output cache                         |
| `TMPDIR`              | `~/yocto/pluto_tmp`       | Local disk    | Work directories and sysroots             |
| `DEPLOY_DIR`          | `build/deploy`            | Local disk    | Images, package feed, and license data    |
| `BB_HASHSERVE_DB_DIR` | `~/yocto/hashserv`        | Local disk    | Hash equivalence database (`hashserv.db`) |

`init_build.sh` uses these values as defaults. The `--dl_dir`, `--sstate`, and
`--tmpdir` options change them.

#### 5.6.2 Storage rules

| Variable              | Network share | Reason                                                                                                                           |
| --------------------- | ------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `DL_DIR`              | Permitted     | BitBake writes with lock files and renames. Many builds can share it.                                                            |
| `SSTATE_DIR`          | Permitted     | BitBake writes each file with a temporary name, then renames it. Many builds can share it.                                       |
| `TMPDIR`              | Prohibited    | The oe-core sanity check stops the build if `TMPDIR` is on NFS. `TMPDIR` also needs hard links and fast small-file access.       |
| `BB_HASHSERVE_DB_DIR` | Prohibited    | The database is SQLite. SQLite locks do not operate reliably on network file systems. BitBake stops if this directory is on NFS. |

The oe-core and BitBake checks detect NFS only. They do not detect CIFS. Apply
the same rules to CIFS.

#### 5.6.3 Hash equivalence database

Hash equivalence lets BitBake reuse sstate when a changed input gives an
identical output. The Poky distro sets these values:

```
BB_SIGNATURE_HANDLER ?= "OEEquivHash"
BB_HASHSERVE ??= "auto"
```

With `BB_HASHSERVE = "auto"`, BitBake starts a local hash server. By default,
the server keeps its database in the build directory. A shared `SSTATE_DIR`
then gives less reuse, and BitBake shows a warning.

Set `BB_HASHSERVE_DB_DIR` to one local directory for all build directories on
this host. If many hosts share `SSTATE_DIR`, run a permanent `bitbake-hashserv`
server instead.

#### 5.6.4 Size control

| Setting                             | Location      | Effect                                                                                                                       |
| ----------------------------------- | ------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `INHERIT += "rm_work"`              | `local.conf`  | Removes the work directory of each recipe after a successful build. `TMPDIR` stays small.                                    |
| `RM_WORK_EXCLUDE += "<recipe>"`     | `local.conf`  | Keeps the work directory of a recipe that you debug.                                                                         |
| `BB_GIT_SHALLOW = "1"`              | Kernel recipe | Clones the kernel with a short history. The git mirror in `DL_DIR` is smaller.                                               |
| `BB_GENERATE_MIRROR_TARBALLS = "1"` | `local.conf`  | Writes each git mirror as one tarball in `DL_DIR`. One large file transfers faster than many small files on a network share. |

Remove old sstate files:

```
openembedded-core/scripts/sstate-cache-management.py --cache-dir=<SSTATE_DIR> --stamps-dir=<TMPDIR>/stamps
```

The script keeps the sstate files that the stamps in `TMPDIR` use. It removes
the other versions. Run it first with `--dry-run` to see the files that it removes.

#### 5.6.5 CIFS mount settings

The current mount of `//zbox.local/netshare` uses `vers=1.0,soft`. These
settings can cause build failures:

| Setting    | Problem                                                                                     | Recommended value                              |
| ---------- | ------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| `vers=1.0` | SMB1 is slow and has security defects.                                                      | `vers=3.0` or later, if the server supports it |
| `soft`     | A slow server response gives an I/O error. The error can leave a partial file in the cache. | `hard`                                         |

NFS is an alternative to CIFS for `DL_DIR` and `SSTATE_DIR`.

## 6. `meta-pluto-platform` layer design

```
meta-pluto-platform/
  conf/
    layer.conf                    LAYERSERIES_COMPAT = "wrynose"
    machine/pluto.conf
    distro/pluto.conf
    templates/default/
      local.conf.sample
      bblayers.conf.sample
      conf-notes.txt
  recipes-kernel/
    linux/
      linux-pluto_6.12.bb
      files/amp.cfg
      files/fpga-overlay.cfg
      files/persist.cfg
      files/zynq-pluto-sdr-amp.dts
    zynq-remoteproc/
      zynq-remoteproc.bb          inherit module
  recipes-bsp/
    pluto-bitstream/              default bitstream for the FIT image and /lib/firmware
    pluto-fit/                    makes pluto.itb, pluto.frm, pluto.dfu
  recipes-core/
    images/                       core-image-minimal settings
    pluto-personality/            target tool, boot script, runtime package
```

The `recipes-<category>/<name>/` structure is a convention. `layer.conf`
finds recipes through `BBFILES` patterns. Put patches and other files for a
recipe in a `files/` directory or a `<recipe-name>/` directory next to the
recipe. BitBake searches these directories for `file://` entries in `SRC_URI`.

### 6.1 Make the layer

Use `bitbake-layers` to make the skeleton:

```
bitbake-layers create-layer ../meta-pluto-platform
bitbake-layers add-layer ../meta-pluto-platform
```

### 6.2 `layer.conf`

```
BBPATH .= ":${LAYERDIR}"
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb ${LAYERDIR}/recipes-*/*/*.bbappend"
BBFILE_COLLECTIONS += "pluto-platform"
BBFILE_PATTERN_pluto-platform = "^${LAYERDIR}/"
BBFILE_PRIORITY_pluto-platform = "10"
LAYERDEPENDS_pluto-platform = "core openembedded-layer"
LAYERSERIES_COMPAT_pluto-platform = "wrynose"
```

| Variable                    | Function                                                                                                             |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `BBPATH`                    | Search path for `conf/` and `classes/` files.                                                                        |
| `BBFILES`                   | File patterns for recipes and appends.                                                                               |
| `BBFILE_COLLECTIONS`        | Layer name. Other layers use this name in `LAYERDEPENDS`.                                                            |
| `BBFILE_PRIORITY_<name>`    | Layer priority. If two layers have the same recipe, BitBake uses the recipe from the layer with the higher priority. |
| `LAYERDEPENDS_<name>`       | Layers that must also be in `bblayers.conf`.                                                                         |
| `LAYERSERIES_COMPAT_<name>` | Supported release code names.                                                                                        |

Names in this workspace:

| Item                           | Name                  |
| ------------------------------ | --------------------- |
| Layer repository and directory | `meta-pluto-platform` |
| Layer collection name          | `pluto-platform`      |
| Machine                        | `pluto`               |
| Distro                         | `pluto`               |

### 6.3 Machine: `pluto.conf`

| Variable                            | Value                                                                                     | Function                                                  |
| ----------------------------------- | ----------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| Tune                                | `require conf/machine/include/arm/armv7a/tune-cortexa9.inc`                               | Loads the compiler flags for the Cortex-A9.               |
| `DEFAULTTUNE`                       | `cortexa9thf-neon`                                                                        | Selects Thumb-2, hard float, and NEON.                    |
| `SERIAL_CONSOLES`                   | `115200;ttyPS0`                                                                           | Starts a login prompt on the PS UART.                     |
| `KERNEL_IMAGETYPE`                  | `zImage`                                                                                  | Kernel file format for the FIT image.                     |
| `KERNEL_EXTRA_ARGS`                 | `UIMAGE_LOADADDR=0x8000`                                                                  | Kernel load address.                                      |
| `PREFERRED_PROVIDER_virtual/kernel` | `linux-pluto`                                                                             | Selects the kernel recipe.                                |
| `KERNEL_DEVICETREE`                 | `xilinx/zynq-pluto-sdr.dtb xilinx/zynq-pluto-sdr-revb.dtb xilinx/zynq-pluto-sdr-revc.dtb` | Device trees that the kernel recipe compiles and deploys. |
| `MACHINE_FEATURES`                  | `usbgadget`                                                                               | Enables recipes that need USB gadget support.             |

### 6.4 Distro: `pluto.conf`

```
require conf/distro/poky.conf
DISTRO = "pluto"
DISTRO_NAME = "Pluto Linux"
INIT_MANAGER = "mdev-busybox"
```

- `require` loads the Poky distro from `meta-poky`. The Pluto distro changes only the settings that it needs.
- `INIT_MANAGER` selects the init system. `mdev-busybox` gives the smallest initramfs. `sysvinit` gives more standard init scripts.

### 6.5 Kernel: `linux-pluto`

| Item               | Value                                           |
| ------------------ | ----------------------------------------------- |
| Repository         | `https://github.com/analogdevicesinc/linux.git` |
| Branch             | `xlnx/release/v6.12.y-2026r1`                   |
| Base configuration | `KBUILD_DEFCONFIG = "zynq_pluto_defconfig"`     |
| Fragments          | `amp.cfg`, `fpga-overlay.cfg`, `persist.cfg`    |

The ADI kernel supplies these items:

- `zynq-pluto-sdr*.dts` device trees
- `zynq_pluto_defconfig`
- AD9361 family IIO drivers
- Zynq FPGA manager (`CONFIG_FPGA_MGR_ZYNQ_FPGA`)
- `of-fpga-region`
- OF configfs overlays (`drivers/of/configfs.c`)
- exported `zynq_cpun_start()` in `arch/arm/mach-zynq/platsmp.c`

Recipe: `recipes-kernel/linux/linux-pluto_6.12.bb` (main lines).

```
require recipes-kernel/linux/linux-yocto.inc

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

KBRANCH = "xlnx/release/v6.12.y-2026r1"
SRC_URI = "git://github.com/analogdevicesinc/linux.git;protocol=https;branch=${KBRANCH};name=machine"
SRCREV_machine = "b486fe824008ce25f56036b03d891063e6f233a8"
LINUX_VERSION = "6.12.77"
LINUX_VERSION_EXTENSION = ""
PV = "${LINUX_VERSION}+git"
BB_GIT_SHALLOW = "1"
KBUILD_DEFCONFIG = "zynq_pluto_defconfig"
KCONFIG_MODE = "alldefconfig"
COMPATIBLE_MACHINE = "^pluto$"
```

| Line                                           | Function                                                                                             |
| ---------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `require recipes-kernel/linux/linux-yocto.inc` | Adds the `kernel` and `kernel-yocto` classes. `kernel-yocto` merges `.cfg` fragments from `SRC_URI`. |
| `SRCREV_machine`                               | Fixes the source commit. Use a commit hash, not `${AUTOREV}`, for reproducible builds.               |
| `LINUX_VERSION`                                | Must agree with the kernel `Makefile` at `SRCREV_machine`. A version check stops the build if not.   |
| `LINUX_VERSION_EXTENSION = ""`                 | Removes the default `-yocto-standard` suffix from the kernel version.                                |
| `BB_GIT_SHALLOW`                               | Clones with a short history. The full ADI history is several GB.                                     |
| `KBUILD_DEFCONFIG`                             | Base configuration from the kernel tree.                                                             |
| `KCONFIG_MODE = "alldefconfig"`                | Expands the short `defconfig` file to a full configuration.                                          |
| `COMPATIBLE_MACHINE`                           | Stops BitBake from using this recipe for other machines.                                             |

To move to a newer kernel commit:

1. Get the commit: `git ls-remote https://github.com/analogdevicesinc/linux.git refs/heads/xlnx/release/v6.12.y-2026r1`.
2. Set `SRCREV_machine` to the commit.
3. Set `LINUX_VERSION` to `VERSION.PATCHLEVEL.SUBLEVEL` from the `Makefile` at the commit.
4. Run `bitbake linux-pluto`.

The fragments `amp.cfg`, `fpga-overlay.cfg`, and `persist.cfg` come in phases P2 and P3.

### 6.6 Kernel configuration procedure

1. Run `bitbake -c menuconfig virtual/kernel`.
2. Change the options and save.
3. Run `bitbake -c diffconfig virtual/kernel`.
4. Copy the output `fragment.cfg` to `recipes-kernel/linux/files/`.
5. Add the fragment to `SRC_URI`.
6. Run `bitbake -c kernel_configcheck -f virtual/kernel`.

The `kernel_configcheck` task shows the fragment options that the final
configuration does not contain. A missing dependency usually causes this.

### 6.7 Out-of-tree module: `zynq-remoteproc`

```
SUMMARY = "Zynq-7000 remoteproc driver for CPU1"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=<md5>"

inherit module

SRC_URI = "file://Makefile file://zynq_remoteproc.c file://COPYING"
S = "${UNPACKDIR}"

RPROVIDES:${PN} += "kernel-module-zynq-remoteproc"
KERNEL_MODULE_AUTOLOAD += "zynq_remoteproc"
```

| Line                     | Function                                                                 |
| ------------------------ | ------------------------------------------------------------------------ |
| `inherit module`         | Builds the module against the `virtual/kernel` source and configuration. |
| `S = "${UNPACKDIR}"`     | Uses the local files as the source directory.                            |
| `KERNEL_MODULE_AUTOLOAD` | Writes a `/etc/modules-load.d/` entry. The module loads at boot.         |

The `Makefile` must have a `modules_install` target. Copy the pattern from
`openembedded-core/meta-skeleton/recipes-kernel/hello-mod/`.

## 7. Firmware image (FIT)

The stock u-boot loads a FIT image from `qspi-linux`. The `pluto-fit` recipe
makes this image. The recipe copies the structure of
`plutosdr-fw/scripts/pluto.its`.

Oe-core has a `kernel-fitimage` class. The workspace does not use it. The
class cannot write the Pluto `magic` property or the `fpga@1` node in the
stock format.

### 7.1 FIT contents

| Node             | Content                            | Properties                                                                   |
| ---------------- | ---------------------------------- | ---------------------------------------------------------------------------- |
| root             | —                                  | `magic = "ITB PlutoSDR (ADALM-PLUTO)"`                                       |
| `fdt@1`          | `zynq-pluto-sdr.dtb`               | `type = "flat_dt"`                                                           |
| `fdt@2`          | `zynq-pluto-sdr-revb.dtb`          | `type = "flat_dt"`                                                           |
| `fdt@3`          | `zynq-pluto-sdr-revc.dtb`          | `type = "flat_dt"`                                                           |
| `fpga@1`         | `system_top.bit`                   | `type = "fpga"`, `compatible = "u-boot,zynq-fpga-enc"`, `load = <0xF000000>` |
| `linux_kernel@1` | `zImage`                           | `load = <0x8000>`, `entry = <0x8000>`                                        |
| `ramdisk@1`      | `core-image-minimal-pluto.cpio.gz` | `compression = "gzip"`                                                       |

Keep all `config@N` entries from `pluto.its`. The stock u-boot selects a
configuration from the hardware revision.

### 7.2 Device tree post-processing

The stock u-boot environment edits nodes under `/amba`. The ADI kernel names
this node `axi`. The recipe renames the node before it packs the DTB:

```
dtc -q -@ -I dtb -O dts in.dtb | sed 's/axi {/amba {/g' | dtc -q -@ -I dts -O dtb -o out.dtb
```

### 7.3 Output files

| File        | Make procedure                                                         |
| ----------- | ---------------------------------------------------------------------- |
| `pluto.itb` | `mkimage -f pluto.its pluto.itb`                                       |
| `pluto.frm` | Append the ASCII MD5 sum of `pluto.itb` to `pluto.itb`.                |
| `pluto.dfu` | `dfu-suffix -a pluto.dfu -v 0x0456 -p 0xb673` on a copy of `pluto.itb` |

### 7.4 Recipe outline

The `pluto-fit` recipe does not have source code. It collects the outputs of
other recipes from `DEPLOY_DIR_IMAGE`.

```
SUMMARY = "Pluto FIT firmware image"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit deploy nopackages

SRC_URI = "file://pluto.its"
PLUTO_FIT_MAX_SIZE = "0xE00000"
DEPENDS = "u-boot-tools-native dtc-native dfu-util-native"

do_compile[depends] += " \
    virtual/kernel:do_deploy \
    core-image-minimal:do_image_complete \
    pluto-bitstream:do_deploy \
    "

do_compile() {
    # Copy inputs, rename axi to amba, run mkimage, make .frm and .dfu.
    # Stop if pluto.itb is larger than PLUTO_FIT_MAX_SIZE.
}

do_deploy() {
    install -m 0644 ${B}/pluto.itb ${B}/pluto.frm ${B}/pluto.dfu ${DEPLOYDIR}/
}
addtask deploy after do_compile
```

| Line                  | Function                                                                                |
| --------------------- | --------------------------------------------------------------------------------------- |
| `inherit deploy`      | Adds `DEPLOYDIR`. `do_deploy` output goes to `DEPLOY_DIR_IMAGE` through sstate.         |
| `inherit nopackages`  | Removes the packaging tasks. The recipe makes no packages.                              |
| `DEPENDS`             | Build-time dependencies. BitBake builds them first and puts them in the recipe sysroot. |
| `do_compile[depends]` | Task-level dependencies. `do_compile` starts after these tasks complete.                |

`DEPENDS` makes the files of a recipe available in the sysroot. It does not
wait for `do_deploy` or `do_image_complete`. Use `[depends]` for these tasks.

### 7.5 Image settings

Put these settings in `meta-pluto-platform/recipes-core/images/core-image-minimal.bbappend`:

| Variable                            | Value                                  | Function                                                            |
| ----------------------------------- | -------------------------------------- | ------------------------------------------------------------------- |
| `IMAGE_FSTYPES`                     | `cpio.gz`                              | Writes the root filesystem as a compressed `cpio` archive.          |
| `INITRAMFS_IMAGE_BUNDLE`            | `0`                                    | Keeps the initramfs out of the kernel file. The FIT image holds it. |
| `IMAGE_FEATURES:append`             | `" package-management"`                | Installs `opkg` and its package database.                           |
| `IMAGE_INSTALL:append`              | `" pluto-personality pluto-bitstream"` | Adds the personality tool and the default bitstream file.           |
| `IMAGE_INSTALL:append`              | `" kernel-module-zynq-remoteproc"`     | Adds the remoteproc module (phase 3).                               |
| `ROOTFS_POSTPROCESS_COMMAND:append` | `" pluto_preinstall_ipks"`             | Installs `PLUTO_PREINSTALL_IPKS` (section 9.8.3).                   |

The FIT image must not exceed 14 MB, the size of the platform `qspi-linux`
partition (section 9.8.2).

### 7.6 Default bitstream

The `pluto-bitstream` recipe supplies the platform default bitstream. The
`PLUTO_BITSTREAM` variable in `local.conf` gives the path or URI. The recipe
puts the bitstream in two locations:

| Location                              | Use                                           |
| ------------------------------------- | --------------------------------------------- |
| FIT image (`fpga@1`)                  | u-boot loads it at boot.                      |
| `/lib/firmware/pluto-default.bit.bin` | The unload sequence loads it (section 9.7.2). |

The default bitstream must agree with the AXI peripherals in the Linux base
device tree. It must contain the platform contract items, for example the IPI
mailbox (section 9.9).

## 8. AMP design

### 8.1 Remoteproc driver

| Item              | Value                                                |
| ----------------- | ---------------------------------------------------- |
| Source repository | `https://github.com/Xilinx/linux-xlnx.git`           |
| Source branch     | `xlnx_rebase_v5.15_LTS`                              |
| Source file       | `drivers/remoteproc/zynq_remoteproc.c`               |
| Build             | `zynq-remoteproc.bb`, `inherit module` (section 6.7) |

Port items for kernel 6.12:

| Old API               | Action                                                     |
| --------------------- | ---------------------------------------------------------- |
| `cpu_down(1)`         | Replace with `remove_cpu(1)`.                              |
| `zynq_cpun_start()`   | No change. The ADI kernel exports this symbol.             |
| `set_ipi_handler()`   | Not in 6.12. Replace the IPI mechanism (see 8.2).          |
| `gic_raise_softirq()` | Not exported in 6.12. Replace the IPI mechanism (see 8.2). |
| `da_to_va` callback   | Update to the 6.12 signature (`is_iomem` argument).        |
| Carveout handling     | Update to the 6.12 `rproc_mem_entry` API.                  |

### 8.2 Inter-processor interrupt

The driver needs an interrupt in each direction between CPU0 and CPU1. Two
options exist:

| Option          | Description                                                                   | Kernel patch |
| --------------- | ----------------------------------------------------------------------------- | ------------ |
| A (recommended) | The project HDL adds a mailbox or doorbell register with PL-to-PS interrupts. | No           |
| B               | A kernel patch adds an SGI hook for the module.                               | Yes          |

### 8.3 Kernel configuration fragments

`amp.cfg` and `fpga-overlay.cfg`:

```
CONFIG_REMOTEPROC=y
CONFIG_RPMSG_VIRTIO=y
CONFIG_HOTPLUG_CPU=y
CONFIG_OF_OVERLAY=y
CONFIG_OF_CONFIGFS=y
CONFIG_FPGA_REGION=y
CONFIG_OF_FPGA_REGION=y
CONFIG_FPGA_BRIDGE=y
```

`persist.cfg`:

```
CONFIG_MTD=y
CONFIG_JFFS2_FS=y
```

`zynq_pluto_defconfig` already sets these options. `persist.cfg` keeps the
requirement explicit if the base configuration changes.

### 8.4 Device tree additions

- A `reserved-memory` node with `no-map` for the Zephyr image.
- A `reserved-memory` region for vrings and the shared buffer.
- A remoteproc node for the `zynq-remoteproc` module.
- An `fpga-region` node for personality overlays.
- The QSPI partitions `qspi-linux` (14 MB) and `qspi-persist` (16 MB) in place of the stock 30 MB `qspi-linux` (section 9.8.2).
- `spi0` with `status = "disabled"`. Section 10 gives the reason.
- No AD9363 node and no ADI AXI core nodes. The Linux RF overlay adds them (section 10).

During P1, use the stock ADI device tree without these changes. Apply the
changes in P2.

To add a device tree to the kernel recipe:

1. Put `zynq-pluto-sdr-amp.dts` in `recipes-kernel/linux/files/`.
2. Add `file://zynq-pluto-sdr-amp.dts` to `SRC_URI`.
3. Copy the file to `arch/arm/boot/dts/xilinx/` in a `do_configure:prepend` function.
4. Add `xilinx/zynq-pluto-sdr-amp.dtb` to `KERNEL_DEVICETREE`.

### 8.5 Zephyr requirements

The project builds Zephyr in a separate `west` workspace. The Zephyr board
`pluto_cpu1` must obey these rules:

- Link the image into the `reserved-memory` carve-out.
- Do not initialize the GIC distributor. Linux owns it.
- Do not initialize the PL310 L2 cache controller. Linux owns it.
- Do not initialize the SCU. Linux owns it.
- Supply a remoteproc resource table.
- Use RPMsg or a PL UART for the console. Linux owns the PS UART.
- Do not write the SLCR MIO pin configuration. The FSBL and Linux own it. Do not enable Zephyr `pinctrl` for PS pins.
- Do not access the PS GPIO controller. Do not enable the Zephyr PS GPIO driver (`xlnx,ps-gpio`). Linux owns the controller.
- Control FPGA I/O through project PL peripherals only (section 10.5).
- Enable only the PS peripherals that the personality gives to Zephyr. Set all other PS nodes to `status = "disabled"`.

The Zephyr board device tree describes the hardware at build time. The `west`
build compiles it into `zephyr.elf`. For each personality, these three items
must agree:

| Item                                  | Owner                   | Contents                               |
| ------------------------------------- | ----------------------- | -------------------------------------- |
| Bitstream                             | Project HDL flow        | PL peripherals and AXI addresses       |
| Linux overlay (`.dtbo`)               | Project HDL flow        | PL peripherals that Linux uses         |
| Zephyr board device tree and overlays | Zephyr `west` workspace | PL and PS peripherals that Zephyr uses |

A peripheral must appear in the Linux overlay or in the Zephyr device tree.
It must not appear in both.

## 9. FPGA personality model

### 9.1 Responsibilities

The platform supplies the personality infrastructure. The platform does not
know the function of a personality.

| Item              | Platform (this workspace)                                         | Project                                      |
| ----------------- | ----------------------------------------------------------------- | -------------------------------------------- |
| Bitstream         | Loads and unloads it.                                             | Makes it in the project HDL flow.            |
| Zephyr ELF        | Starts and stops CPU1 with it.                                    | Makes it with the `west` build.              |
| Linux overlay     | Applies and removes it.                                           | Makes it, if Linux uses a PL peripheral.     |
| Manifest          | Reads it. Checks the contract version.                            | Writes it.                                   |
| Package (`.ipk`)  | Supplies the pack script. Installs, removes, and stores packages. | Runs the pack script. Publishes the package. |
| Platform contract | Defines it. Publishes a version.                                  | Obeys it.                                    |

A project does not need a Yocto layer. A project needs a Yocto layer only to
add Linux software, for example Linux applications or Linux drivers.

### 9.2 Personality contents

| File               | Required | Source                                                            | Content                                                                                                                                               |
| ------------------ | -------- | ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `personality.conf` | Yes      | Project                                                           | Manifest (section 9.3).                                                                                                                               |
| `<name>.bit.bin`   | Yes      | Project HDL flow. Vivado `bootgen` converts `.bit` to `.bit.bin`. | Bitstream.                                                                                                                                            |
| `zephyr.elf`       | No       | Zephyr `west` build                                               | CPU1 program. It contains the compiled Zephyr hardware description. There is no separate Zephyr device tree file. Without an ELF, CPU1 stays stopped. |
| `<name>.dtbo`      | No       | Project HDL flow                                                  | Linux device tree overlay. Supply it only if Linux uses a PL peripheral or the PL clock rates change.                                                 |

The package installs the files to `/lib/firmware/personalities/<name>/`. The
FPGA manager and remoteproc read firmware paths relative to `/lib/firmware`.

### 9.3 Manifest: `personality.conf`

```
PERSONALITY_NAME="example"
PERSONALITY_VERSION="1.2.0"
PLATFORM_CONTRACT="1.0"
BITSTREAM="example.bit.bin"
ZEPHYR_ELF="zephyr.elf"
OVERLAY=""
RF_OWNER="zephyr"
```

| Field                 | Required | Value                                                                            |
| --------------------- | -------- | -------------------------------------------------------------------------------- |
| `PERSONALITY_NAME`    | Yes      | Lowercase letters, digits, and `-`. Must agree with the directory name.          |
| `PERSONALITY_VERSION` | Yes      | Version of the personality, for example `1.2.0`.                                 |
| `PLATFORM_CONTRACT`   | Yes      | Contract version that the personality obeys, `MAJOR.MINOR` (section 9.9).        |
| `BITSTREAM`           | Yes      | Bitstream file name.                                                             |
| `ZEPHYR_ELF`          | No       | Zephyr ELF file name. Empty: CPU1 stays stopped.                                 |
| `OVERLAY`             | No       | Linux overlay file name. Empty: the tool loads the bitstream without an overlay. |
| `RF_OWNER`            | Yes      | `linux`, `zephyr`, or `none` (section 10).                                       |

The target tool reads each line as a `KEY="value"` pair. It does not execute
the file.

The platform uses `RF_OWNER` only for checks. For example, the tool refuses
`RF_OWNER="linux"` without an overlay.

### 9.4 Package format

File name: `personality-<name>_<version>_all.ipk`

| Member           | Content                                                                 |
| ---------------- | ----------------------------------------------------------------------- |
| `debian-binary`  | The text `2.0`.                                                         |
| `control.tar.gz` | `control` file and the `prerm` script.                                  |
| `data.tar.gz`    | `./lib/firmware/personalities/<name>/` with the files from section 9.2. |

The `.ipk` file is an `ar` archive of these three members, in this sequence.

`control` file:

```
Package: personality-<name>
Version: <PERSONALITY_VERSION>
Architecture: all
Depends: pluto-personality-runtime (>= <MAJOR.MINOR>), pluto-personality-runtime (<< <MAJOR+1>.0)
Maintainer: <project contact>
Description: <one line>
```

| Field               | Function                                                                     |
| ------------------- | ---------------------------------------------------------------------------- |
| `Architecture: all` | The package contains data only. `opkg` installs it on any architecture.      |
| `Depends`           | `opkg` refuses the package if the platform contract version is out of range. |

`prerm` script: if the personality is active, it runs `pluto-personality unload`.

### 9.5 Host pack script: `pluto-personality-pack`

The platform supplies `scripts/pluto-personality-pack`. The script needs only
`ar`, `tar`, and `gzip` on the host. It does not need Yocto.

```
pluto-personality-pack --dir <input-dir> --out <output-dir>
```

`<input-dir>` contains `personality.conf` and the files that it names.

The script does these checks before it writes the package:

- All required manifest fields have values.
- All named files exist.
- `PLATFORM_CONTRACT` has the format `MAJOR.MINOR`.
- `RF_OWNER="linux"` has an `OVERLAY`.

Project procedure:

1. Build the bitstream in the project HDL flow.
2. Convert the bitstream: `bootgen -image <file>.bif -arch zynq -process_bitstream bin`.
3. Build `zephyr.elf` with `west build`.
4. Write `personality.conf`.
5. Run `pluto-personality-pack`.
6. Publish the `.ipk` file.

The `.bif` file for step 2 contains `all: { <name>.bit }`.

### 9.6 Target tool: `pluto-personality`

| Command                                            | Operation                                                                                |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `pluto-personality install [--persist] <file.ipk>` | Runs `opkg install`. With `--persist`, also copies the package to flash (section 9.8.2). |
| `pluto-personality remove <name>`                  | Unloads the personality if it is active. Runs `opkg remove personality-<name>`.          |
| `pluto-personality unpersist <name>`               | Removes the stored package from flash.                                                   |
| `pluto-personality default <name>`                 | Sets the personality that loads at boot. `none` clears it.                               |
| `pluto-personality list`                           | Shows installed, stored, active, and default personalities.                              |
| `pluto-personality load <name>`                    | Runs the load sequence (section 9.7.1).                                                  |
| `pluto-personality unload`                         | Runs the unload sequence (section 9.7.2).                                                |
| `pluto-personality status`                         | Shows the active personality, the remoteproc state, and the overlay state.               |

The `pluto-personality` recipe in `meta-pluto-platform` supplies the tool, the boot
script, and the `pluto-personality-runtime` package.

### 9.7 Load and unload sequences

#### 9.7.1 Load

1. Read `personality.conf`. Stop if the contract major version is different from the platform.
2. Run the unload sequence if a personality is active.
3. If `OVERLAY` has a value, apply the overlay through configfs. The overlay loads the bitstream.
4. If `OVERLAY` is empty, write `personalities/<name>/<BITSTREAM>` to `/sys/class/fpga_manager/fpga0/firmware`.
5. If `ZEPHYR_ELF` has a value, write `personalities/<name>/<ZEPHYR_ELF>` to `/sys/class/remoteproc/remoteproc0/firmware`.
6. If `ZEPHYR_ELF` has a value, write `start` to `/sys/class/remoteproc/remoteproc0/state`.
7. Write the name to `/run/pluto-personality/active`.

Overlay procedure for step 3:

```
mkdir /sys/kernel/config/device-tree/overlays/<name>
echo -n personalities/<name>/<OVERLAY> > /sys/kernel/config/device-tree/overlays/<name>/path
```

#### 9.7.2 Unload

1. If CPU1 runs, write `stop` to `/sys/class/remoteproc/remoteproc0/state`.
2. If an overlay is active, remove its configfs directory. Linux removes the overlay devices and unbinds their drivers.
3. Write `pluto-default.bit.bin` to `/sys/class/fpga_manager/fpga0/firmware`. The PL goes to the platform default state.
4. Remove `/run/pluto-personality/active`.

### 9.8 Storage

#### 9.8.1 RAM

The stock u-boot starts the kernel with `rootfstype=ramfs root=/dev/ram0 rw`.
The root filesystem is in RAM and is writable. `opkg install` writes the
personality files to RAM. A power cycle removes them.

#### 9.8.2 Flash persistence

The platform Linux device tree divides the stock `qspi-linux` partition into
two partitions (section 3.1):

| Label          | Offset      | Size  | Content                                 |
| -------------- | ----------- | ----- | --------------------------------------- |
| `qspi-linux`   | `0x200000`  | 14 MB | FIT firmware image                      |
| `qspi-persist` | `0x1000000` | 16 MB | JFFS2 filesystem, mounted at `/persist` |

The stock u-boot does not change. It reads only `fit_size` bytes from
`0x200000` (`include/configs/zynq_pluto_sdr.h`, ADI u-boot
`adi-xlnx-u-boot-2025.1-y`):

```
sf read ${fit_load_address} 0x200000 ${fit_size}
```

A DFU firmware write sets `fit_size` to the file size. If the FIT check fails,
u-boot reads the full 30 MB. This is slower but safe.

`/persist` contents:

| Path                           | Content                         |
| ------------------------------ | ------------------------------- |
| `/persist/personalities/*.ipk` | Stored packages                 |
| `/persist/default`             | Name of the default personality |

`qspi-persist` stores packages, not installed files. This decreases flash
writes. The `opkg` database in RAM always agrees with the installed files.

Boot script `pluto-personality-restore`:

1. Mount `qspi-persist` at `/persist`.
2. Run `opkg install` for each package in `/persist/personalities/`.
3. If `/persist/default` has a name, run `pluto-personality load <name>`.

Capacity: an XC7Z010 bitstream is approximately 2 MB. Vivado bitstream
compression and package compression make it smaller. 16 MB holds several
personalities.

Flash wear: QSPI NOR flash has a limited number of erase cycles per sector.
Only `install --persist`, `unpersist`, and `default` write to `qspi-persist`.

Do these checks on hardware before you use `qspi-persist`:

1. Write a firmware image with DFU. Make sure that the `qspi-persist` content does not change.
2. Boot a firmware image of almost 14 MB. Make sure that u-boot boots it.
3. Clear `fit_size` in the u-boot environment. Make sure that the fallback read boots.

The DFU entry `firmware.dfu` permits a 30 MB write. A file larger than 14 MB
overwrites `qspi-persist`. The `pluto-fit` recipe stops the build at 14 MB.
As an added safety, change the `firmware.dfu` size in the u-boot variable
`dfu_sf_info` to `0xE00000`.

#### 9.8.3 Preinstall at build time (optional)

A release image can contain personalities. Set the package paths in
`local.conf`:

```
PLUTO_PREINSTALL_IPKS = "/path/to/personality-a_1.0_all.ipk /path/to/personality-b_2.1_all.ipk"
```

The image recipe installs them into the root filesystem with `opkg-native`.
Preinstalled personalities use space in the 14 MB `qspi-linux` partition.

### 9.9 Platform contract

The platform contract is the set of fixed items that each project HDL design
and each Zephyr board must obey. The platform publishes it in
`docs/platform_contract.md` (phase P2).

| Item                  | Content                                                                                                              |
| --------------------- | -------------------------------------------------------------------------------------------------------------------- |
| CPU1 memory           | Address and size of the Zephyr carve-out.                                                                            |
| Shared memory         | Address and size of the vrings and the shared buffer.                                                                |
| IPI mailbox           | PL address and interrupt numbers (section 8.2).                                                                      |
| Resource table        | Format and location that the remoteproc driver expects.                                                              |
| PS7 configuration     | DDR, MIO, and default PL clock settings. The FSBL sets them. Each project HDL design must use the same PS7 settings. |
| Reserved PL addresses | AXI address ranges that the platform uses. Projects must not use them.                                               |
| AD9363 rules          | Section 10.                                                                                                          |
| Package format        | Sections 9.2 to 9.4.                                                                                                 |

Contract versions use `MAJOR.MINOR`:

| Change              | Version change | Effect on installed personalities         |
| ------------------- | -------------- | ----------------------------------------- |
| Compatible addition | `MINOR` + 1    | They continue to operate.                 |
| Incompatible change | `MAJOR` + 1    | `opkg` and the load sequence refuse them. |

The `pluto-personality-runtime` package version is the contract version.

### 9.10 Limits

- Only one personality is active at a time.
- The FSBL sets the PL clock rates at boot. A bitstream load does not change them. A personality that needs other rates must supply an overlay that sets `assigned-clock-rates`.
- A personality with `RF_OWNER="linux"` must use an overlay. Overlay removal unbinds the Linux AD9363 drivers.
- Installed personalities use RAM. The Zephyr carve-out also uses RAM.

## 10. AD9363 ownership

### 10.1 Driver compatibility

The AD9363 uses the AD9361 driver in Linux and in no-OS.

| Driver    | Location                         | AD9363 selection                                      |
| --------- | -------------------------------- | ----------------------------------------------------- |
| ADI Linux | `drivers/iio/adc/ad9361.c`       | `compatible = "adi,ad9363a"` (device ID `ID_AD9363A`) |
| ADI no-OS | `drivers/rf-transceiver/ad9361/` | `dev_sel = ID_AD9363A` in the init parameters         |

The drivers apply these AD9363 limits:

| Parameter                  | AD9363                    | AD9361                                  |
| -------------------------- | ------------------------- | --------------------------------------- |
| Carrier frequency          | 325 MHz to 3.8 GHz        | 70 MHz (RX) or 46.875 MHz (TX) to 6 GHz |
| RF bandwidth               | 20 MHz maximum            | 56 MHz maximum                          |
| Multi-chip synchronization | Not supported (`-ENODEV`) | Supported                               |

### 10.2 Personality types

Each personality gives the AD9363 to one processor:

| Type      | AD9363 driver                | HDL interface logic             | Linux overlay contents                          |
| --------- | ---------------------------- | ------------------------------- | ----------------------------------------------- |
| Linux RF  | ADI Linux `ad9361`           | ADI `axi_ad9361` and `axi_dmac` | `spi0` enabled, AD9363 node, ADI AXI core nodes |
| Zephyr RF | ADI no-OS `ad9361` in Zephyr | Project HDL                     | No AD9363 node. No `spi0` change.               |

The Linux RF type gives a generic build. The top-level FPGA design includes the
ADI interface logic. Linux tools, for example `libiio`, then operate the AD9363.

### 10.3 SPI controller

The AD9363 connects to the PS SPI controller `spi0`. Only one processor can
own `spi0`.

| Type      | `spi0` owner | Device tree setting                                                                                         |
| --------- | ------------ | ----------------------------------------------------------------------------------------------------------- |
| Linux RF  | Linux        | The Linux RF overlay sets `status = "okay"` and adds the AD9363 node.                                       |
| Zephyr RF | Zephyr       | The Linux base device tree keeps `status = "disabled"`. The Zephyr device tree enables its `cdns,spi` node. |

As an alternative, the project HDL can add an AXI Quad SPI controller for
Zephyr. Zephyr supports it (`xlnx,xps-spi-2.00.a`). The HDL then routes the
AD9363 SPI pins to the PL controller.

### 10.4 Control GPIOs

The stock Pluto device tree connects two AD9363 control pins to PS GPIO:

| AD9363 pin | Stock connection  |
| ---------- | ----------------- |
| `RESETB`   | `gpio0` 67 (EMIO) |
| `EN_AGC`   | `gpio0` 66 (EMIO) |

Linux owns the PS GPIO controller. Linux also uses it for other pins, for
example the USB PHY reset (`gpio0` 52).

Rule: Zephyr controls FPGA I/O through project PL peripherals only. Zephyr
does not access the PS GPIO controller. This rule applies to the AD9363
control pins and to all other FPGA I/O.

| Personality type | AD9363 control pin connection                                |
| ---------------- | ------------------------------------------------------------ |
| Linux RF         | PS GPIO EMIO, as in the stock design. Linux drives the pins. |
| Zephyr RF        | Project PL peripheral. Zephyr drives the pins.               |

### 10.5 Project PL peripheral for Zephyr I/O

The project HDL adds a PL peripheral for each group of FPGA I/O that Zephyr
controls. The peripheral can be a project design or a standard IP, for
example Xilinx `axi_gpio`. Zephyr owns these peripherals. Linux does not know
about them.

HDL procedure:

1. Add the peripheral to the block design.
2. Connect its AXI slave port to `M_AXI_GP0` through the AXI interconnect.
3. Give it an address that no other AXI peripheral uses.
4. In the top level, connect the peripheral outputs to the AD9363 `RESETB` and `EN_AGC` pins.
5. Remove the EMIO connections to these pins.
6. Add other control pins, for example `ENABLE` and `TXNRX`, if no-OS needs them.

Linux procedure:

1. Do not put the peripheral in the Linux overlay.
2. Do not put `reset-gpios` or `en_agc-gpios` for the AD9363 in the Linux device tree.

Zephyr procedure:

1. Add a node for the peripheral to the Zephyr board device tree.
2. Set `reg` to the address from HDL step 3.
3. Select the driver:
   - For a project peripheral, write a Zephyr driver and a device tree binding in the Zephyr application or a Zephyr module.
   - For Xilinx `axi_gpio`, use `compatible = "xlnx,xps-gpio-1.00.a"`. This enables `CONFIG_GPIO_XLNX_AXI` by default.
4. Connect the no-OS GPIO abstraction (`no_os_gpio`) to the Zephyr driver.
5. Give the no-OS init parameters the pin numbers for `RESETB` and `EN_AGC`.

Results:

- Zephyr and Linux share no GPIO registers.
- Linux can reset or reload the FPGA without a change to PS GPIO state.
- Each Zephyr driver initializes only its own PL peripheral.

## 11. JTAG with the HS3

### 11.1 Cable

| Side           | Connector                 |
| -------------- | ------------------------- |
| ADALM-UARTJTAG | 10-pin ribbon             |
| JTAG-HS3       | Xilinx 14-pin, 2 mm pitch |

Make an adapter cable. Check the pinout and VREF before you apply power.

### 11.2 Tools

| Tool                                | Use                                                                                              |
| ----------------------------------- | ------------------------------------------------------------------------------------------------ |
| Vivado/Vitis `hw_server` and `xsdb` | Native HS3 support. Bootloader recovery. CPU1 debug.                                             |
| OpenOCD                             | `interface/ftdi/digilent-hs3.cfg` and a Zynq-7000 target configuration. GDB access to each core. |

### 11.3 Procedures

- Bootloader recovery: use the pattern in `plutosdr-fw/scripts/run-xsdb.tcl`. Use `ps7_init.tcl` from the project HDL.
- CPU1 debug: attach to Cortex-A9 core 1. Linux continues on core 0.

## 12. Phases

| Phase                    | Work                                                                                                                                       | Exit criterion                                                                                                                                              |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| P0 Workspace             | Submodules, `init_build.sh`, `.gitignore`, `meta-pluto-platform` skeleton, templates                                                       | `bitbake-layers show-layers` lists all layers. `bitbake -p` parses without errors.                                                                          |
| P1 Linux                 | Machine, distro, kernel, device tree, initramfs, FIT                                                                                       | DFU RAM boot gives a login prompt on `ttyPS0`. QSPI boot from `pluto.frm` gives a login prompt.                                                             |
| P2 Personalities         | Platform default bitstream, `pluto-personality` tool and boot script, `pluto-personality-pack`, `qspi-persist`, platform contract document | A package made outside Yocto installs, loads, and unloads. A stored package loads after a power cycle. A DFU firmware write does not change `qspi-persist`. |
| P3 AMP                   | `zynq-remoteproc` module, Zephyr `pluto_cpu1` board, RPMsg                                                                                 | Zephyr starts on CPU1. Stop and restart operate correctly. RPMsg sends messages in both directions.                                                         |
| P4 Boot chain (optional) | FSBL or u-boot SPL from project HDL `ps7_init`, `boot.bin`, `meta-arm`, `meta-xilinx-core`                                                 | JTAG recovery operates. QSPI boot operates with the new `boot.bin`.                                                                                         |

During P1, use any bitstream that agrees with the device tree. Replace it with
the project HDL default bitstream in P2.

## 13. Risks

| Risk                                                                | Mitigation                                                                                      |
| ------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| GCC 15 on Wrynose causes warnings or errors in ADI 6.12 drivers.    | Add kernel patches in `meta-pluto-platform`. Disable `-Werror` for specific drivers.            |
| The IPI port fails or has bugs.                                     | Use option A (HDL mailbox).                                                                     |
| Zephyr changes GIC, L2, or SCU state and stops Linux.               | Apply the rules in 8.5. Test with JTAG attached.                                                |
| The FIT image exceeds 14 MB and overwrites `qspi-persist`.          | `pluto-fit` stops the build at 14 MB. Limit `firmware.dfu` to 14 MB in the u-boot environment.  |
| A DFU firmware write erases `qspi-persist`.                         | Do the hardware checks in section 9.8.2 before use.                                             |
| A project HDL design uses different PS7 settings.                   | The platform contract fixes the PS7 settings (section 9.9).                                     |
| A personality obeys a different contract version.                   | `opkg` dependencies and the load sequence refuse it.                                            |
| An incorrect HS3 adapter cable damages the board.                   | Check pinout and VREF before power-up.                                                          |
| Linux and Zephyr both access `spi0` or the AD9363 control pins.     | Apply the ownership rules in section 10.                                                        |
| Zephyr accesses the PS GPIO controller and changes Linux pins.      | Zephyr uses project PL peripherals only (section 10.5). Do not enable `xlnx,ps-gpio` in Zephyr. |
| The bitstream, Linux overlay, and Zephyr device tree do not agree.  | Review the three items for each personality (section 8.5).                                      |
| A QSPI write replaces the ADI firmware and its mass-storage update. | Keep the stock u-boot. Use u-boot DFU mode for recovery.                                        |

## 14. Target procedures

### 14.1 DFU RAM boot (no QSPI write)

1. On the stock firmware, run `device_reboot ram`.
2. On the host, run `dfu-util -a firmware.dfu -D pluto.dfu`.
3. On the host, run `dfu-util -e`.

### 14.2 QSPI write

1. Put the Pluto in DFU mode.
2. On the host, run `dfu-util -a firmware.dfu -D pluto.dfu`.
3. On the host, run `dfu-util -e`.

### 14.3 Serial console

```
picocom -b 115200 /dev/ttyUSB0
```

The CP2103 on the ADALM-UARTJTAG gives a `/dev/ttyUSB*` device on the host.

## 15. Development procedures

### 15.1 First build

1. Run `git submodule update --init`.
2. Run `. init_build.sh --init --dl_dir=<path> --sstate=<path> --tmpdir=<path>`.
3. Run `bitbake-layers show-layers`. Make sure that all layers show.
4. Run `bitbake core-image-minimal`.
5. Run `bitbake pluto-fit`.
6. Find the output in `build/deploy/images/pluto/`.

### 15.2 Change a recipe from a different layer

Do not edit files in a submodule layer. Use a `.bbappend` in `meta-pluto-platform`:

1. Find the recipe file: `bitbake-layers show-recipes <recipe>`.
2. Make `meta-pluto-platform/recipes-<category>/<recipe>/<recipe>_%.bbappend`.
3. Add the changes, for example `SRC_URI:append = " file://fix.patch"`.
4. Add `FILESEXTRAPATHS:prepend := "${THISDIR}/files:"` if the append adds files.
5. Run `bitbake-layers show-appends`. Make sure that the append shows.

The `%` in the file name matches all recipe versions.

### 15.3 Change source code with `devtool`

1. Run `devtool modify <recipe>`. Devtool clones the source into `build/workspace/sources/<recipe>/`.
2. Edit the source and make git commits.
3. Run `devtool build <recipe>`.
4. Run `devtool finish <recipe> ../meta-pluto-platform`. Devtool writes the commits as patches into the layer.

### 15.4 Add a new recipe with `devtool`

1. Run `devtool add <name> <source-url>`.
2. Edit the recipe in `build/workspace/recipes/<name>/`.
3. Run `devtool build <name>`.
4. Run `devtool finish <name> ../meta-pluto-platform`.

### 15.5 Add a package to the image

1. Find the package name: `oe-pkgdata-util find-path <file>` or `bitbake-layers show-recipes`.
2. Add `IMAGE_INSTALL:append = " <package>"` to the image `.bbappend`.
3. Run `bitbake core-image-minimal`.
4. Check the package list in `build/deploy/images/pluto/*.manifest`.

### 15.6 Find a build failure

1. Read the error message. It gives the recipe, the task, and the log path.
2. Read the log: `${TMPDIR}/work/<arch>/<recipe>/<version>/temp/log.do_<task>`.
3. Read the script that BitBake ran: `.../temp/run.do_<task>`.
4. Open a shell in the build environment of the recipe: `bitbake -c devshell <recipe>`.
5. Run the task again: `bitbake -c <task> -f <recipe>`.

### 15.7 Find the value of a variable

1. Run `bitbake-getvar -r <recipe> <VARIABLE>`.
2. For the full history of the variable, run `bitbake -e <recipe> | less`. Search for `# $<VARIABLE>`.

The history shows each file and line that sets or changes the variable.

## 16. Metadata syntax reference

### 16.1 Assignment operators

| Operator   | Example            | Result                                                                 |
| ---------- | ------------------ | ---------------------------------------------------------------------- |
| `=`        | `A = "x"`          | Sets the value. BitBake expands references when it uses the value.     |
| `?=`       | `A ?= "x"`         | Sets the value only if `A` has no value. The first `?=` wins.          |
| `??=`      | `A ??= "x"`        | Sets a default. Any other assignment replaces it. The last `??=` wins. |
| `:=`       | `A := "${B}"`      | Expands references immediately.                                        |
| `+=`       | `A += "x"`         | Appends with a space.                                                  |
| `=+`       | `A =+ "x"`         | Prepends with a space.                                                 |
| `.=`       | `A .= "x"`         | Appends without a space.                                               |
| `=.`       | `A =. "x"`         | Prepends without a space.                                              |
| `:append`  | `A:append = " x"`  | Appends after all other assignments. Include the space.                |
| `:prepend` | `A:prepend = "x "` | Prepends after all other assignments. Include the space.               |
| `:remove`  | `A:remove = "x"`   | Removes all `x` words after all other assignments.                     |

Use `:append` in `.bbappend` files and in `local.conf`. `+=` in these files can
fail because a later `?=` in the recipe does not apply.

### 16.2 Overrides

| Syntax                        | Meaning                                        |
| ----------------------------- | ---------------------------------------------- |
| `VAR:pluto = "x"`             | Use `x` when `MACHINE` is `pluto`.             |
| `VAR:append:pluto = " x"`     | Append `x` only when `MACHINE` is `pluto`.     |
| `VAR:${PN} = "x"`             | Use `x` for the main package of the recipe.    |
| `do_install:append() { ... }` | Add shell commands to the end of `do_install`. |

`OVERRIDES` lists the active override names. It includes the machine name,
the distro name, the architecture, and `class-target` or `class-native`.

### 16.3 Important recipe variables

| Variable             | Meaning                                                                 |
| -------------------- | ----------------------------------------------------------------------- |
| `PN`                 | Recipe name.                                                            |
| `PV`                 | Recipe version.                                                         |
| `PR`                 | Recipe revision.                                                        |
| `SRC_URI`            | Source and file list.                                                   |
| `SRCREV`             | Git commit for `git://` entries.                                        |
| `S`                  | Source directory.                                                       |
| `B`                  | Build directory.                                                        |
| `D`                  | Install destination directory.                                          |
| `WORKDIR`            | Work directory of the recipe.                                           |
| `UNPACKDIR`          | Directory where `do_unpack` puts the `SRC_URI` files.                   |
| `DEPENDS`            | Build-time dependencies (recipes).                                      |
| `RDEPENDS:${PN}`     | Runtime dependencies (packages).                                        |
| `FILES:${PN}`        | Files in the main package.                                              |
| `LICENSE`            | License identifier (SPDX).                                              |
| `LIC_FILES_CHKSUM`   | Checksums of license files. A change in a license file stops the build. |
| `COMPATIBLE_MACHINE` | Regular expression of supported machines.                               |
| `DEPLOY_DIR_IMAGE`   | Output directory for images, kernels, and DTBs.                         |

## 17. Command reference

### 17.1 Workspace

| Command                         | Use                                                     |
| ------------------------------- | ------------------------------------------------------- |
| `. init_build.sh --init`        | Make the build directory from the template.             |
| `. init_build.sh`               | Start the build environment.                            |
| `git submodule update --init`   | Get all submodules after a clone.                       |
| `git submodule update --remote` | Move submodules to the newest commit on their branches. |

### 17.2 BitBake

| Command                                | Use                                                         |
| -------------------------------------- | ----------------------------------------------------------- |
| `bitbake core-image-minimal`           | Build the initramfs.                                        |
| `bitbake pluto-fit`                    | Build `pluto.itb`, `pluto.frm`, `pluto.dfu`.                |
| `bitbake -p`                           | Parse all metadata. Do not build.                           |
| `bitbake -c listtasks <recipe>`        | Show the tasks of a recipe.                                 |
| `bitbake -c <task> <recipe>`           | Run one task and the tasks before it.                       |
| `bitbake -c <task> -f <recipe>`        | Run one task again. Ignore the stamp.                       |
| `bitbake -c devshell <recipe>`         | Open a shell in the build environment of a recipe.          |
| `bitbake -c menuconfig virtual/kernel` | Change the kernel configuration.                            |
| `bitbake -c diffconfig virtual/kernel` | Write a configuration fragment from the changes.            |
| `bitbake -c clean <recipe>`            | Remove the build output of a recipe.                        |
| `bitbake -c cleansstate <recipe>`      | Remove the build output and the sstate of a recipe.         |
| `bitbake -c cleanall <recipe>`         | Remove the build output, sstate, and downloads of a recipe. |
| `bitbake -e <recipe>`                  | Show the recipe environment with variable history.          |
| `bitbake -g <recipe>`                  | Write the dependency graph (`task-depends.dot`).            |
| `bitbake -k <recipe>`                  | Continue after a failure. Build as much as possible.        |
| `bitbake-getvar -r <recipe> <VAR>`     | Show one variable value for a recipe.                       |

### 17.3 Layers and recipes

| Command                              | Use                                                 |
| ------------------------------------ | --------------------------------------------------- |
| `bitbake-layers show-layers`         | Show the layers and priorities.                     |
| `bitbake-layers show-recipes <name>` | Show the recipe and its layer.                      |
| `bitbake-layers show-appends`        | Show the `.bbappend` files.                         |
| `bitbake-layers show-overlayed`      | Show recipes that a higher-priority layer replaces. |
| `bitbake-layers create-layer <path>` | Make a layer skeleton.                              |
| `bitbake-layers add-layer <path>`    | Add a layer to `bblayers.conf`.                     |

### 17.4 Devtool and package data

| Command                                | Use                                         |
| -------------------------------------- | ------------------------------------------- |
| `devtool modify <recipe>`              | Get the source of a recipe for editing.     |
| `devtool add <name> <url>`             | Make a new recipe from a source URL.        |
| `devtool build <recipe>`               | Build a recipe from the devtool workspace.  |
| `devtool finish <recipe> <layer>`      | Write patches and the recipe into a layer.  |
| `devtool reset <recipe>`               | Remove a recipe from the devtool workspace. |
| `oe-pkgdata-util find-path <file>`     | Find the package that installs a file.      |
| `oe-pkgdata-util list-pkg-files <pkg>` | Show the files in a package.                |

## 18. External references

| Document                    | URL                                                       |
| --------------------------- | --------------------------------------------------------- |
| Yocto Project documentation | `https://docs.yoctoproject.org`                           |
| BitBake user manual         | `https://docs.yoctoproject.org/bitbake/`                  |
| Yocto variables glossary    | `https://docs.yoctoproject.org/ref-manual/variables.html` |
| Kernel development manual   | `https://docs.yoctoproject.org/kernel-dev/index.html`     |
| Yocto release list          | `https://wiki.yoctoproject.org/wiki/Releases`             |
| ADI PlutoSDR firmware       | `https://github.com/analogdevicesinc/plutosdr-fw`         |
| ADI Linux kernel            | `https://github.com/analogdevicesinc/linux`               |
