#!/bin/bash
#set -euo pipefail
#IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Bash helper script used in project generate.sh scripts.
# -----------------------------------------------------------------------------

# Include all 'xpacks-scripts.sh'
source_tmp_file="$(mktemp)"

# DEPRECATED (the source command is done inside do_install_xpack())
_do_source_distributed_scripts() {
  find "$xpacks_repo_folder" -maxdepth 4 -type f -name 'xpacks-helper.sh' -print \
    | sed -e '/ilg\/scripts.git\/xpacks-helper.sh/d' \
    | sed -n -e '/scripts\/xpacks-helper.sh/p' \
    | sed -e 's/.*/source "&"/' > ${source_tmp_file}

  source "${source_tmp_file}"
  rm "${source_tmp_file}"
}

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

# If an xPack is not present, clone it.
# $1 = project name
# $2 = author is (like "ilg")
# $3 = project url
do_install_xpack() {
  if [ $# -lt 3 ]
  then
    echo "do_install_xpack() requires 3 params"
    exit 1
  fi

  local dst=${xpacks_repo_folder}/$2/$1.git
  echo "Checking '$1'..."
  if [ ! -d "${dst}" ]
  then
    git clone "$3" "${dst}"
    (cd "${dst}"; git branch)
  fi

  if [ -f "${dst}/scripts/xpacks-helper.sh" ]
  then
    source "${dst}/scripts/xpacks-helper.sh"
  fi
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
  generated_orig_folder="$(dirname $(dirname ${script}))/generated"
  generated_folder="${generated_orig_folder}.tmp"

  if [ -d "${generated_folder}" ]
  then
    echo
    echo "Removing '${generated_folder}'..."

    chmod -R +w "${generated_folder}"
    rm -rf "${generated_folder}"
  fi
}

do_create_dest() {
  local file_name="NON_EDITABLE.txt"
  mkdir -p ${verbose} "${generated_folder}"
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
    chmod -R +w "${generated_folder}"/*
  else
    echo
    echo "Changing mode to R/O..."
    chmod -R -w "${generated_folder}"/*
  fi
}

do_list() {
  echo
  ls -l "${generated_folder}"
}

do_done() {

  # Remove original generated folder.
  if [ -d "${generated_orig_folder}" ]
  then
    rm -rf "${generated_orig_folder}"
  fi

  # Rename the generated.net -> generated.
  echo
  echo Renaming $(basename "${generated_folder}") "->" $(basename "${generated_orig_folder}")...
  mv "${generated_folder}" "${generated_orig_folder}"

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
  mkdir -p ${verbose} "${dest_folder}"
}

# $1 = git path
do_select_pack_folder() {
  pack_folder="${xpacks_repo_folder}/$1"
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
      find . -type d -exec mkdir -p ${verbose} "${dest}"/{} \;

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
