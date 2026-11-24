#!/bin/bash
#
# Boot the Pluto from RAM over JTAG (Digilent JTAG-HS3 and ADALM-UARTJTAG).
# The script programs the PL, initializes the PS, loads Linux into DDR, and
# starts the kernel. Nothing goes into QSPI flash.
#
set -euo pipefail

WKS=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
TCL="$WKS/scripts/jtag/pluto-jtag-boot.tcl"

BUILD_DIR="build"
[ -f "$WKS/settings.cfg" ] && BUILD_DIR=$(. "$WKS/settings.cfg"; echo "${PLUTO_BUILD_DIR:-build}")
case $BUILD_DIR in /*) ;; *) BUILD_DIR="$WKS/$BUILD_DIR" ;; esac
DEPLOY="$BUILD_DIR/deploy/images/pluto"
# ADI JTAG bootstrap files (recipe pluto-jtag-bootstrap).
BOOTSTRAP="$DEPLOY/adi-jtag-bootstrap"

# DDR load addresses. The kernel decompresses itself to 0x8000.
KERNEL_ADDR=0x01000000
DTB_ADDR=0x02000000
INITRD_ADDR=0x04000000

MODE="linux"
REV="b"
URL=""
DTB=""
BIT=""
KERNEL="$DEPLOY/zImage"
INITRD="$DEPLOY/core-image-minimal-pluto.rootfs.cpio.gz"
PS7_INIT="$BOOTSTRAP/ps7_init.tcl"
UBOOT="$BOOTSTRAP/u-boot.elf"
BOOTARGS="console=ttyPS0,115200 root=/dev/ram0 rw earlyprintk clk_ignore_unused"

usage () {
    cat <<EOF
Boot the Pluto from RAM over JTAG.
Usage: $(basename "$0") [OPTIONS]
Options:
    -h --help          : Show this message.
    --rev=a|b|c        : Hardware revision. Selects the default DTB (default: $REV).
    --dtb=FILE         : Device tree blob (default: zynq-pluto-sdr-rev<REV>.dtb).
    --kernel=FILE      : zImage (default: \$DEPLOY/zImage).
    --initrd=FILE      : cpio.gz initramfs (default: core-image-minimal).
    --bit=FILE|none    : Bitstream (default: ADI stock system_top.bit).
    --ps7-init=FILE    : ps7_init.tcl (default: ADI stock ps7_init.tcl).
    --bootargs=STRING  : Kernel command line (default: "$BOOTARGS").
    --uboot[=FILE]     : Start u-boot.elf instead of Linux.
    --url=HOST:PORT    : Remote hw_server. Default: local hw_server.
DEPLOY=$DEPLOY
Run "bitbake core-image-minimal" first. It deploys all default files.
Console: minicom -D /dev/ttyUSB<N> -b 115200 (the ADALM-UARTJTAG CP2104 port)
EOF
}

for arg in "$@"; do
    case $arg in
        -h|--help)    usage; exit 0 ;;
        --rev=*)      REV="${arg#*=}" ;;
        --dtb=*)      DTB="${arg#*=}" ;;
        --kernel=*)   KERNEL="${arg#*=}" ;;
        --initrd=*)   INITRD="${arg#*=}" ;;
        --bit=*)      BIT="${arg#*=}" ;;
        --ps7-init=*) PS7_INIT="${arg#*=}" ;;
        --bootargs=*) BOOTARGS="${arg#*=}" ;;
        --uboot)      MODE="uboot" ;;
        --uboot=*)    MODE="uboot"; UBOOT="${arg#*=}" ;;
        --url=*)      URL="${arg#*=}" ;;
        *) echo "ERROR: Unknown option: $arg"; usage; exit 1 ;;
    esac
done

case $REV in
    a) DTB_NAME="zynq-pluto-sdr.dtb" ;;
    b) DTB_NAME="zynq-pluto-sdr-revb.dtb" ;;
    c) DTB_NAME="zynq-pluto-sdr-revc.dtb" ;;
    *) echo "ERROR: --rev must be a, b, or c."; exit 1 ;;
esac
[ -n "$DTB" ] || DTB="$DEPLOY/$DTB_NAME"

case $BIT in
    none) BIT="" ;;
    "")   BIT="$BOOTSTRAP/system_top.bit" ;;
esac

XSDB="${XSDB:-$(command -v xsdb || true)}"
if [ -z "$XSDB" ]; then
    XSDB=$(ls -d /opt/Xilinx/*/Vivado/bin/xsdb /tools/Xilinx/*/Vivado/bin/xsdb 2>/dev/null | sort -V | tail -n 1 || true)
fi
[ -x "$XSDB" ] || { echo "ERROR: xsdb not found. Set XSDB=<path>."; exit 1; }

need () {
    [ -f "$1" ] || { echo "ERROR: File not found: $1"; [ -z "${2:-}" ] || echo "$2"; exit 1; }
}
need "$PS7_INIT" "Run bitbake core-image-minimal."
[ -z "$BIT" ] || need "$BIT" "Run bitbake core-image-minimal."

ARGS=("mode=$MODE" "url=$URL" "ps7_init=$PS7_INIT" "bit=$BIT")

if [ "$MODE" = "uboot" ]; then
    need "$UBOOT" "Run bitbake core-image-minimal."
    ARGS+=("uboot=$UBOOT")
else
    need "$KERNEL" "Run bitbake core-image-minimal."
    need "$DTB" "Run bitbake core-image-minimal."
    need "$INITRD" "Run bitbake core-image-minimal."
    command -v fdtput >/dev/null || { echo "ERROR: fdtput not found. Install device-tree-compiler."; exit 1; }

    # The kernel finds the initramfs and the command line in /chosen.
    # Without u-boot, this script writes them into a copy of the DTB.
    TMP=$(mktemp -d)
    trap 'rm -rf "$TMP"' EXIT
    KERNEL=$(readlink -f "$KERNEL")
    INITRD=$(readlink -f "$INITRD")
    cp "$(readlink -f "$DTB")" "$TMP/boot.dtb"
    INITRD_SIZE=$(stat -c %s "$INITRD")
    INITRD_END=$(( INITRD_ADDR + INITRD_SIZE ))
    fdtput -t x "$TMP/boot.dtb" /chosen linux,initrd-start "$(printf %x $INITRD_ADDR)"
    fdtput -t x "$TMP/boot.dtb" /chosen linux,initrd-end "$(printf %x $INITRD_END)"
    fdtput -t s "$TMP/boot.dtb" /chosen bootargs "$BOOTARGS"

    if (( INITRD_ADDR < DTB_ADDR + $(stat -c %s "$TMP/boot.dtb") )); then
        echo "ERROR: The DTB overlaps the initramfs. Change DTB_ADDR or INITRD_ADDR."
        exit 1
    fi

    echo "Kernel   : $KERNEL"
    echo "DTB      : $DTB"
    echo "Initramfs: $INITRD ($INITRD_SIZE bytes)"
    echo "Bootargs : $BOOTARGS"
    ARGS+=("kernel=$KERNEL" "dtb=$TMP/boot.dtb" "initrd=$INITRD"
           "kernel_addr=$KERNEL_ADDR" "dtb_addr=$DTB_ADDR" "initrd_addr=$INITRD_ADDR")
fi
echo "Bitstream: ${BIT:-none}"

"$XSDB" "$TCL" "${ARGS[@]}"
echo "Done. Monitor the boot on the serial console."
