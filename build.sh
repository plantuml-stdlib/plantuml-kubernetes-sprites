#!/usr/bin/env bash

set -o errexit  # Exit script when a command exits with non-zero status.
set -o errtrace # Exit on error inside any functions or sub-shells.
set -o nounset  # Exit script on use of an undefined variable.
set -o pipefail # Return exit status of the last command in the pipe that exited with a non-zero status.

: "${PLANTUML:=java -jar plantuml.jar}"

# Simple usage example:
#
#   $0 ./src ./out
build_diagrams() {
    local sFilename sFormat sInputPath sOutputPath

    sInputPath="${1?Two parameters required: <input-path> <output-path> [format]}"
    sOutputPath="${2?Two parameters required: <input-path> <output-path> [format]}"
    readonly sFormat="${3:-png}"

    sInputPath="$(realpath "${sInputPath}")"
    readonly sInputPath

    if [[ ! -d ${sInputPath} ]]; then
        echo "Error: Input path '${sInputPath}' does not exist" >&2
        exit 1
    fi

    sOutputPath="$(realpath "${sOutputPath}")"
    readonly sOutputPath

    mkdir -p "${sOutputPath}"

    find "${sInputPath}" -name "*.puml" -type f -print0 | while IFS= read -r -d $'\0' sFilename; do
        echo " =====> Building ${sFilename}"

        ${PLANTUML} \
            -format "${sFormat}" \
            -output "${sOutputPath}" \
            -verbose \
            "${sFilename}"
    done
}

if [[ ${BASH_SOURCE[0]} != "${0}" ]]; then
    export -f build_diagrams
else
    build_diagrams "$@"
fi
