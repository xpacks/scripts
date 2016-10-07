#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Until the XCDL utility will be functional, use this Bash script
# to update the xPacks repository.
#
# During the first run, the repositories will be cloned into the local folder.
# Subsequent runs will pull the latest commits.
# -----------------------------------------------------------------------------

# Prefer the environment location XPACKS_FOLDER, if defined,
# but default to '.xpacks'.
xpacks_repo_folder="${XPACKS_REPO_FOLDER:-$HOME/.xpacks}"

# -----------------------------------------------------------------------------

helper_script="$xpacks_repo_folder/ilg/scripts.git/xpacks-helper.sh"

# Include common definitions from helper script.
source "${helper_script}"

# -----------------------------------------------------------------------------

if [ ! -d "${xpacks_repo_folder}" ]
then
  echo "Creating ${xpacks_repo_folder}..."
  mkdir -p "${xpacks_repo_folder}"
else
  echo "Using ${xpacks_repo_folder}..."
fi

# -----------------------------------------------------------------------------

# Update a single Git, if it exists.
# $1 = absolute folder.
# $2 = git absolute url.
do_git_update() {
  echo
  if [ -d "$1" ]
  then
    echo "Checking '$1'..."
    (cd "$1"; git pull)
  fi
}

# -----------------------------------------------------------------------------

# Update µOS++ xPacks
do_update_micro_os_plus "micro-os-plus-iii"
do_update_micro_os_plus "micro-os-plus-iii-cortexm"
do_update_micro_os_plus "posix-arch"

# Update third party xPacks
do_update_xpacks "arm-cmsis"
do_update_xpacks "stm32f4-cmsis"
do_update_xpacks "stm32f4-hal"
do_update_xpacks "stm32f7-cmsis"
do_update_xpacks "stm32f7-hal"
do_update_xpacks "freertos"

do_update_xpacks "scripts"

echo
echo "Done."
echo

# -----------------------------------------------------------------------------
