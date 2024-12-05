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

function envsubst_bash() {
    tfile=$(mktemp)
    env | sed -E -e '
       /^_=/d; 
       s=\\=\\\\=g; 
       s/=/\\=/g; 
       s/\\=/=/; 
       s%^([^=]*)=(.*)$%s=\\$\\{?\1\\}?([^_A-Za-z0-9]|$)=\2=g;%
    ' > $tfile
    sed -E -f $tfile
    rm $tfile
}

# Extract target names and comments from each makefile
for makefile in $makefiles; do
    makefile=$(realpath ${makefile})
    while IFS= read -r line; do
        target="${line%%:*}"
        comment="${line#*##}"
        targets="${targets}
                 ${target}##${comment}
        "
    done <<< "$(sed -n '/[^[:space:]]*:.*##/p' "${makefile}"|| echo "")"
done

# substitute environment variables, strip whitspace from beginning and end of each line, remove empty lines, sort and remove duplicates 
targets=$(echo "${targets}" | envsubst_bash | sed '/^[[:space:]]*$/d;s/^[[:space:]]*//;s/[[:space:]]*$//' | sort | uniq)

# Check for ANSI support in the current shell interactive session
ansi_supported() {
    if [ -z "$TERM" ]; then
        return 1
    elif [[ "$TERM" == *"color"* || "$TERM" == "xterm" || "$TERM" == "xterm-256color" || "$TERM" == "screen"* || "$TERM" == "linux" || "$TERM" == "rxvt"* || "$TERM" == "eterm" ]]; then
        return 0
    elif [ -t 1 ]; then
        return 0
    else
        return 1
    fi
}

font_bold=""
font_reset=""
color_teal=""
color_reset=""

# Apply ANSI color if it is supported
if ansi_supported; then
    font_bold=$(tput bold)
    font_reset=$(tput sgr0)
    color_teal="\033[36m"
    color_reset="\033[0m"
fi

# Strip all ANSI control sequences if the current environment does not provide rendering support
strip_ansi() {
    if ansi_supported; then
        cat
    else
        sed 's/\x1b\[[0-9;]*m//g'
    fi
}

{
  printf "Usage: make ${color_teal}${font_bold}<target>${font_reset}${color_reset}" | strip_ansi
  while IFS= read -r target; do
    name=$(echo "${target}" | awk -F"##" '{print $1}')
    comment=$(echo "${target}" | awk -F"##" '{print $2}')
    printf "  ${font_bold}${color_teal}%-40s${color_reset}${font_reset} %b\n" "${name}" "${comment}" | strip_ansi
  done <<< "${targets}"
} | awk '{print length($1), $0}' | sort -n | cut -d' ' -f2- | (command -v less >/dev/null 2>&1 && less -F || cat)



