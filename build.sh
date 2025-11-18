#!/usr/bin/env bash

# ==============================================================================
# There are a few standards this code tries to adhere to, these are listed below.
#
# - Code follows the BASH style-guide described at:
#   http://guides.dealerdirect.io/code-styling/bash/
#
# - Variables are named using an adaption of Systems Hungarian explained at:
#   http://blog.pother.ca/VariableNamingConvention
# ==============================================================================

set -o errexit  # Exit script when a command exits with non-zero status.
set -o errtrace # Exit on error inside any functions or sub-shells.
set -o nounset  # Exit script on use of an undefined variable.
set -o pipefail # Return exit status of the last command in the pipe that exited with a non-zero status.

: "${PLANTUML:=java -jar plantuml.jar}"

# ==============================================================================
# Exit codes
# ------------------------------------------------------------------------------
: readonly -i "${EXIT_OK:=0}"
: readonly -i "${EXIT_NOT_ENOUGH_PARAMETERS:=65}"
: readonly -i "${EXIT_INVALID_PARAMETER:=66}"
: readonly -i "${EXIT_COULD_NOT_FIND_FILE:=74}"
: readonly -i "${EXIT_COULD_NOT_CREATE_DIRECTORY:=76}"
: readonly -i "${EXIT_COULD_NOT_FIND_DIRECTORY:=75}"
: readonly -i "${EXIT_NOT_CORRECT_TYPE:=81}"
# ------------------------------------------------------------------------------
# Foreground colors
# ------------------------------------------------------------------------------
: readonly "${COLOR_RED:=$(tput setaf 1)}"
: readonly "${COLOR_WHITE:=$(tput setaf 7)}"
# ------------------------------------------------------------------------------
# Text attributes
# ------------------------------------------------------------------------------
: readonly "${TEXT_BOLD:=$(tput bold)}" # turn on bold (extra bright) mode
: readonly "${TEXT_DIM:=$(tput dim)}"   # turn on half-bright mode
# ------------------------------------------------------------------------------
: readonly "${RESET_TEXT:=$(tput sgr0)}" # turn off all attributes
# ==============================================================================

# ==============================================================================
#                       PlantUML Diagram Builder Script
# ------------------------------------------------------------------------------
## Build PlantUML diagrams from .puml files in a given source directory and output
## them to the given target directory.
##
## Usage:   $0 [options] <input-path> <output-path>
##
## Where:
##     <input-path>  - Directory containing .puml files to be processed.
##     <output-path> - Directory where the generated diagrams will be saved.
##
## Options:
##     -f | --format    Specify the output format (png, svg, etc.)
##     -h | --help      Print this help dialogue and exit
##
## If no format is specified, 'png' will be used by default.
##
## By default, a 'plantuml.jar' is expected to be present in the directory this script is run from.
## A custom PlantUML command can be set using the PLANTUML environment variable.
##
## Simple usage example:
##
##     $0 ./src ./out
##
## Usage examples with different format:
##
##     $0 --format 'svg' ./src ./out
##
## Usage example using custom PlantUML command:
##
##     PLANTUML="java -DPLANTUML_LIMIT_SIZE=8192 -jar /path/to/plantuml.jar" $0 ./src ./out
##

error() {
    if [ ${#} -eq 1 ]; then
        logMessage "ERROR" "${COLOR_RED}" "${@}" "Call with ${TEXT_BOLD}--help${RESET_TEXT}${TEXT_DIM} for more information." >&2
    else
        logMessage "ERROR" "${COLOR_RED}" "${@}" >&2
    fi
}

logMessage() {
    local sColor sMessage sPrefix sType

    readonly sType="${1?Three parameters required: <type> <color> <message>}"
    readonly sColor="${2?Three parameters required: <type> <color> <message>}"
    sMessage="${3?Three parameters required: <type> <color> <message>}"

    sPrefix="${COLOR_WHITE}[${sColor}${sType}${COLOR_WHITE}]${RESET_TEXT}"

    message "${sPrefix}" "${sMessage}"

    # Each additional parameter will be treated as extra information to display with the error
    if [[ $# -gt 3 ]]; then
        shift 3
        for sMessage in "$@"; do
            message "        " "${TEXT_DIM}${sMessage}${RESET_TEXT}"
        done
    fi
}

message() {
    local sMessage sPrefix

    readonly sPrefix="${1?Two parameters required: <message-prefix> <message>}"
    readonly sMessage="${2?Two parameters required: <message-prefix> <message>}"

    echo -e "${sPrefix} ${sMessage}"
}

statusMessage() {
    message " -----> " "${@}" >&2
}

topicMessage() {
    message " =====> " "${@}" >&2
}

usage() {
    local sScript sUsage

    sScript="$(basename "$0")"
    readonly sScript

    sUsage="$(grep '^##' < "$0" | cut -c4-)"
    readonly sUsage

    echo -e "${sUsage//\$0/${sScript}}\n"
}

build_diagrams() {
    build() {
        local sFilename sFileType sFormat sInputPath sOutputPath sSearch

        readonly sInputPath="${1?Three parameters required: <input-path> <output-path> <format>}"
        readonly sOutputPath="${2?Three parameters required: <input-path> <output-path> <format>}"
        readonly sFormat="${3?Three parameters required: <input-path> <output-path> <format>}"
        readonly sFileType='puml'

        readonly sSearch="*.${sFileType}"

        local -i iTotalFiles
        iTotalFiles=$(find "${sInputPath}" -name "${sSearch}" -type f | wc -l)

        if [[ ${iTotalFiles} -eq 0 ]]; then
            error "No '${sSearch}' files found in '${sInputPath}'" >&2
            exit "${EXIT_COULD_NOT_FIND_FILE}"
        else
            topicMessage "Found ${iTotalFiles} .${sFileType} files to process in '${sInputPath}'"

            find "${sInputPath}" -name "*.${sFileType}" -type f -print0 | while IFS= read -r -d $'\0' sFilename; do
                statusMessage "Building ${sFilename}"

                # @TODO: Make verbose a command flag of the outer script
                ${PLANTUML} \
                    -t"${sFormat}" \
                    -output "${sOutputPath}" \
                    -verbose \
                    "${sFilename}"
            done
        fi
    }

    validatePath() {
        local sPath

        readonly sPath="${1?One parameter required: <path>}"

        if [[ ! -e ${sPath} ]]; then
            error "$(printf "Provided path '%s' does not exist" "${sPath}")"
            return "${EXIT_COULD_NOT_FIND_DIRECTORY}"
        elif [[ ! -d ${sPath} ]]; then
            error "$(printf "Provided path '%s' is not a directory" "${sPath}")"
            return "${EXIT_NOT_CORRECT_TYPE}"
        else
            realpath "${sPath}"
            return "${EXIT_OK}"
        fi
    }

    local -a aParameters=()
    local sFormat sInputPath sOutputPath sParameter
    sFormat='png'

    while [[ $# -gt 0 ]]; do
        sParameter="${1}"
        case "${sParameter}" in
            -f | --format)
                shift
                sFormat="${1?Format value expected after "${sParameter}"}"
                ;;
            -f=* | --format=*)
                sFormat="${sParameter#*=}"
                ;;
            -h | --help)
                usage
                exit
                ;;
            --* | -*)
                error "Invalid option '${sParameter}' provided"
                exit "${EXIT_INVALID_PARAMETER}"
                ;;
            *)
                aParameters+=("${sParameter}")
                ;;
        esac
        shift
    done

    if [[ ${#aParameters[@]} -lt 2 ]]; then
        error 'Two parameters required: <input-path> <output-path>'
        exit "${EXIT_NOT_ENOUGH_PARAMETERS}"
    fi

    sInputPath="$(validatePath "${aParameters[0]}")" || exit $?
    readonly sInputPath

    sOutputPath="$(validatePath "${aParameters[1]}")" || exit $?
    readonly sOutputPath

    build "${sInputPath}" "${sOutputPath}" "${sFormat}"
}

if [[ ${BASH_SOURCE[0]} != "${0}" ]]; then
    export -f build_diagrams
else
    build_diagrams "$@"
fi
