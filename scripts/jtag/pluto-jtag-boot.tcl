# Load and start software on the Pluto over JTAG. Nothing goes into QSPI flash.
#
# Usage: xsdb pluto-jtag-boot.tcl key=value ...
# pluto-jtag-boot.sh supplies the arguments. Keys:
#   mode         linux: start the Linux kernel. uboot: start u-boot.elf.
#   url          hw_server URL. Empty: xsdb starts a local hw_server.
#   ps7_init     ps7_init.tcl that agrees with the bitstream.
#   bit          bitstream file. Empty: do not program the PL.
#   kernel       zImage (mode=linux).
#   dtb          device tree blob (mode=linux).
#   initrd       cpio.gz initramfs (mode=linux).
#   kernel_addr  dtb_addr  initrd_addr   DDR load addresses (mode=linux).
#   uboot        u-boot.elf (mode=uboot).

array set opt {
    mode linux url "" ps7_init "" bit "" kernel "" dtb "" initrd ""
    kernel_addr 0x01000000 dtb_addr 0x02000000 initrd_addr 0x04000000 uboot ""
}
foreach a $::argv {
    set i [string first "=" $a]
    if {$i < 1} { error "Argument is not key=value: $a" }
    set key [string range $a 0 [expr {$i - 1}]]
    if {![info exists opt($key)]} { error "Unknown key: $key" }
    set opt($key) [string range $a [expr {$i + 1}] end]
}

proc step {msg} { puts "== $msg" }

step "Connect"
if {$opt(url) eq ""} { connect } else { connect -url $opt(url) }
after 1000

targets -set -nocase -filter {name =~ "APU*"}
set boot_mode [expr {[mrd -value 0xF800025C] & 0xF}]
if {$boot_mode != 0} {
    puts "WARNING: Boot mode is $boot_mode, not JTAG (0). The QSPI bootloader starts after the reset."
}

step "Reset the system"
rst -system
after 500
targets -set -nocase -filter {name =~ "*A9*#0"}
catch {stop}

if {$opt(bit) ne ""} {
    step "Program the PL: $opt(bit)"
    targets -set -nocase -filter {name =~ "xc7z*"}
    fpga -file $opt(bit)
    targets -set -nocase -filter {name =~ "*A9*#0"}
}

step "Initialize the PS: $opt(ps7_init)"
source $opt(ps7_init)
ps7_init
ps7_post_config

# The kernel and u-boot need the MMU, the D-cache, and the I-cache off.
# Clear SCTLR bits M (0), C (2), and I (12).
set sctlr [lindex [rrd -nvlist cp15 1 sctlr] 1]
rwr cp15 1 sctlr [format 0x%08x [expr {"0x$sctlr" & ~0x1005}]]

if {$opt(mode) eq "uboot"} {
    step "Load $opt(uboot)"
    dow $opt(uboot)
} elseif {$opt(mode) eq "linux"} {
    step "Load $opt(kernel) at $opt(kernel_addr)"
    dow -data $opt(kernel) $opt(kernel_addr)
    step "Load $opt(dtb) at $opt(dtb_addr)"
    dow -data $opt(dtb) $opt(dtb_addr)
    step "Load $opt(initrd) at $opt(initrd_addr)"
    dow -data $opt(initrd) $opt(initrd_addr)

    # ARM Linux boot protocol: r0 = 0, r1 = ~0 (device tree boot),
    # r2 = device tree address, SVC mode, IRQ and FIQ masked.
    rwr r0 0
    rwr r1 0xffffffff
    rwr r2 $opt(dtb_addr)
    rwr cpsr 0x1d3
    rwr pc $opt(kernel_addr)
} else {
    error "Unknown mode: $opt(mode)"
}

step "Start CPU0"
con
disconnect
