#! /bin/bash
set -euo pipefail
IFS=$'\n\t'

#
# This file is part of the µOS++ distribution.
#   (https://github.com/micro-os-plus)
# Copyright (c) 2015-2023 Liviu Ionescu.  All rights reserved.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
#
# If a copy of the license was not distributed with this file, it can
# be obtained from https://opensource.org/licenses/mit/.
#
# -----------------------------------------------------------------------------

#
# Script to run all tests in the current package.
#

if [ ! -f xpack.json ]
then
	echo "Must be started in a package root folder."
	exit 1
fi

PROJECT_FOLDER=$(pwd)

# This subfolder will be created in the folder where this script runs.
TEST_SUBFOLDER="${PROJECT_FOLDER}/build/tests"

# $1 = test name
# $2 = test folder
function run_test {
    echo
    echo "Testing \"$1\"..."
    TEST_FOLDER="${TEST_SUBFOLDER}/$1"

    mkdir -p "${TEST_FOLDER}"
    cp $2/* "${TEST_FOLDER}"
    for f in "${PROJECT_FOLDER}/test/"*.mk "${PROJECT_FOLDER}/tests/"*.mk
    do
      if [ -f "$f" ]
      then
        cp "$f" "${TEST_FOLDER}"
      fi
	done

    # If the test folder has a 'makefile', run it.
    make --directory="${TEST_FOLDER}" PARENT="${PROJECT_FOLDER}" TEST_NAME="$1" all

    echo
    echo "Testing \"$1\" done."
}

# Clean all previous tests.
rm -rf "${TEST_SUBFOLDER}"

if [ -f "${PROJECT_FOLDER}/test/makefile" ]
then
  run_test "root" "test"
fi

if [ -f "${PROJECT_FOLDER}/tests/makefile" ]
then
  run_test "top" "tests"
fi

for f in test/* tests/*
do
  if [ \( -d "$f" \) -a \( -f "$f/makefile" \) ]
  then
    TEST_NAME=$(basename "$f")
    run_test "${TEST_NAME}" $f
  fi
done

