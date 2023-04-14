#!/usr/bin/env bash

set -euo pipefail

echoerr (){ printf "%s \n" "$@" >&2;}

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

makefiles=

help() {
  cat << EOF 
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] -m makefile1 makefile2 ...

Available options:

-h, --help       Print this help and exit
-v, --verbose    Print script debug info
-m, --make-files List of makefiles
EOF
  exit
}


function parse_params() {
  makefiles=

  while :; do
    case "${1-}" in
    -h | --help) help ;;
    -v | --verbose) set -x ;;
    -m | --makefiles)
      makefiles="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
#  [[ -z "${param-}" ]] && die "Missing required parameter: param"
#  [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

  return 0
}

parse_params "$@"


if [[ -z "${makefiles}" ]]; then
   echoerr "ERROR: Must provide a list of makefiles with -m or --makefiles "
   exit 1
fi

#echo "${makefiles}"

targets=

trim() {
    local var="$*"
    printf '%s' "$var" | awk '{$1=$1;print}' | sed '/^$/d'
}

envsubst() {
    while read input; do
        eval "echo \"${input}\"" 2> /dev/null || true
        #echo "${input}"
    done
}

font_bold=$(tput bold)
font_reset=$(tput sgr0)
color_teal=\\033[36m
color_reset=\\033[0m
for makefile in $makefiles; do
    #echo "  makefile: $(realpath ${makefile})"
    makefile=$(realpath ${makefile})
    #project=$(cat "${makefile}" | grep "project=\|project:=" | cut -d "=" -f 2 || echo "")
    #PROJECT=${project^^}
    #echo "  PROJECT: ${PROJECT}"
    targets="${targets}
    $(grep ' ## ' "${makefile}" | envsubst || echo "")
    "
done

targets=$(trim "${targets}" | sort | uniq)
short_targets=$(trim "${targets}" | grep -E '^[^_]*:' | sort || echo "")
long_targets=$(trim "${targets}" | grep -vE '^[^_]*:' | sort || echo "")
targets="
${short_targets}
${long_targets}
"
targets=$(trim "${targets}" | uniq)

{
printf "Usage: make ${color_teal}${font_bold}<target>${font_reset}${color_reset}\n"
while IFS= read -r target; do
    name=$(echo "${target}" | awk -F: '{print $1}')
    comment=$(echo "${target}" | awk -F" ## " '{print $2}')
    #printf "name: %s  comment: %s\n" "${name}" "${comment}"
    printf "  ${font_bold}${color_teal}%-40s${color_reset}${font_reset} %b\n" "${name}" "${comment}"
#printf "  ${font_bold}${color_teal}%s${color_reset}${font_reset}\n" "${name}"
done <<< "${targets}"
} | less -F
