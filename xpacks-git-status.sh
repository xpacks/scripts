#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Until the XCDL utility will be functional, use this Bash script
# to check the status of the gits in the xPacks repository.
# -----------------------------------------------------------------------------

# Prefer the environment location XPACKS_FOLDER, if defined,
# but default to '.xpacks'.
xpacks_repo_folder="${XPACKS_REPO_FOLDER:-$HOME/.xpacks}"

# -----------------------------------------------------------------------------

helper_script="$xpacks_repo_folder/ilg/scripts.git/xpacks-helper.sh"

# Include common definitions from helper script.
source "${helper_script}"

# -----------------------------------------------------------------------------

cd "$xpacks_repo_folder"
tmp_file="$(mktemp)"
cat <<'EOF' >"${tmp_file}"
cd "$1/.."
b="$(git name-rev --name-only HEAD)"
git diff --exit-code && git diff --cached --exit-code
if [ $? -ne 0 ]
then  
  echo
  pwd
  git status -v
else
  p="$(git log @{push}..)"
  if [ "${p}" != "" ]
  then
    echo
    pwd
    echo "${p}"
    git status -v
  fi
fi

EOF

find "$xpacks_repo_folder" -type d -name '.git' -depth 3 \
-exec bash "${tmp_file}" {} \;

rm "${tmp_file}"

echo
echo "Done."
echo

# -----------------------------------------------------------------------------
