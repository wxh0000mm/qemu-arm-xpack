#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# This file is part of the GNU MCU Eclipse distribution.
#   (https://gnu-mcu-eclipse.github.io)
# Copyright (c) 2019 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software 
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Safety settings (see https://gist.github.com/ilg-ul/383869cbb01f61a51c4d).

if [[ ! -z ${DEBUG} ]]
then
  set ${DEBUG} # Activate the expand mode if DEBUG is anything but empty.
else
  DEBUG=""
fi

set -o errexit # Exit if command failed.
set -o pipefail # Exit if pipe failed.
set -o nounset # Exit if variable not set.

# Remove the initial space and instead use '\n'.
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Identify the script location, to reach, for example, the helper scripts.

build_script_path="$0"
if [[ "${build_script_path}" != /* ]]
then
  # Make relative path absolute.
  build_script_path="$(pwd)/$0"
fi

script_folder_path="$(dirname "${build_script_path}")"
script_folder_name="$(basename "${script_folder_path}")"

# =============================================================================

# Inner script to run inside Docker containers to build the 
# GNU MCU Eclipse QEMU ARM distribution packages.

# For native builds, it runs on the host (macOS build cases,
# and development builds for GNU/Linux).

# -----------------------------------------------------------------------------

defines_script_path="${script_folder_path}/defs-source.sh"
echo "Definitions source script: \"${defines_script_path}\"."
source "${defines_script_path}"

# This file is generated by the host build script.
host_defines_script_path="${script_folder_path}/host-defs-source.sh"
echo "Host definitions source script: \"${host_defines_script_path}\"."
source "${host_defines_script_path}"

common_helper_functions_script_path="${script_folder_path}/helper/common-functions-source.sh"
echo "Common helper functions source script: \"${common_helper_functions_script_path}\"."
source "${common_helper_functions_script_path}"

common_functions_script_path="${script_folder_path}/common-functions-source.sh"
echo "Common functions source script: \"${common_functions_script_path}\"."
source "${common_functions_script_path}"

container_functions_script_path="${script_folder_path}/helper/container-functions-source.sh"
echo "Container helper functions source script: \"${container_functions_script_path}\"."
source "${container_functions_script_path}"

common_libs_functions_script_path="${script_folder_path}/${COMMON_LIBS_FUNCTIONS_SCRIPT_NAME}"
echo "Common libs functions source script: \"${common_libs_functions_script_path}\"."
source "${common_libs_functions_script_path}"

common_apps_functions_script_path="${script_folder_path}/${COMMON_APPS_FUNCTIONS_SCRIPT_NAME}"
echo "Common app functions source script: \"${common_apps_functions_script_path}\"."
source "${common_apps_functions_script_path}"

# -----------------------------------------------------------------------------

if [ ! -z "#{DEBUG}" ]
then
  echo $@
fi

WITH_STRIP="y"
WITH_PDF="y"
WITH_HTML="n"
IS_DEVELOP=""
IS_DEBUG=""

JOBS=""

while [ $# -gt 0 ]
do

  case "$1" in

    --disable-strip)
      WITH_STRIP="n"
      shift
      ;;

    --without-pdf)
      WITH_PDF="n"
      shift
      ;;

    --with-pdf)
      WITH_PDF="y"
      shift
      ;;

    --without-html)
      WITH_HTML="n"
      shift
      ;;

    --with-html)
      WITH_HTML="y"
      shift
      ;;

    --jobs)
      JOBS=$2
      shift 2
      ;;

    --develop)
      IS_DEVELOP="y"
      shift
      ;;

    --debug)
      IS_DEBUG="y"
      shift
      ;;

    *)
      echo "Unknown action/option $1"
      exit 1
      ;;

  esac

done

if [ "${IS_DEBUG}" == "y" ]
then
  WITH_STRIP="n"
fi

# -----------------------------------------------------------------------------

start_timer

detect_container

prepare_xbb_env

prepare_xbb_extras

# -----------------------------------------------------------------------------

QEMU_PROJECT_NAME="qemu"

QEMU_GIT_COMMIT=${QEMU_GIT_COMMIT:-""}
QEMU_GIT_PATCH=""

README_OUT_FILE_NAME="README-${RELEASE_VERSION}.md"

# Keep them in sync with combo archive content.
if [[ "${RELEASE_VERSION}" =~ 2\.8\.0-* ]]
then

  # ---------------------------------------------------------------------------

  QEMU_VERSION="2.8"
  if [ "${RELEASE_VERSION}" == "2.8.0-3" ]
  then
    QEMU_GIT_BRANCH=${QEMU_GIT_BRANCH:-"gnuarmeclipse"}
    QEMU_GIT_COMMIT=${QEMU_GIT_COMMIT:-"b01e4c3bd5dc1715c684e600c1a3d634a0672b2c"}
    
    ZLIB_VERSION="1.2.8"

    LIBPNG_VERSION="1.6.23"
    LIBPNG_SFOLDER="libpng16"

    JPEG_VERSION="9b"

    SDL2_VERSION="2.0.5"

    SDL2_IMAGE_VERSION="2.0.1"

    LIBFFI_VERSION="3.2.1"

    LIBICONV_VERSION="1.14"

    LIBXML2_VERSION="2.9.8"

    GETTEXT_VERSION="0.19.8.1"

    GLIB_MVERSION="2.51"
    GLIB_VERSION="${GLIB_MVERSION}.0"

    PIXMAN_VERSION="0.34.0"

  elif [ "${RELEASE_VERSION}" == "2.8.0-4" ]
  then
    QEMU_GIT_BRANCH=${QEMU_GIT_BRANCH:-"gnuarmeclipse"}
    QEMU_GIT_COMMIT=${QEMU_GIT_COMMIT:-"ee07085299a4ec1edc92453eef9b3c3bd0c4ab92"}
    QEMU_GIT_PATCH="qemu-2.8.0.git-patch"

    ZLIB_VERSION="1.2.8"

    LIBPNG_VERSION="1.6.23"
    LIBPNG_SFOLDER="libpng16"

    JPEG_VERSION="9b"

    SDL2_VERSION="2.0.5"

    SDL2_IMAGE_VERSION="2.0.1"

    LIBFFI_VERSION="3.2.1"

    LIBICONV_VERSION="1.14"

    LIBXML2_VERSION="2.9.8"

    GETTEXT_VERSION="0.19.8.1"

    GLIB_MVERSION="2.51"
    GLIB_VERSION="${GLIB_MVERSION}.0"

    PIXMAN_VERSION="0.34.0"

  elif [[ "${RELEASE_VERSION}" =~ 2\.8\.0-[56] ]]
  then
    QEMU_GIT_BRANCH=${QEMU_GIT_BRANCH:-"gnuarmeclipse-dev"}
    QEMU_GIT_COMMIT=${QEMU_GIT_COMMIT:-"b8a0a8bc9850acbf5763d2e5d526c250de6ff809"}
    QEMU_GIT_PATCH="qemu-2.8.0.git-patch"

    ZLIB_VERSION="1.2.11"

    # LIBPNG_VERSION="1.6.34"
    LIBPNG_VERSION="1.6.36"
    LIBPNG_SFOLDER="libpng16"

    JPEG_VERSION="9b"

    # SDL2_VERSION="2.0.8"
    SDL2_VERSION="2.0.9"

    # SDL2_IMAGE_VERSION="2.0.3"
    SDL2_IMAGE_VERSION="2.0.4"

    LIBFFI_VERSION="3.2.1"

    LIBICONV_VERSION="1.15"

    GETTEXT_VERSION="0.19.8.1"

    # The last one without meson & ninja.
    # 2.56.0 fails on mingw.
    GLIB_MVERSION="2.56"
    GLIB_VERSION="${GLIB_MVERSION}.4"

    # PIXMAN_VERSION="0.34.0"
    PIXMAN_VERSION="0.38.0"

    # LIBXML2_VERSION="2.9.8"

    HAS_WINPTHREAD="y"
  elif [[ "${RELEASE_VERSION}" =~ 2\.8\.0-7 ]]
  then
    QEMU_GIT_BRANCH=${QEMU_GIT_BRANCH:-"xpack-develop"}
    QEMU_GIT_COMMIT=${QEMU_GIT_COMMIT:-"743693888b8ac728035511f0f698305e41346bca"}
    QEMU_GIT_PATCH="qemu-2.8.0.git-patch"

    ZLIB_VERSION="1.2.11"

    # LIBPNG_VERSION="1.6.34"
    LIBPNG_VERSION="1.6.36"
    LIBPNG_SFOLDER="libpng16"

    JPEG_VERSION="9b"

    # SDL2_VERSION="2.0.8"
    SDL2_VERSION="2.0.9"

    # SDL2_IMAGE_VERSION="2.0.3"
    SDL2_IMAGE_VERSION="2.0.4"

    LIBFFI_VERSION="3.2.1"

    LIBICONV_VERSION="1.15"

    GETTEXT_VERSION="0.19.8.1"

    # The last one without meson & ninja.
    # 2.56.0 fails on mingw.
    GLIB_MVERSION="2.56"
    GLIB_VERSION="${GLIB_MVERSION}.4"

    # PIXMAN_VERSION="0.34.0"
    PIXMAN_VERSION="0.38.0"

    # LIBXML2_VERSION="2.9.8"

    HAS_WINPTHREAD="y"
  else
    echo "Unsupported version ${RELEASE_VERSION}."
    exit 1
  fi

  # ---------------------------------------------------------------------------
else
  echo "Unsupported version ${RELEASE_VERSION}."
  exit 1
fi

# -----------------------------------------------------------------------------

QEMU_SRC_FOLDER_NAME=${QEMU_SRC_FOLDER_NAME:-"${QEMU_PROJECT_NAME}.git"}
QEMU_GIT_URL=${QEMU_GIT_URL:-"https://github.com/xpack-dev-tools/qemu.git"}

# Used in the licenses folder.
QEMU_FOLDER_NAME="qemu-${QEMU_VERSION}"

# -----------------------------------------------------------------------------

echo
echo "Here we go..."
echo

# -----------------------------------------------------------------------------
# Build dependent libraries.

# Warning: on Darwin, some libraries do not build with GNU GCC-7.4, and
# must revert to Apple clang. (glib & sdl2)

do_zlib

do_libpng
do_jpeg
do_libiconv

do_sdl2
do_sdl2_image

do_libffi

# in certain configurations it requires libxml2 on windows
do_gettext 
do_glib
do_pixman

# -----------------------------------------------------------------------------

do_qemu

run_qemu

# -----------------------------------------------------------------------------

copy_distro_files

create_archive

# Change ownership to non-root GNU/Linux user.
fix_ownership

# -----------------------------------------------------------------------------

stop_timer

exit 0

# -----------------------------------------------------------------------------