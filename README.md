# Scripts

Various scripts used for processing the xPacks.

## `run-tests.sh`

Run all tests defined for the current package.

Must be executed in the package root folder.

## `convert-arm-asm.sh`

Convert an ARM assembly startup file to a format like the `vectors_*.c` file.

Basically a sequence of `sed` scripts. Output on `stdout`.

## `generate-vectors-from-arm-startup.sh`

Iterate a folder where ARM assembly startup files are located and
convert one by one to a similar name but in `vectors_*.c` format.

The new files are stored in the configurable destination folder.
