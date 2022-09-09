#!/bin/env bash
set -eu

# get script location
#  ref: https://www.baeldung.com/linux/bash-get-location-within-script
SCRIPT_PATH="${BASH_SOURCE}"
while [ -L "${SCRIPT_PATH}" ]; do
  SCRIPT_DIR="$(cd -P "$(dirname "${SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"
  SCRIPT_PATH="$(readlink "${SCRIPT_PATH}")"
  [[ ${SCRIPT_PATH} != /* ]] && SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_PATH}"
done
SCRIPT_PATH="$(readlink -f "${SCRIPT_PATH}")"
SCRIPT_DIR="$(cd -P "$(dirname -- "${SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"

# for documentation of alpine-chroot-install, see help section below
usage() {
	sed -En '/^#---help---/,/^#---help---/p' "${SCRIPT_PATH}" | sed -E 's/^# ?//; 1d;$d;'
  echo 'shell variables that have been set are:'
  echo ''
  echo "  CBUILDER=$CBUILDER"
  echo "  CHROOT_DIR=$CHROOT_DIR"
  echo "  ALPINE_CHROOT_INSTALL_TAG=$ALPINE_CHROOT_INSTALL_TAG"
  echo "  ALPINE_CHROOT_INSTALL_SHA1=$ALPINE_CHROOT_INSTALL_SHA1"
  echo ''
  echo '------------------------------------------------------------------'
  echo ''
  if [ -e alpine-chroot-install ]; then
    sh alpine-chroot-install -h
  fi
}

show_versions() {
  echo "cbuilder-chroot.sh ${VERSION:=${ALPINE_CHROOT_INSTALL_TAG}}"
  if [ -e alpine-chroot-install ]; then
    sh alpine-chroot-install -v
  fi
}

get_installer() {
  if [ ! -e alpine-chroot-install ]; then
    pushd ${SCRIPT_DIR}
    wget https://raw.githubusercontent.com/alpinelinux/alpine-chroot-install/${ALPINE_CHROOT_INSTALL_TAG:="v0.14.0"}/alpine-chroot-install \
     && echo "${ALPINE_CHROOT_INSTALL_SHA1:='ccbf65f85cdc351851f8ad025bb3e65bae4d5b06'}  alpine-chroot-install" | sha1sum -c \
     || exit 1 
    popd
  fi
}

# script-specific overrides go here; may be overridden via getopts

CHROOT_DIR_DEFAULT=~/var/alpine
CHROOT_DIR=${CHROOT_DIR:="$CHROOT_DIR_DEFAULT"}
ALPINE_CHROOT_INSTALL_TAG=${ALPINE_CHROOT_INSTALL_TAG:="v0.14.0"}
ALPINE_CHROOT_INSTALL_SHA1=${ALPINE_CHROOT_INSTALL_SHA1:="ccbf65f85cdc351851f8ad025bb3e65bae4d5b06"}
CBUILDER=''
CBUILDER="${CBUILDER} bash vim"
CBUILDER="${CBUILDER} build-base gcc abuild binutils binutils-doc gcc-doc"
CBUILDER="${CBUILDER} cmake cmake-doc"
CBUILDER="${CBUILDER} ccache ccache-doc"
# Linux headers are necessary to compile and link static busybox
CBUILDER="${CBUILDER} linux-headers"
# Package mandoc is needed to view man pages
#   Package name has changed from man to mandoc in alpine 3.12
#     according to https://stackoverflow.com/a/62240153
CBUILDER="${CBUILDER} mandoc man-pages"
# Files needed to build man pages and md2roff
CBUILDER="${CBUILDER} perl"
CBUILDER="${CBUILDER} groff"
CBUILDER="${CBUILDER} groff-doc"
# Uncomment if git is desired
#CBUILDER="${CBUILDER} git"
# Comment if fossil-scm is not desired
CBUILDER="${CBUILDER} fossil fossil-bash-completion"

ALPINE_PACKAGES=${ALPINE_PACKAGES:="build-base ca-certificates ssl_client ${CBUILDER}"}


# TODO rewrite using getopt, see man 1 getopt
# override defaults with option list stolen from alpine-chroot-install
while getopts 'a:b:d:gi:k:m:p:r:t:s:u:hv' OPTION; do
	case "$OPTION" in
		a) ARCH="$OPTARG";;
		b) ALPINE_BRANCH="$OPTARG";;
		d) CHROOT_DIR="$OPTARG";;
    g) get_installer;; 
		i) BIND_DIR="$OPTARG";;
		k) CHROOT_KEEP_VARS="${CHROOT_KEEP_VARS:-} $OPTARG";;
		m) ALPINE_MIRROR="$OPTARG";;
		p) ALPINE_PACKAGES="${ALPINE_PACKAGES:-} $OPTARG";;
		r) EXTRA_REPOS="${EXTRA_REPOS:-} $OPTARG";;
		t) TEMP_DIR="$OPTARG";;
		s) ALPINE_CHROOT_INSTALL_SHA1="$OPTARG";;
		u) ALPINE_CHROOT_INSTALL_TAG="$OPTARG";;
		h) usage; exit 0;;
    v) show_versions; exit 0;;
	esac
done

# http://logan.tw/posts/2016/02/27/colon-built-in-in-bash/
#   ':' means treat unset parameters as unset.
set -x
export ALPINE_BRANCH="${ALPINE_BRANCH:=latest-stable}"
#export ALPINE_MIRROR="${ALPINE_MIRROR:='http://dl-cdn.alpinelinux.org/alpine'}"
export ALPINE_PACKAGES="${ALPINE_PACKAGES:=build-base ca-certificates ssl_client}"
export ARCH="${ARCH:=}"
export BIND_DIR="${BIND_DIR:=}"
export CHROOT_DIR="${CHROOT_DIR:=~/alpine}"
export CHROOT_KEEP_VARS="${CHROOT_KEEP_VARS:=ARCH CI QEMU_EMULATOR TRAVIS_.*}"
export EXTRA_REPOS="${EXTRA_REPOS:=}"
export TEMP_DIR="$(mktemp -d || echo /tmp/alpine)"
set +x

# get installer if it does not exist
get_installer

# override mount for rootless operation
chmod +x ${SCRIPT_DIR}/usr/sbin/mount
export PATH="${SCRIPT_DIR}/usr/sbin:$PATH"

# invoke installer, options have been exported in environment
#bash -c printenv
bash ${SCRIPT_DIR}/alpine-chroot-install
cp post_install.sh ${CHROOT_DIR}/root/

#---help---
# Usage: alpine-cbuilder.sh [-g] \
#                           [-s ALPINE_CHROOT_INSTALL_SHA1] \
#                           [-u ALPINE_CHROOT_INSTALL_TAG] \
#                           [options for alpine-chroot-install
# where:
#
#   - the -g argument means get the alpine-chroot-install script
#       if it is not present; this happens by default; delete the
#       script first if you need to update it because this script
#       will not automatically update it.
#   - ALPINE_CHROOT_INSTALL_TAG is release tag from
#       https://github.com/alpinelinux/alpine-chroot-install/tags
#   - ALPINE_CHROOT_INSTALL_SHA1 is commit SHA1 tagged by
#       ALPINE_CHROOT_INSTALL_TAG
#
# This script builds an Alpine Linux chroot environment for
# alpine-cbuilder, so that there is no need to resort to creating a
# Docker image.
#
# This script fetches and invokes
#   https://github.com/alpinelinux/alpine-chroot-install
#
# alpine-chroot-install requires Debian or Ubuntu if QEMU is desired,
# e.g., to emulate other architectures.
#
# For more info, see help for alpine-chroot-install which follows if
# it has been installed:
#
#--------------------------------------------------------------------
#
#---help---

