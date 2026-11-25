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

Build the FIT firmware image. The FIT image contains the ADI stock bitstream.
To use a different bitstream, set `PLUTO_BITSTREAM` in `build/conf/local.conf`
to the path of a `.bit` file:

```
bitbake pluto-fit
```

Output: `build/deploy/images/pluto/`

| File        | Use                                      |
| ----------- | ---------------------------------------- |
| `pluto.dfu` | DFU write or DFU RAM boot                |
| `pluto.frm` | Mass-storage update (stock ADI firmware) |
| `pluto.itb` | FIT image                                |

## JTAG RAM boot

Boot `core-image-minimal` from RAM with the JTAG-HS3 and the ADALM-UARTJTAG.
The procedure writes nothing to QSPI flash.

```
bitbake core-image-minimal
scripts/jtag/pluto-jtag-boot.sh
```

`bitbake core-image-minimal` also deploys the ADI JTAG bootstrap files
(`ps7_init.tcl`, `system_top.bit`, `u-boot.elf`) to
`build/deploy/images/pluto/adi-jtag-bootstrap/`. The script uses the Rev.B
device tree. Give `--rev=a` or `--rev=c` for a different hardware revision.

Open the serial console before the boot. The CP2104 on the ADALM-UARTJTAG
gives the console port. The JTAG-HS3 also gives a `/dev/ttyUSB*` port.
Select the CP2104 with its `/dev/serial/by-id/` name:

```
ls /dev/serial/by-id/
minicom -D /dev/serial/by-id/usb-Silicon_Labs_CP2104_USB_to_UART_Bridge_Controller_*-if00-port0 -b 115200
```

| Item              | Value                                                                                 |
| ----------------- | ------------------------------------------------------------------------------------- |
| Line settings     | 115200 8N1                                                                            |
| Flow control      | None. Push `Ctrl-A O`, select "Serial port setup", set "Hardware Flow Control" to No. |
| Save the settings | `Ctrl-A O`, then "Save setup as dfl"                                                  |
| Exit minicom      | `Ctrl-A X`                                                                            |

Your user must be in the `dialout` group to open the port.

Log in as `root`. The image has no password.
See `docs/Yocto_overview.md` section 14.4.

## SSH over USB

The image configures the Pluto USB data port as a USB network device.
Connect it to the host, then boot the Pluto.

| Side  | Address                              |
| ----- | ------------------------------------ |
| Pluto | `192.168.2.1`                        |
| Host  | `192.168.2.10` (DHCP from the Pluto) |

```
ssh root@192.168.2.1
```

The host keys change at each boot. See `docs/Yocto_overview.md` section 14.5
for an `~/.ssh/config` entry that stops the warning.
