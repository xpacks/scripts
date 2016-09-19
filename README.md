# Scripts

Various scripts used for processing the xPacks.

These scripts were created on macOS, and the ones suffixed with `.command` are specific to macOS; the `.sh` scripts should also be fine on GNU/Linux, Windows MSYS2, and on the new [Windows Subsystem for Linux](https://msdn.microsoft.com/commandline/wsl/about).

For those who insist on native Windows, separate PowerShell scripts would be required, but considering Microsoft's move towards Linux, this would probably not be worth the effort. Anyway, if you manage to create them, please consider improving your karma and contribute them back to the community.

## Environment variables

### XPACKS\_REPO\_FOLDER

Set this variable to the location where you want the xPacks repo to be stored. For example:

```
XPACKS_REPO_FOLDER=$USER/my-special-xpacks-folder
```

If not defined, the default folder is `~/.xpacks`:

```
XPACKS_REPO_FOLDER=$USER/.xpacks
```

Please be aware that on macOS, this folder, having a name that starts with a dot, is not visible by default in Finder; to make it visible the following command must be executed in a terminal:

```
chflags nohidden ~/.xpacks
```

## bootstrap.sh

This initial script downloads the GitHub [`xpacks/scripts`](https://github.com/xpacks/scripts) project into `XPACKS_REPO_FOLDER`, to provide access to further scripts.

Download [bootstrap.sh](https://github.com/xpacks/scripts/blob/master/bootstrap.sh) to a folder of your choice and run it via Bash in a terminal. For example:

```
curl -L https://github.com/xpacks/scripts/raw/master/bootstrap.sh -o ~/Downloads/bootstrap.sh
bash  ~/Downloads/bootstrap.sh
```

The result should be a folder like `~/.xpacks/ilg/scripts.git/` containing several other scripts.

## update-xpacks-repo.sh

This script will download the existing xPacks into the `XPACKS_REPO_FOLDER`. 

For now, the format is the original Git, but separate versions will be added as the XCDL tool will be available.

During the first run, the repositories will be cloned locally.

Subsequent runs will update the xPacks to their latest commits.

If, for one reason or another, it is necessary to stick with one older commit for a specific repository, after the initial clone, temporarily comment out the `do_update_*` line to avoid further updates.

## update-xpacks-repo.mac.command

Wrapper for macOS; execute it by double clicking in Finder.

## Deprecated

### run-tests.sh

Run all tests defined for the current package.

Must be executed in the package root folder.

### convert-arm-asm.sh

Convert an ARM assembly startup file to a format like the `vectors_*.c` file.

Basically a sequence of `sed` scripts. Output on `stdout`.

### generate-vectors-from-arm-startup.sh

Iterate a folder where ARM assembly startup files are located and
convert one by one to a similar name but in `vectors_*.c` format.

The new files are stored in the configurable destination folder.
