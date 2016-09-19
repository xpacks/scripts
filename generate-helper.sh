#!/bin/bash
#set -euo pipefail
#IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Bash helper script used in project generate.sh scripts.
# -----------------------------------------------------------------------------

do_process_args() {
  use_development_tree=""
  writable=""

  while [ $# -gt 0 ]
  do
    case "$1" in

      --dev-tree)
        use_development_tree="$2"
        shift 2
        ;;

      --read-write)
        writable="y"
        shift 1
        ;;

      --help)
        echo "Update xPacks."
        echo "Usage:"
        echo "    bash $(basename $0) [--read-write] [--dev-tree absolute-path] [--help]"
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

do_greet() {
  project_name="$(basename $(dirname $(dirname ${script})))"
  echo
  echo "* Generating xPacks for '${project_name}' *"
  if [ -n "$use_development_tree" ]
  then
    echo "Using the development tree '${use_development_tree}'..."
  else
    echo "Using xPacks '${xpacks_repo_folder}'..."
  fi
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
  echo "All files are set read-only and cannot be edited." >>"${generated_folder}/${file_name}"
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
do_prepare_dest() {
  echo
  echo "Processing '$1'..."

  dest_folder="${generated_folder}/$1"
}

# $1 = git path
# $2 = tree path
do_select_pack_folder() {
  if [ -n "${use_development_tree}" ]
  then
    pack_folder="${use_development_tree}/$2"
  else
    pack_folder="${xpacks_repo_folder}/$1"
  fi
}

do_set_cube_folder() {
  cube_folder="$(dirname $(dirname ${script}))/cube-mx"
}

do_create_include() {
  echo "Creating '${dest_folder}/include'..."
  mkdir -p "${dest_folder}/include"
}


do_create_src() {
  if [ $# -ge 1 ]
  then
    echo "Creating '${1}'..."
    mkdir -p "${1}"
  else
    echo "Creating '${dest_folder}/src'..."
    mkdir -p "${dest_folder}/src"
  fi
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

do_add_arm_cmsis_xpack() {
  do_prepare_dest "arm-cmsis-xpack"
  do_select_pack_folder "ilg/arm-cmsis.git" "ilg/arm/arm-cmsis-xpack"

  do_create_include
  cp -r "${pack_folder}/CMSIS/Include"/* "${dest_folder}/include"
}

# -----------------------------------------------------------------------------

do_add_cmsis_plus_xpack() {
  do_prepare_dest "micro-os-plus-xpack"
  do_select_pack_folder "ilg/cmsis-plus.git" "ilg/arm/cmsis-plus-xpack"

  do_create_include
  cp -r "${pack_folder}/include"/* "${dest_folder}/include"

  do_create_src
  cp -r "${pack_folder}/src/diag" "${dest_folder}/src"
  cp -r "${pack_folder}/src/libc" "${dest_folder}/src"
  cp -r "${pack_folder}/src/libcpp" "${dest_folder}/src"
  cp -r "${pack_folder}/src/rtos" "${dest_folder}/src"
  cp -r "${pack_folder}/src/semihosting" "${dest_folder}/src"
  cp -r "${pack_folder}/src/startup" "${dest_folder}/src"
  cp -r "${pack_folder}/src/memory" "${dest_folder}/src"
}

# -----------------------------------------------------------------------------

do_add_micro_os_plus_iii_xpack() {
  do_prepare_dest "micro-os-plus-xpack"
  do_select_pack_folder "ilg/micro-os-plus-iii.git" "ilg/portable/micro-os-plus-xpack"

  mkdir -p "${dest_folder}/include"
  cp -r "${pack_folder}/include"/* "${dest_folder}/include"

  mkdir -p "${dest_folder}/src/rtos/port"
  cp -r "${pack_folder}/src/rtos"/* "${dest_folder}/src/rtos/port"
}

# -----------------------------------------------------------------------------

# $1 = device name suffix (like "stm32f407xx")
do_add_stm32_cmsis_xpack() {
  local device=$(echo $1 | tr '[:upper:]' '[:lower:]')
  local family=${device:5:2}
  local family_uc=$(echo ${family} | tr '[:lower:]' '[:upper:]')

  do_prepare_dest "stm32${family}-cmsis-xpack"
  do_select_pack_folder "ilg/stm32${family}-cmsis.git" "ilg/stm/stm32${family}-cmsis-xpack"

  do_create_include
  cp -r "${pack_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Include/cmsis_device.h" "${dest_folder}/include"
  cp -r "${pack_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Include/stm32${family}xx.h" "${dest_folder}/include"
  cp -r "${pack_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Include/${device}.h" "${dest_folder}/include"
  cp -r "${pack_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Include/system_stm32${family}xx.h" "${dest_folder}/include"

  do_create_src "${dest_folder}/src/startup"
  cp -r "${pack_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Source/Templates/system_stm32${family}xx.c" "${dest_folder}/src/startup"
  cp -r "${pack_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Source/Templates/gcc/vectors_${device}.c" "${dest_folder}/src/startup"
}

# -----------------------------------------------------------------------------

# $1 = device name suffix (like "stm32f407xx")
do_add_stm32_cmsis_drivers_xpack() {
  local device=$(echo $1 | tr '[:upper:]' '[:lower:]')
  local family=${device:5:2}
  local family_uc=$(echo ${family} | tr '[:lower:]' '[:upper:]')

  do_prepare_dest "stm32${family}-cmsis-xpack"
  do_select_pack_folder "ilg/stm32${family}-cmsis.git" "ilg/stm/stm32${family}-cmsis-xpack"

  do_create_src "${dest_folder}/src/drivers"
  cp -r "${pack_folder}/CMSIS/Driver/"* "${dest_folder}/src/drivers"
}

# -----------------------------------------------------------------------------

# $1 = family shortcut (like "f0", "f4", ...)
do_add_stm32_hal_xpack() {
  local family=$(echo $1 | tr '[:upper:]' '[:lower:]')
  local family_uc=$(echo ${family} | tr '[:lower:]' '[:upper:]')

  do_prepare_dest "stm32${family}-hal-xpack"
  do_select_pack_folder "ilg/stm32${family}-hal.git" "ilg/stm/stm32${family}-hal-xpack"

  do_create_include
  cp -r "${pack_folder}/Drivers/STM32${family_uc}xx_HAL_Driver/Inc"/* "${dest_folder}/include"

  do_create_src
  cp -r "${pack_folder}/Drivers/STM32${family_uc}xx_HAL_Driver/Src"/* "${dest_folder}/src"
}

# -----------------------------------------------------------------------------

# $1 = family shortcut (like "f0", "f4", ...)
do_add_stm32_hal_cube() {
  local family=$1
  local family_uc=$(echo ${family} | tr '[:lower:]' '[:upper:]')

  do_prepare_dest "stm32-hal-cube"
  do_set_cube_folder

  do_create_include
  cp -r "${cube_folder}/Drivers/STM32${family_uc}xx_HAL_Driver/Inc"/* "${dest_folder}/include"

  do_create_src
  cp -r "${cube_folder}/Drivers/STM32${family_uc}xx_HAL_Driver/Src"/* "${dest_folder}/src"
}

# -----------------------------------------------------------------------------

# $1 = device name suffix (like "stm32f407xx")
do_add_stm32_cmsis_cube() {
  local device=$(echo $1 | tr '[:upper:]' '[:lower:]')
  local family=${device:5:2}
  local family_uc=$(echo ${family} | tr '[:lower:]' '[:upper:]')

  do_prepare_dest "stm32-cmsis-cube"
  do_set_cube_folder

  do_create_include
  echo "#include \"stm32${family}xx.h\"" >"${dest_folder}/include/cmsis_device.h"
  cp -r "${cube_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Include/stm32${family}xx.h" "${dest_folder}/include"
  cp -r "${cube_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Include/${device}.h" "${dest_folder}/include"
  cp -r "${cube_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Include/system_stm32${family}xx.h" "${dest_folder}/include"

  do_create_src "${dest_folder}/src/startup"
  cp -r "${cube_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Source/Templates/system_stm32${family}xx.c" "${dest_folder}/src/startup"
  do_create_vectors "${cube_folder}/Drivers/CMSIS/Device/ST/STM32${family_uc}xx/Source/Templates/arm/startup_${device}.s" >"${dest_folder}/src/startup/vectors_${device}.c"
}

# -----------------------------------------------------------------------------

