# This file must be included with source into generate.sh, 
# and not executed separately.

# Prefer the environment locations XPACKS_REPO_FOLDER/XPACKS_CACHE_FOLDER, 
# if defined, otherwise default to platform specific locations.
host_uname="$(uname)"
if [ "${host_uname}" == "Darwin" ]
then
  xpacks_repo_folder_path="${XPACKS_REPO_FOLDER:-$HOME/Library/xPacks}"
  xpacks_cache_folder_path="${XPACKS_CACHE_FOLDER:-$HOME/Library/Caches/xPacks}"
elif [ "${host_uname}" == "Linux" ]
then
  xpacks_repo_folder_path="${XPACKS_REPO_FOLDER:-$HOME/.xpacks}"
  xpacks_cache_folder_path="${XPACKS_CACHE_FOLDER:-$HOME/.cache/xpacks}"
elif [ "${host_uname:0:7}" == "MINGW64" ]
then
  xpacks_repo_folder_path="${XPACKS_REPO_FOLDER:-$HOME/AppData/Roaming/xPacks}"
  xpacks_cache_folder_path="${XPACKS_CACHE_FOLDER:-$HOME/AppData/Local/Caches/xPacks}"
else
  echo "${host_uname} not supported"
  exit 1
fi

export xpacks_repo_folder_path
export xpacks_cache_folder_path

# -----------------------------------------------------------------------------

# The generate.sh scripts do not define the helper, so enter it as default.
helper_file_name="${helper_file_name:-xpacks-helper.sh}"
helper_path="${xpacks_repo_folder_path}/ilg/scripts.git/${helper_file_name}"

# Check if the helper is present.
if [ ! -f "${helper_path}" ]
then
  mkdir -p "${HOME}/Downloads"
  echo "Downloading bootstrap.sh..."
  curl -L https://github.com/xpacks/scripts/raw/master/bootstrap.sh -o "${HOME}/Downloads/bootstrap.sh"
  bash "${HOME}/Downloads/bootstrap.sh"
fi

# -----------------------------------------------------------------------------

# Include common definitions from the helper script.
source "${helper_path}"
