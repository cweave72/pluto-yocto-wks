#!/bin/bash
#
# Initialize or start the Yocto build environment for the Pluto workspace.
# Source this script. Do not execute it: it changes the current shell.
#
(return 0 2>/dev/null) || { echo "ERROR: Source this script: . init_build.sh"; exit 1; }

_wks_usage () {
    cat <<EOF
Initialize or start the Yocto build environment (source this script).
Usage:
. $(basename "${BASH_SOURCE[0]}") [OPTIONS] [build_dir]
Options:
    -h --help         : Show this message.
    -p --printenv     : Show the settings. Do not start the environment.
    --init            : Make build_dir/conf from the meta-pluto-platform template.
                        The script also does this if build_dir/conf does not exist.
    --dl_dir=PATH     : DL_DIR location (network share permitted).
    --sstate=PATH     : SSTATE_DIR location (network share permitted).
    --tmpdir=PATH     : TMPDIR location (local disk only).
build_dir defaults to "build". settings.cfg keeps the last values.
Example:
. init_build.sh --init --dl_dir=~/netshare/yocto_dl --sstate=~/netshare/yocto_sstate --tmpdir=~/yocto/pluto_tmp
EOF
}

_wks_confirm () {
    local reply
    read -r -p "Continue [y/n] (RET=y): " reply
    case $reply in
        [yY]|"") return 0 ;;
        *) return 1 ;;
    esac
}

# Expand a leading "~" and make the path absolute.
_wks_abspath () {
    local p="$1"
    case $p in
        "~") p="$HOME" ;;
        "~/"*) p="$HOME/${p#\~/}" ;;
    esac
    realpath -m "$p"
}

_wks_main () {
    local root settings template builddir init=0 printonly=0 arg
    root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    settings="$root/settings.cfg"
    template="$root/meta-pluto-platform/conf/templates/default"

    if [ ! -f "$root/openembedded-core/oe-init-build-env" ] || [ ! -f "$template/local.conf.sample" ]; then
        echo "ERROR: Submodules are missing. Run: git submodule update --init"
        return 1
    fi

    # Prefixed names: TMPDIR in the shell environment changes the temporary
    # directory of other tools.
    local PLUTO_DL_DIR PLUTO_SSTATE_DIR PLUTO_TMPDIR PLUTO_BUILD_DIR
    [ -f "$settings" ] && source "$settings"
    PLUTO_DL_DIR="${PLUTO_DL_DIR:-$HOME/netshare/yocto_dl}"
    PLUTO_SSTATE_DIR="${PLUTO_SSTATE_DIR:-$HOME/netshare/yocto_sstate}"
    PLUTO_TMPDIR="${PLUTO_TMPDIR:-$HOME/yocto/pluto_tmp}"
    PLUTO_BUILD_DIR="${PLUTO_BUILD_DIR:-build}"

    for arg in "$@"; do
        case $arg in
            --dl_dir=*)  PLUTO_DL_DIR=$(_wks_abspath "${arg#*=}") ;;
            --sstate=*)  PLUTO_SSTATE_DIR=$(_wks_abspath "${arg#*=}") ;;
            --tmpdir=*)  PLUTO_TMPDIR=$(_wks_abspath "${arg#*=}") ;;
            --init)      init=1 ;;
            -p|--printenv) printonly=1 ;;
            -h|--help)   _wks_usage; return 0 ;;
            -*)          echo "Unrecognized option: $arg"; _wks_usage; return 1 ;;
            *)           PLUTO_BUILD_DIR="$arg" ;;
        esac
    done
    builddir="$root/$PLUTO_BUILD_DIR"

    echo "Settings:"
    echo "---------------------"
    echo "Build directory = $builddir"
    echo "DL_DIR          = $PLUTO_DL_DIR"
    echo "SSTATE_DIR      = $PLUTO_SSTATE_DIR"
    echo "TMPDIR          = $PLUTO_TMPDIR"
    echo "---------------------"
    [ "$printonly" = 1 ] && return 0

    if [ "$init" = 1 ] && [ -d "$builddir/conf" ]; then
        echo "NOTE: $builddir/conf exists. The script does not apply the template again."
        echo "      Remove $builddir/conf to apply the template again."
    fi
    _wks_confirm || return 1

    cat > "$settings" <<EOF
PLUTO_DL_DIR="$PLUTO_DL_DIR"
PLUTO_SSTATE_DIR="$PLUTO_SSTATE_DIR"
PLUTO_TMPDIR="$PLUTO_TMPDIR"
PLUTO_BUILD_DIR="$PLUTO_BUILD_DIR"
EOF

    # oe-init-build-env copies the template only if conf/ does not exist.
    if [ ! -d "$builddir/conf" ]; then
        export TEMPLATECONF="$template"
    fi

    cd "$root" || return 1
    source openembedded-core/oe-init-build-env "$builddir" || return 1
    unset TEMPLATECONF

    # Write the cache locations into local.conf.
    sed -i \
        -e "s|^DL_DIR ?= .*|DL_DIR ?= \"$PLUTO_DL_DIR\"|" \
        -e "s|^SSTATE_DIR ?= .*|SSTATE_DIR ?= \"$PLUTO_SSTATE_DIR\"|" \
        -e "s|^TMPDIR ?= .*|TMPDIR ?= \"$PLUTO_TMPDIR\"|" \
        conf/local.conf
    echo "Cache locations written to $builddir/conf/local.conf."
}

_wks_main "$@"
_wks_rc=$?
unset -f _wks_usage _wks_confirm _wks_abspath _wks_main
eval "unset _wks_rc; return $_wks_rc"
