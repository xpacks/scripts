#! /bin/bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Bash script to load the scripts.git project.
# -----------------------------------------------------------------------------

# Prefer the environment location XPACKS_FOLDER, if defined,
# but default to '.xpacks'.
xpacks_repo_folder="${XPACKS_REPO_FOLDER:-$HOME/.xpacks}"

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
  mkdir -p "${xpacks_repo_folder}/ilg"
  do_git_update "${xpacks_repo_folder}/ilg/$1.git" "https://github.com/xpacks/$1.git"
}

# -----------------------------------------------------------------------------

if [ ! -d "${xpacks_repo_folder}" ]
then
  echo "Creating ${xpacks_repo_folder}"
  mkdir -p "${xpacks_repo_folder}"
fi

# Update third party xPacks
do_update_xpacks "scripts"

# -----------------------------------------------------------------------------
