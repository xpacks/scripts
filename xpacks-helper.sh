#!/bin/bash
#set -euo pipefail
#IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Bash helper script used in project generate.sh scripts.
# -----------------------------------------------------------------------------

do_process_args() {
  writable=""
  verbose=""
  link=""
  symlink=""

  while [ $# -gt 0 ]
  do
    case "$1" in

      --read-write)
        writable="y"
        shift 1
        ;;

      --link)
        link="y"
        writable="y"
        shift 1
        ;;

      --symlink)
        link="y"
        writable="y"
        symlink="-s"
        shift 1
        ;;

      --verbose)
        verbose="-v"
        shift 1
        ;;

      --help)
        echo "Update xPacks."
        echo "Usage:"
        echo "    bash $(basename $0) [--symlink|--link] [--read-write] [--help]"
        echo
        exit 1
        ;;

      *)
        echo "Unknown option $1"
        exit 1
        ;;
    esac
  done
}

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
  (cd "$1"; git branch)
}

# Update a single µOS++ xpack.
# $1 = GitHub project name.
do_update_micro_os_plus() {
  do_git_update "${xpacks_repo_folder}/ilg/$1.git" "https://github.com/micro-os-plus/$1.git"
}

# Update a single third party xPack.
# $1 = GitHub project name.
do_update_xpacks() {
  do_git_update "${xpacks_repo_folder}/ilg/$1.git" "https://github.com/xpacks/$1.git"
}

# -----------------------------------------------------------------------------

do_greet() {
  project_name="$(basename $(dirname $(dirname ${script})))"
  echo
  echo "* Generating xPacks for '${project_name}' *"
  echo "Using xPacks from '${xpacks_repo_folder}'..."
  echo
}

do_load_repo() {
  if [ ! -d "${xpacks_repo_folder}" ]
  then
    update_script="$xpacks_repo_folder/ilg/scripts.git/update-xpacks-repo.sh"

    bash "${update_script}"
  fi
}

do_remove_dest() {
  generated_folder="$(dirname $(dirname ${script}))/generated"

  if [ -d "${generated_folder}" ]
  then
    echo "Removing '${generated_folder}'..."

    chmod -R +w "${generated_folder}"
    rm -rf "${generated_folder}"
  fi
}

do_create_dest() {
  local file_name="NON_EDITABLE.txt"
  mkdir -p "${generated_folder}"
  echo "This folder was automatically generated." >"${generated_folder}/${file_name}"
  if [ "$writable" != "y" ]
  then
    echo "All files are set read-only and cannot be edited." >>"${generated_folder}/${file_name}"
  fi
}

do_protect() {
  if [ "$writable" == "y" ]
  then
    echo
    echo "Changing mode to R/W..."
    chmod -R +w "${generated_folder}"
  else
    echo
    echo "Changing mode to R/O..."
    chmod -R -w "${generated_folder}"
  fi
}

do_list() {
  echo
  ls -l "${generated_folder}"
}

do_done() {
  echo
  echo "Done."
}

# $1 = xpack name
do_tell_xpack() {
  echo
  echo "Processing '$1'..."
}

# $1 = xpack name
do_prepare_dest() {
  dest_folder="${generated_folder}/$1"

  echo "Creating '${dest_folder}'..."
  mkdir -p "${dest_folder}"
}

# $1 = git path
do_select_pack_folder() {
  pack_folder="${xpacks_repo_folder}/$1"
}

# $1 = GitHub project name.
do_check_micro_os_plus() {
  if [[ ! -d "${pack_folder}" ]]
  then
    do_update_micro_os_plus $1
  fi
}

# $1 = GitHub project name.
do_check_xpacks() {
  if [[ ! -d "${pack_folder}" ]]
  then
    do_update_xpacks $1
  fi
}

do_set_cube_folder() {
  cube_folder="$(dirname $(dirname ${script}))/cube-mx"
}

# $1 $2 ... source files or folders
# $N destination folder
do_add_content() {
  while [ $# -ge 1 ]
  do 
    local dest="${dest_folder}/$(basename $1)"

    if [ -f "$1" ]
    then
      if [ "${link}" == "y" ]
      then
        ln ${symlink} ${verbose} "$1" "${dest}"
      else
        cp ${verbose} "$1" "${dest}"
      fi
    elif [ -d "$1" ]
    then
      cd "$1"

      # Create all intermediate folders 
      find . -type d -exec mkdir -pv "${dest}"/{} \;

      if [ "${link}" == "y" ]
      then
        find . -type f -exec ln ${symlink} ${verbose} "$1"/{} "${dest}"/{} \;
      else
        find . -type f -exec cp ${verbose} "$1"/{} "${dest}"/{} \;
      fi
    else
      echo "Not supported content $1"
      exit 1
    fi

    shift
  done
}


# -----------------------------------------------------------------------------

# $1 = source file (ARM startup_stm32*.s)
# $2 = destination file (vectors_stm32*.c)
do_create_vectors() {

TAB=$'\t'
TMP_FILE=$(mktemp -q /tmp/cmsis_vectors.XXXXXX)

cat "$1" | \
sed -n -e '/^__Vectors/,/^__Vectors_End/p' | \
sed -e '/^__Vectors_End/,$d' | \
sed -e '1,16d' | \
sed -e 's/__Vectors//' | \
sed -E 's/[[:space:]]*DCD[[:space:]]*//' | \
sed -E 's/[[:space:]]+$//' \
> "${TMP_FILE}"

cat <<EOF
/*
 * This file is part of the µOS++ distribution.
 *   (https://github.com/micro-os-plus)
 * Copyright (c) 2016 Liviu Ionescu.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom
 * the Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

// ----------------------------------------------------------------------------

#include <cmsis_device.h>

// ----------------------------------------------------------------------------

extern void
Reset_Handler (void);

extern void
NMI_Handler (void);

extern void
HardFault_Handler (void);

#if defined(__ARM_ARCH_7M__) || defined(__ARM_ARCH_7EM__)

extern void
MemManage_Handler (void);

extern void
BusFault_Handler (void);

extern void
UsageFault_Handler (void);

extern void
DebugMon_Handler (void);

#endif // defined(__ARM_ARCH_7M__) || defined(__ARM_ARCH_7EM__)

extern void
SVC_Handler (void);

extern void
PendSV_Handler (void);

extern void
SysTick_Handler (void);

// ----------------------------------------------------------------------------

void __attribute__((weak))
Default_Handler(void);

// Forward declaration of the specific IRQ handlers. These are aliased
// to the Default_Handler, which is a 'forever' loop. When the application
// defines a handler (with the same name), this will automatically take
// precedence over these weak definitions

// The list of external handlers is obtained by parsing the
// ARM assembly startup file.

EOF

cat "${TMP_FILE}" | \
sed -e '/^0/d' | \
sed -E '/^[[:space:]]+/d' | \
sed -e '/^$/d' | \
sed -E 's/[[:space:]]+[;] .*$//' | \
sed -e 's/.*/void __attribute__ ((weak, alias ("Default_Handler")))\
&(void);/'

echo

cat <<EOF
// ----------------------------------------------------------------------------

extern unsigned int _estack;

typedef void
(* const handler_ptr)(void);

// ----------------------------------------------------------------------------

// The table of interrupt handlers. It has an explicit section name
// and relies on the linker script to place it at the correct location
// in memory.

__attribute__ ((section(".isr_vector"),used))
handler_ptr __isr_vectors[] =
  {
    // Cortex-M Core Handlers
    (handler_ptr) &_estack,            // The initial stack pointer
    Reset_Handler,                     // The reset handler

    NMI_Handler,                       // The NMI handler
    HardFault_Handler,                 // The hard fault handler

#if defined(__ARM_ARCH_7M__) || defined(__ARM_ARCH_7EM__)
    MemManage_Handler,                 // The MPU fault handler
    BusFault_Handler,                  // The bus fault handler
    UsageFault_Handler,                // The usage fault handler
#else
    0,                                 // Reserved
    0,                                 // Reserved
    0,                                 // Reserved
#endif
    0,                                 // Reserved
    0,                                 // Reserved
    0,                                 // Reserved
    0,                                 // Reserved
    SVC_Handler,                       // SVCall handler
#if defined(__ARM_ARCH_7M__) || defined(__ARM_ARCH_7EM__)
    DebugMon_Handler,                  // Debug monitor handler
#else
    0,                                 // Reserved
#endif
    0,                                 // Reserved
    PendSV_Handler,                    // The PendSV handler
    SysTick_Handler,                   // The SysTick handler

    // ------------------------------------------------------------------------
EOF

cat "${TMP_FILE}" | \
sed -E '/^[[:space:]]*$/d' | \
sed -E 's/^[[:space:]]*;/;/' | \
sed -e 's/^0/0,/' | \
sed -e 's/_IRQHandler/_IRQHandler,/' | \
sed -e 's/;/\/\//' | \
sed -e 's/^/    /'

cat <<EOF
};

// ----------------------------------------------------------------------------

// Processor ends up here if an unexpected interrupt occurs or a
// specific handler is not present in the application code.
// When in DEBUG, trigger a debug exception to clearly notify
// the user of the exception and help identify the cause.

void __attribute__ ((section(".after_vectors")))
Default_Handler(void)
{
#if defined(DEBUG)
#if defined(__ARM_ARCH_7M__) || defined(__ARM_ARCH_7EM__)
  if ((CoreDebug->DHCSR & CoreDebug_DHCSR_C_DEBUGEN_Msk) != 0)
    {
      __BKPT (0);
    }
#else
  __BKPT (0);
#endif /* defined(__ARM_ARCH_7M__) || defined(__ARM_ARCH_7EM__) */
#endif /* defined(DEBUG) */

  while (1)
    {
      ;
    }
}

// ----------------------------------------------------------------------------
EOF

rm "${TMP_FILE}"
}

# -----------------------------------------------------------------------------

# Optional arguments: 'driver'.
do_add_arm_cmsis_xpack() {
  local pack_name='arm-cmsis'
  do_tell_xpack "${pack_name}-xpack"

  do_select_pack_folder "ilg/${pack_name}.git"
  do_check_xpacks "${pack_name}"

  # Always add 'core'.
  do_prepare_dest "${pack_name}/include/core"
  do_add_content "${pack_folder}/CMSIS/Include"/*

  while [ $# -ge 1 ]
  do
    case $1 in
    driver)
      do_prepare_dest "${pack_name}/include/driver"
      do_add_content "${pack_folder}/CMSIS/Driver/Include"/*
      ;;
    esac
    shift
  done
}

# -----------------------------------------------------------------------------

# Optional args: src folders, like posix-io, driver
do_add_micro_os_plus_iii_xpack() {
  local pack_name='micro-os-plus-iii'
  do_tell_xpack "${pack_name}-xpack"

  do_select_pack_folder "ilg/${pack_name}.git"
  do_check_micro_os_plus "${pack_name}"

  # Exception to the rule, folder is micro-os-plus, not cmsis-plus; 
  # The package will be renamed.
  do_prepare_dest "${pack_name}/include"
  do_add_content "${pack_folder}/include"/* 

  do_prepare_dest "${pack_name}/src"
  do_add_content "${pack_folder}/src/diag" 
  do_add_content "${pack_folder}/src/libc" 
  do_add_content "${pack_folder}/src/libcpp" 
  do_add_content "${pack_folder}/src/rtos" 
  do_add_content "${pack_folder}/src/semihosting" 
  do_add_content "${pack_folder}/src/startup" 
  do_add_content "${pack_folder}/src/memory" 
  do_add_content "${pack_folder}/src/utils" 

  while [ $# -ge 1 ]
  do
    do_add_content "${pack_folder}/src/$1" 
    shift
  done
}

# -----------------------------------------------------------------------------

do_add_micro_os_plus_iii_cortexm_xpack() {
  local pack_name='micro-os-plus-iii-cortexm'
  do_tell_xpack "${pack_name}-xpack"

  do_select_pack_folder "ilg/${pack_name}.git"
  do_check_micro_os_plus "${pack_name}"

  # Exception, folder with diferent name;
  # Package to be renamed.
  do_prepare_dest "${pack_name}/include"
  do_add_content "${pack_folder}/include"/* 

  do_prepare_dest "${pack_name}/src"
  do_add_content "${pack_folder}/src"/* 
}

# -----------------------------------------------------------------------------

# $1 = device name suffix (like "stm32f407xx")
do_add_stm32_cmsis_xpack() {
  local device=$(echo $1 | tr '[:upper:]' '[:lower:]')
  local family=${device:5:2}
  local family_uc=$(echo ${family} | tr '[:lower:]' '[:upper:]')

  local pack_name="stm32${family}-cmsis"
  do_tell_xpack "${pack_name}-xpack"

  do_select_pack_folder "ilg/${pack_name}.git"
  do_check_xpacks "${pack_name}"

  do_prepare_dest "${pack_name}/include/${device}"
  do_add_content "${pack_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Include/cmsis_device.h" 
  do_add_content "${pack_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Include/stm32${family}xx.h" 
  do_add_content "${pack_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Include/${device}.h" 
  do_add_content "${pack_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Include/system_stm32${family}xx.h" 

  do_prepare_dest "${pack_name}/src/${device}"
  do_add_content "${pack_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Source/Templates/system_stm32${family}xx.c" 
  do_add_content "${pack_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Source/Templates/gcc/vectors_${device}.c" 
}

# -----------------------------------------------------------------------------

# $1 = family name (like "f0", "f4", ...)
do_add_stm32_cmsis_driver_xpack() {
  local family=$(echo $1 | tr '[:upper:]' '[:lower:]')

  local pack_name="stm32${family}-cmsis"
  do_tell_xpack "${pack_name}-xpack"

  do_select_pack_folder "ilg/${pack_name}.git"
  do_check_xpacks "${pack_name}"

  do_prepare_dest "${pack_name}/src/driver"
  do_add_content "${pack_folder}/CMSIS/Driver/"* 

  echo "Removing '${dest_folder}/Config'..."
  rm -rf "${dest_folder}/Config"
}

# -----------------------------------------------------------------------------

# $1 = family shortcut (like "f0", "f4", ...)
do_add_stm32_hal_xpack() {
  local family=$(echo $1 | tr '[:upper:]' '[:lower:]')
  local family_uc=$(echo ${family} | tr '[:lower:]' '[:upper:]')

  local pack_name="stm32${family}-hal"

  do_tell_xpack "${pack_name}-xpack"

  do_select_pack_folder "ilg/${pack_name}.git"
  do_check_xpacks "${pack_name}"

  do_prepare_dest "${pack_name}/include"
  do_add_content "${pack_folder}/Drivers/STM32${family_uc}xx_HAL_Driver/Inc"/* 

  do_prepare_dest "${pack_name}/src"
  do_add_content "${pack_folder}/Drivers/STM32${family_uc}xx_HAL_Driver/Src"/* 

  echo "Removing '${dest_folder}/*_template.c'..."
  rm "${dest_folder}/"*_template.c
}

# -----------------------------------------------------------------------------

# $1 = device name suffix (like "stm32f407xx")
do_add_stm32_cmsis_cube() {
  local device=$(echo $1 | tr '[:upper:]' '[:lower:]')
  local family=${device:5:2}
  local family_uc=$(echo ${family} | tr '[:lower:]' '[:upper:]')

  local pack_name="stm32${family}-cmsis"
  do_tell_xpack "${pack_name}-cube"

  do_set_cube_folder

  do_prepare_dest "${pack_name}/include/${device}"
  echo "#include \"stm32${family}xx.h\"" >"${dest_folder}/cmsis_device.h"
  do_add_content "${cube_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Include/stm32${family}xx.h" 
  do_add_content "${cube_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Include/${device}.h" 
  do_add_content "${cube_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Include/system_stm32${family}xx.h" 

  do_prepare_dest "${pack_name}/src/${device}"
  do_add_content "${cube_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Source/Templates/system_stm32${family}xx.c" 
  do_create_vectors "${cube_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Source/Templates/arm/startup_${device}.s" >"${dest_folder}/vectors_${device}.c"
}

# -----------------------------------------------------------------------------

# $1 = family shortcut (like "f0", "f4", ...)
do_add_stm32_hal_cube() {
  local family=$1
  local family_uc=$(echo ${family} | tr '[:lower:]' '[:upper:]')

  local pack_name="stm32${family}-hal"

  do_tell_xpack "${pack_name}-cube"

  do_set_cube_folder

  do_prepare_dest "${pack_name}/include"
  do_add_content "${cube_folder}/Drivers/STM32${family_uc}xx_HAL_Driver/Inc"/* 

  do_prepare_dest "${pack_name}/src"
  do_add_content "${cube_folder}/Drivers/STM32${family_uc}xx_HAL_Driver/Src"/* 

  echo "Removing '${dest_folder}/*_template.c'..."
  rm "${dest_folder}/"*_template.c
}

# -----------------------------------------------------------------------------

