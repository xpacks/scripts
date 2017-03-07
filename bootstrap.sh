#! /bin/bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Bash script to load the scripts.git project.
# -----------------------------------------------------------------------------

# xpacks_repo_folder must be set by including bootstrap-paths.sh before.

# -----------------------------------------------------------------------------

# Update a single Git, or clone at first run.
# $1 = absolute folder.
# $2 = git absolute url.
do_git_update() {
  echo
  if [ -d "$1" ]
  then
    echo "Checking '$1'..."
    (cd "$1"; git pull)
  else
    git clone "$2" "$1"
  fi
}

# Update a single third party xPack.
# $1 = GitHub project name.
do_update_xpacks() {
  mkdir -p "${xpacks_repo_folder_path}/ilg"
  do_git_update "${xpacks_repo_folder_path}/ilg/$1.git" "https://github.com/xpacks/$1.git"
}

# -----------------------------------------------------------------------------

if [ ! -d "${xpacks_repo_folder_path}" ]
then
  echo "Creating ${xpacks_repo_folder_path}"
  mkdir -p "${xpacks_repo_folder_path}"
fi

# Update third party xPacks
do_update_xpacks "scripts"

# -----------------------------------------------------------------------------
