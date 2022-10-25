#!/usr/bin/env bash

# Returns the sanitized git branch name or short hash if not on a branch.
# Sanitized git branch names can be used as docker tags for example.

# The permitted characters and sequences in a git branch name is broader then
# what is permitted in docker tags. The goal of this script is to be able to map
# git branch names to docker tags.

# For more information view the git and docker documentation:
# https://docs.github.com/en/get-started/using-git/dealing-with-special-characters-in-branch-and-tag-names
# https://docs.docker.com/engine/reference/commandline/tag


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
branch="$(git branch --show-current | tr -d '[:space:]' | tr -s -c "[:alnum:][:blank:]\.\_\-" _ | tr '[:upper:]' '[:lower:]')"


if [[ -z "${branch}" ]]; then
    printf "%s\n" "${short_hash}" 
else
    printf "%s\n" "${branch}" 
fi
