# This file must be included with source into generate.sh, 
# and not executed separately.

# Prefer the environment locations XPACKS_REPO_FOLDER/XPACKS_CACHE_FOLDER, 
# if defined, otherwise default to platform specific locations.
host_uname="$(uname)"
if [ "${host_uname}" == "Darwin" ]
then
  xpacks_repo_folder="${XPACKS_REPO_FOLDER:-$HOME/Library/xPacks}"
  xpacks_cache_folder="${XPACKS_CACHE_FOLDER:-$HOME/Library/Caches/xPacks}"
elif [ "${host_uname}" == "Linux" ]
then
  xpacks_repo_folder="${XPACKS_REPO_FOLDER:-$HOME/.xpacks}"
  xpacks_cache_folder="${XPACKS_CACHE_FOLDER:-$HOME/.cache/xpacks}"
elif [ "${host_uname:0:6}" == "MINGW64" ]
then
  xpacks_repo_folder="${XPACKS_REPO_FOLDER:-$HOME/AppData/Roaming/xPacks}"
  xpacks_cache_folder="${XPACKS_CACHE_FOLDER:-$HOME/AppData/Local/Caches/xPacks}"
else
  echo "${host_uname} not supported"
  exit 1
fi

export xpacks_repo_folder
export xpacks_cache_folder
