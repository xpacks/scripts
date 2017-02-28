# To be included with source into generate.sh.

# Prefer the environment location XPACKS_REPO_FOLDER, if defined,
# but default to '.xpacks'.
host_uname="$(uname)"
if [ "${host_uname}" == "Darwin" ]
then
  xpacks_repo_folder="${XPACKS_REPO_FOLDER:-$HOME/Library/xPacks}"
  xpacks_cache_folder="${XPACKS_CACHE_FOLDER:-$HOME/Library/Caches/xPacks}"
elif [ "${host_uname}" == "Linux" ]
then
  xpacks_repo_folder="${XPACKS_REPO_FOLDER:-$HOME/.xpacks}"
  xpacks_cache_folder="${XPACKS_CACHE_FOLDER:-$HOME/.cache/xpacks}"
elif [ "${host_uname:0:}" == "MINGW64" ]
then
  xpacks_repo_folder="${XPACKS_REPO_FOLDER:-$HOME/AppData/Roaming/xPacks}"
  xpacks_cache_folder="${XPACKS_CACHE_FOLDER:-$HOME/AppData/Local/Caches/xPacks}"
else
  echo "Not supported host ${host_uname}"
  exit 1
fi

export xpacks_repo_folder
export xpacks_cache_folder
