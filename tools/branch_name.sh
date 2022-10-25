#!/usr/bin/env bash

# Returns the sanitized git branch name or short hash if not on a branch. 

set -euo pipefail

echoerr (){ printf "%s" "$@" >&2;}
exiterr (){ echoerr "$@"; exit 1;}

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_DIR=""

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -r|--repo-directory)
      REPO_DIR="$2"
      shift # past argument
      shift # past value
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters


if [[ -n "${REPO_DIR}" ]]; then
    cd "${REPO_DIR}"
fi
short_hash="$(git rev-parse --short HEAD)"
branch="$(git branch --show-current | tr -d '[:space:]' | tr -s -c "[:alnum:][:blank:]" _ | tr '[:upper:]' '[:lower:]')"


if [[ -z "${branch}" ]]; then
    printf "%s\n" "${short_hash}" 
else
    printf "%s\n" "${branch}" 
fi
