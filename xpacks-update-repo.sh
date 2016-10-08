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

# Update existing git repository.
# $1 = local git absolute path
cd "$xpacks_repo_folder"
tmp_file="$(mktemp)"
cat <<'EOF' >"${tmp_file}"
cd "$1/.."
echo
pwd
git pull

EOF

# Iterate all folders that look like a git repo.
find "$xpacks_repo_folder" -type d -name '.git' -maxdepth 3 \
-exec bash "${tmp_file}" {} \;

rm "${tmp_file}"

echo
echo "Done."
echo

# -----------------------------------------------------------------------------
