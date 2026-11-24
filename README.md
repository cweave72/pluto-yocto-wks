# Pluto SDR Yocto Workspace

Yocto workspace for the ADALM-PLUTO (Zynq XC7Z010). The workspace builds
`core-image-minimal` and the Pluto FIT firmware image.

Refer to [docs/Yocto_overview.md](docs/Yocto_overview.md) for the workspace
layout, layers, and phases.

## Quick start

Clone the workspace and its submodules:

```
git clone <workspace-url> pluto-yocto-wks
cd pluto-yocto-wks
git submodule update --init
```

Make the build directory (first time only):

```
. init_build.sh --init --dl_dir=<path> --sstate=<path> --tmpdir=<local path>
```

Start the build environment (each new shell):

```
. init_build.sh
```

Build the initramfs:

```
bitbake core-image-minimal
```

Build the FIT firmware image. Set `PLUTO_BITSTREAM` in `build/conf/local.conf`
to the path of a `.bit` file first:

```
bitbake pluto-fit
```

Output: `<TMPDIR>/deploy/images/pluto/`

| File        | Use                                      |
| ----------- | ---------------------------------------- |
| `pluto.dfu` | DFU write or DFU RAM boot                |
| `pluto.frm` | Mass-storage update (stock ADI firmware) |
| `pluto.itb` | FIT image                                |
