#!/usr/bin/env bash

set -euo pipefail

echoerr (){ printf "%s" "$@" >&2;}
exiterr (){ echoerr "$@"; exit 1;}

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
OUTPUT_DIRECTORY=".log"
DEFAULT_OUTPUT_DIRECTORY="$(pwd)"
DEFAULT_OUTPUT_FILE="${DEFAULT_OUTPUT_DIRECTORY}/submodule_inventory.json"
_help() {
    cat << EOF 
NAME
    cdbuff - cd but with memory 


SYNOPSIS
  USAGE

  DESCRIPTION

  OPTIONS

    -h, --help             Print this help and exit
    -r, --repository-path  Path to git repository. DEFAULT: pwd 
    -o, --output-file      output json file. DEFAULT: pwd/submodule_inventory.json 
    -d, --output-directory Output directory. DEFAULT: pwd 
    -v, --verbose          verbose output
EOF
    exit
}




changed_files_json(){
    git --no-pager log -n 1 --name-status --oneline | tail -n +2 | awk '{ print "{\"change\":\""$1"\", \"file\":\""$2"\"}" }' | paste -sd "," | sed 's/^/[/;s/$/]/'
}
export -f changed_files_json

last_commit(){
    cd $1
    commit=$(git log -1 --pretty=format:"{\"hash\": \"%H\", \"author\": \"%an <%ae>\", \"date\": \"%ad\", \"message\": \"%s\", \"changes\":$(changed_files_json)}" --date=iso8601)
    if [ -z "$commit" ]; then
        echo "{}"
    else
        echo "${commit}"
    fi
}

export -f last_commit
submodule_inventory(){
  local output_file="${1}" 
  output=$(
  echo '{"submodules":['
  git config --file .gitmodules --get-regexp path | \
  awk '{ print $2 }' | \
  xargs -I {} bash -c 'echo "{\"submodule\": \"{}\", \"url\": \"$(git config --file .gitmodules --get submodule.{}.url)\", \"branch\":\"$(git rev-parse --abbrev-ref HEAD)\",\"last_commit\": $(last_commit {}) },"' | \
  sed '$ s/,$//'
  echo ']}')

  
  if [ -x "$(command -v ja)" ]; then
    printf "%s\n" "${output}" > "${output_file}"
    printf "%s\n" "${output}"
  else
    printf "%s\n" "${output}" | jq > "${output_file}"
    printf "%s\n" "${output}" | jq
  fi
}


parse_params() {
  help=0
  output_file=${DEFAULT_OUTPUT_FILE}
  output_directory=${DEFAULT_OUTPUT_DIRECTORY}
  repository_directory=$(pwd)

  
  while :; do
    case "${1-}" in
    -h | --help) echo "$(_help)" | less ;;
    -v | --verbose) set -x ;;
    -o | --output-file)
      output_file="${2-}"
      shift
      ;;
    -o | --output-directory)
      output_directory="${2-}"
      shift
      ;;
    -r | --repository_directory) # example named parameter
      repository_directory="${2-}"
      shift
      ;;
    -?*) exiterr "ERROR: Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

    args=("$@")

    (
    cd "${repository_directory}"
    submodule_inventory "${output_directory}/${output_file}" 2>/dev/null
    )
    return 0
}
parse_params "$@"



