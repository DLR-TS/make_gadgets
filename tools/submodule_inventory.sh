#!/usr/bin/env bash

set -euo pipefail

echoerr (){ printf "%s" "$@" >&2;}
exiterr (){ echoerr "$@"; exit 1;}

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
OUTPUT_FILE=submodule_inventory.json

changed_files_json(){
    git --no-pager log -n 1 --name-status --oneline | tail -n +2 | awk '{ print "{\"change\":\""$1"\", \"file\":\""$2"\"}" }' | paste -sd "," | sed 's/^/[/;s/$/]/'
}
export -f changed_files_json

submodule_inventory(){
  local output_file="${1}" 
  output=$(
  echo '{"submodules":['
  git config --file .gitmodules --get-regexp path | \
  awk '{ print $2 }' | \
  xargs -I {} bash -c 'echo "{\"submodule\": \"{}\", \"url\": \"$(git config --file .gitmodules --get submodule.{}.url)\", \"branch\":\"$(git rev-parse --abbrev-ref HEAD)\",\"last_commit\": $(cd {} && git log -1 --pretty=format:"{\"hash\": \"%H\", \"author\": \"%an <%ae>\", \"date\": \"%ad\", \"message\": \"%s\", \"changes\":$(changed_files_json)}" --date=iso8601)},"' | \
  sed '$ s/,$//' 
  echo ']}')
  if [ -x "$(command -v ja)" ]; then
    printf "%s\n" "${output}" > "${output_file}"
  else
    printf "%s\n" "${output}" | jq > "${output_file}"
  fi
}

submodule_inventory "${OUTPUT_FILE}" 2>/dev/null
