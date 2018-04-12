#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Until the XCDL utility will be functional, use this Bash script
# to check the status of the gits in the xPacks repository.
# -----------------------------------------------------------------------------

# Prefer the environment location XPACKS_FOLDER, if defined,
# but default to '.xpacks'.
xpacks_repo_folder="${XPACKS_REPO_FOLDER:-$HOME/Library/xPacks}"

# -----------------------------------------------------------------------------

helper_script="$xpacks_repo_folder/ilg/scripts.git/xpacks-helper.sh"

# Include common definitions from helper script.
source "${helper_script}"

# -----------------------------------------------------------------------------

# Check if existing git repository requires sync.
# $1 = local git absolute path
cd "$xpacks_repo_folder"
tmp_file="$(mktemp)"
cat <<'EOF' >"${tmp_file}"
cd "$1/.."
b="$(git name-rev --name-only HEAD)"
d="$(git status)"
if [[ "${d}" == *nothing\ to\ commit,\ working\ directory\ clean ]]
then  
  p="$(git log @{push}..)"
  if [ "${p}" != "" ]
  then
    echo
    pwd
    echo "${p}"
    git status -v
  fi
else
  echo
  pwd
  git status -v
fi

EOF

# Iterate all folders that look like a git repo.
find "$xpacks_repo_folder" -maxdepth 3 -type d -name '.git' \
-exec bash "${tmp_file}" {} \;

rm "${tmp_file}"

echo
echo "Done."
echo

# -----------------------------------------------------------------------------
