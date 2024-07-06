#!/bin/bash
#  Copyright (c) 2024 Greg Rynkowski. All rights reserved.
#  License: MIT License

###
# Sets up GPG keyring.
#
# Example with defaults:
#
#   ./src/scripts/setup.bash
#
###

# Bash Strict Mode Settings
set -euo pipefail
# Path Initialization
if [ -z "${SHELL_GR_DIR:-}" ]; then
  SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
  SCRIPT_PATH="$([[ ! "${SCRIPT_PATH_1}" =~ /bash$ ]] && readlink -f "${SCRIPT_PATH_1}" || echo "")"
  SCRIPT_DIR="$([ -n "${SCRIPT_PATH}" ] && (cd "$(dirname "${SCRIPT_PATH}")" && pwd -P) || echo "")"
  ROOT_DIR="$([ -n "${SCRIPT_DIR}" ] && (cd "${SCRIPT_DIR}/../.." && pwd -P) || echo "/tmp")"
  SHELL_GR_DIR="${ROOT_DIR}/.github_deps/rynkowsg/shell-gr@01e853a"
fi
# Library Sourcing
# shellcheck source=.github_deps/rynkowsg/shell-gr@01e853a/lib/color.bash
source "${SHELL_GR_DIR}/lib/color.bash"
# shellcheck source=.github_deps/rynkowsg/shell-gr@01e853a/lib/circleci.bash
source "${SHELL_GR_DIR}/lib/circleci.bash" # fix_home_in_old_images, print_common_debug_info
# shellcheck source=.github_deps/rynkowsg/shell-gr@01e853a/lib/error.bash
source "${SHELL_GR_DIR}/lib/error.bash"
# shellcheck source=.github_deps/rynkowsg/shell-gr@01e853a/lib/mask.bash
source "${SHELL_GR_DIR}/lib/mask.bash"
# shellcheck source=.github_deps/rynkowsg/shell-gr@01e853a/lib/normalize.bash
source "${SHELL_GR_DIR}/lib/normalize.bash" # GR_NORMALIZE__normalize

#################################################
#                    INPUTS                     #
#################################################

init_input_vars_debug() {
  DEBUG=${PARAM_DEBUG:-${DEBUG:-0}}
  printf "${GREEN}%s${NC}\n" "Debug variables:"
  printf "%s\n" "- DEBUG=${DEBUG}"
  if [ "${DEBUG}" = 1 ]; then
    set -x
    printenv | sort
    printf "%s\n" ""
  fi
}

init_input_vars_gpg() {
  GNUPG_HOME="${GNUPG_HOME:-}"
  GPG_PASSPHRASE="${GPG_PASSPHRASE:-}"
  GPG_PRIVATE_KEY_B64="${GPG_PRIVATE_KEY_B64:-}"
  GPG_PUBLIC_KEY_B64="${GPG_PUBLIC_KEY_B64:-}"
  printf "${GREEN}%s${NC}\n" "SSH variables:"
  printf "%s\n" "- GNUPG_HOME=${GNUPG_HOME}"
  printf "%s\n" "- GPG_PASSPHRASE=$(mask "${GPG_PASSPHRASE}")"
  printf "%s\n" "- GPG_PRIVATE_KEY_B64=$(mask "${GPG_PRIVATE_KEY_B64}")"
  printf "%s\n" "- GPG_PUBLIC_KEY_B64=$(mask "${GPG_PUBLIC_KEY_B64}")"
}

setup_gpg() {
  # INPUTS
  local input_GNUPG_HOME="${GNUPG_HOME:-"${HOME}/.gnupg"}"
  local input_GPG_PASSPHRASE="${GPG_PASSPHRASE:-}"
  local input_GPG_PRIVATE_KEY_B64="${GPG_PRIVATE_KEY_B64:-}"
  local input_GPG_PUBLIC_KEY_B64="${GPG_PUBLIC_KEY_B64:-}"
  # VALIDATION
  # private key is mandatory
  [ -n "${input_GPG_PRIVATE_KEY_B64}" ] || fail "GPG private key not provided"
  # public is optional
  # passphrase can be empty

  mkdir -p "${input_GNUPG_HOME}"
  chmod 700 "${input_GNUPG_HOME}"

  echo "${input_GPG_PRIVATE_KEY_B64}" | base64 --decode | gpg --homedir "${input_GNUPG_HOME}" --import --pinentry-mode loopback --passphrase "${input_GPG_PASSPHRASE}"
  if [ -n "${input_GPG_PUBLIC_KEY_B64}" ]; then
    echo "${input_GPG_PUBLIC_KEY_B64}" | base64 --decode | gpg --homedir "${input_GNUPG_HOME}" --import
  fi
}

install_gpg() {
  local command="gpg"
  if ! command -v "${command}" &>/dev/null; then
    local platform_uname
    platform_uname="$(uname -s)"
    case "${platform_uname}" in
      ## LINUX
      Linux*)
        linux_identifier="$(linux_id)"
        case "${linux_identifier}" in
          alpine)
            apk add --no-cache gnupg
            ;;
          fedora)
            dnf install -y gnupg2
            ;;
          debian)
            apt-get update
            apt-get install -y gnupg2
            ;;
          *) fail "Linux \"${linux_identifier}\" is not yet supported." ;;
        esac
        ;;
      ## MACOS
      Darwin*)
        brew update
        brew install gnupg
        ;;
      ## ELSE
      *) fail "Platform \"${platform_uname}\" is not yet supported." ;;
    esac
  else
    printf "%s\n" "'${command}' detected..."
    printf "%s\n" ""
  fi
}

#################################################
#                     MAIN                      #
#################################################

main() {
  fix_home_in_old_images
  GR_NORMALIZE__normalize

  print_common_debug_info "$@"
  init_input_vars_debug
  init_input_vars_gpg
  setup_gpg

  set -x
  gpg -k
  gpg -K
}

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ "${CIRCLECI}" == "true" ]]; then
  main "$@"
else
  printf "%s\n" "Loaded: ${BASH_SOURCE[0]:-}"
fi
