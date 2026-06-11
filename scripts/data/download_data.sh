#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2010-2026 MNE-CPP Authors
#
# This script downloads the MNE-CPP test data and sample data into
# the resources/data directory. Compatible with macOS and Linux.
#
# Usage:
#   ./download_data.sh [all] [test-data] [sample-data] [help]
#
# This file is part of the MNE-CPP project.
# For more information visit: https://mne-cpp.github.io/

set -euo pipefail

EXIT_FAIL=1
EXIT_SUCCESS=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
RESOURCES_DIR="${BASE_DIR}/resources"
DATA_DIR="${RESOURCES_DIR}/data"

DOWNLOAD_TEST_DATA="false"
DOWNLOAD_SAMPLE_DATA="false"
PRINT_HELP="false"

do_print_help() {
    cat <<EOF
MNE-CPP download data script (macOS / Linux).

Downloads the test and sample data sets into \`resources/data\`.

Usage: ./download_data.sh [Options]

Options:
  all          Download all datasets
  test-data    Download the mne-cpp-test-data repository
  sample-data  Download the MNE sample data set
  help         Show this help message

Examples:
  ./download_data.sh all
  ./download_data.sh test-data
  ./download_data.sh sample-data

Output directory:
  ${DATA_DIR}
EOF
}

do_print_configuration() {
    cat <<EOF
========================================================================
======================== MNE-CPP DOWNLOAD DATA ========================

 Script path       : ${SCRIPT_DIR}
 Base directory    : ${BASE_DIR}
 Resources dir     : ${RESOURCES_DIR}
 Output (data) dir : ${DATA_DIR}

 Download test data   : ${DOWNLOAD_TEST_DATA}
 Download sample data : ${DOWNLOAD_SAMPLE_DATA}

========================================================================
========================================================================

EOF
}

# ----- argument parsing --------------------------------------------------------

if [ $# -eq 0 ]; then
    PRINT_HELP="true"
fi

for arg in "$@"; do
    case "${arg}" in
        all)
            DOWNLOAD_TEST_DATA="true"
            DOWNLOAD_SAMPLE_DATA="true"
            ;;
        test-data)
            DOWNLOAD_TEST_DATA="true"
            ;;
        sample-data)
            DOWNLOAD_SAMPLE_DATA="true"
            ;;
        help|--help|-h)
            PRINT_HELP="true"
            ;;
        *)
            echo "Unknown option: ${arg}" >&2
            do_print_help >&2
            exit ${EXIT_FAIL}
            ;;
    esac
done

if [ "${PRINT_HELP}" == "true" ]; then
    do_print_help
    exit ${EXIT_SUCCESS}
fi

do_print_configuration

mkdir -p "${DATA_DIR}"

# ----- download test-data ------------------------------------------------------

if [ "${DOWNLOAD_TEST_DATA}" == "true" ]; then
    TEST_DATA_DIR="${DATA_DIR}/mne-cpp-test-data"
    if [ -d "${TEST_DATA_DIR}" ]; then
        echo "[test-data] Already exists: ${TEST_DATA_DIR}. Skipping git clone."
    else
        echo "[test-data] Cloning mne-cpp-test-data into ${TEST_DATA_DIR} ..."
        git clone https://github.com/mne-tools/mne-cpp-test-data.git "${TEST_DATA_DIR}"
        echo "[test-data] Done."
    fi
fi

# ----- download sample-data ----------------------------------------------------

if [ "${DOWNLOAD_SAMPLE_DATA}" == "true" ]; then
    SAMPLE_DATA_DIR="${DATA_DIR}/MNE-sample-data"
    SAMPLE_DATA_URL="https://files.osf.io/v1/resources/rxvq7/providers/osfstorage/59c0e26f9ad5a1025c4ab159?action=download&direct&version=6"
    TARBALL="${DATA_DIR}/MNE-sample-data.tar.gz"

    if [ -d "${SAMPLE_DATA_DIR}" ]; then
        echo "[sample-data] Already exists: ${SAMPLE_DATA_DIR}. Skipping download."
    else
        echo "[sample-data] Downloading MNE-sample-data.tar.gz ..."
        curl -fSL --retry 3 --retry-delay 2 -o "${TARBALL}" "${SAMPLE_DATA_URL}"

        echo "[sample-data] Extracting ..."
        tar -xzf "${TARBALL}" -C "${DATA_DIR}"

        # Create symlinks so the BEM surfaces resolve correctly
        # (equivalent of Windows `mklink /D` in the original .bat script)
        BEM_DIR="${SAMPLE_DATA_DIR}/subjects/sample/bem"
        FLASH_DIR="${BEM_DIR}/flash"
        if [ -d "${FLASH_DIR}" ]; then
            echo "[sample-data] Creating BEM surface symlinks ..."
            ln -sfn "${FLASH_DIR}/inner_skull.surf" "${BEM_DIR}/inner_skull.surf"
            ln -sfn "${FLASH_DIR}/outer_skull.surf" "${BEM_DIR}/outer_skull.surf"
            ln -sfn "${FLASH_DIR}/outer_skin.surf"  "${BEM_DIR}/outer_skin.surf"
        else
            echo "[sample-data] Warning: flash directory not found at ${FLASH_DIR};" \
                 "skipping BEM symlinks." >&2
        fi

        echo "[sample-data] Cleaning up tarball ..."
        rm -f "${TARBALL}"
        echo "[sample-data] Done."
    fi
fi

echo ""
echo "All requested data is ready in ${DATA_DIR}."
exit ${EXIT_SUCCESS}
