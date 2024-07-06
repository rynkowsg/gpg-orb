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
# source "${SHELL_GR_DIR}/lib/color.bash" # BEGIN
#!/usr/bin/env bash
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# shellcheck disable=SC2034
GREEN=$(printf '\033[32m')
RED=$(printf '\033[31m')
YELLOW=$(printf '\033[33m')
NC=$(printf '\033[0m')

# Color enabled by default
COLOR=${COLOR:-1}

is_color() {
  case "${COLOR}" in
    1 | "true") return 0 ;; # true
    *) return 1 ;;          # false
  esac
}
# source "${SHELL_GR_DIR}/lib/color.bash" # END
# shellcheck source=.github_deps/rynkowsg/shell-gr@01e853a/lib/circleci.bash
# source "${SHELL_GR_DIR}/lib/circleci.bash" # fix_home_in_old_images, print_common_debug_info # BEGIN
#!/usr/bin/env bash
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
if [ -n "${SHELL_GR_DIR:-}" ]; then
  _SHELL_GR_DIR="${SHELL_GR_DIR}"
elif [ -z "${_SHELL_GR_DIR:-}" ]; then
  _SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
  _SCRIPT_PATH="$([[ ! "${_SCRIPT_PATH_1}" =~ /bash$ ]] && readlink -f "${_SCRIPT_PATH_1}" || exit 1)"
  _SCRIPT_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
  _ROOT_DIR="$(cd "${_SCRIPT_DIR}/.." && pwd -P || exit 1)"
  _SHELL_GR_DIR="${_ROOT_DIR}"
fi
# Library Sourcing
# source "${_SHELL_GR_DIR}/lib/color.bash" # GREEN, NC # SKIPPED

fix_home_in_old_images() {
  # Workaround old docker images with incorrect $HOME
  # check https://github.com/docker/docker/issues/2968 for details
  if [ -z "${HOME}" ] || [ "${HOME}" = "/" ]; then
    HOME="$(getent passwd "$(id -un)" | cut -d: -f6)"
    export HOME
  fi
}

# Prints common debug info
# Usage:
#     print_common_debug_info "$@"
print_common_debug_info() {
  printf "${GREEN}%s${NC}\n" "Common debug info"
  bash --version
  # typical CLI debugging variables
  printf "\$0: %s\n" "$0"
  printf "\$@: %s\n" "$@"
  printf "BASH_SOURCE[0]: %s\n" "${BASH_SOURCE[0]}"
  printf "BASH_SOURCE[*]: %s\n" "${BASH_SOURCE[*]}"
  # other common
  printf "HOME: %s\n" "${HOME}"
  printf "PATH: %s\n" "${PATH}"
  printf "CIRCLECI: %s\n" "${CIRCLECI}"
  # sosh related
  [ -n "${SCRIPT_PATH:-}" ] && printf "SCRIPT_PATH: %s\n" "${SCRIPT_PATH}"
  [ -n "${SCRIPT_DIR:-}" ] && printf "SCRIPT_DIR: %s\n" "${SCRIPT_DIR}"
  [ -n "${ROOT_DIR:-}" ] && printf "ROOT_DIR: %s\n" "${ROOT_DIR}"
  [ -n "${SHELL_GR_DIR:-}" ] && printf "SHELL_GR_DIR: %s\n" "${SHELL_GR_DIR}"
  [ -n "${_SHELL_GR_DIR:-}" ] && printf "_SHELL_GR_DIR: %s\n" "${_SHELL_GR_DIR}"
  printf "%s\n" ""
}
# source "${SHELL_GR_DIR}/lib/circleci.bash" # fix_home_in_old_images, print_common_debug_info # END
# shellcheck source=.github_deps/rynkowsg/shell-gr@01e853a/lib/error.bash
# source "${SHELL_GR_DIR}/lib/error.bash" # BEGIN
#!/usr/bin/env bash
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
if [ -n "${SHELL_GR_DIR:-}" ]; then
  _SHELL_GR_DIR="${SHELL_GR_DIR}"
elif [ -z "${_SHELL_GR_DIR:-}" ]; then
  _SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
  _SCRIPT_PATH="$([[ ! "${_SCRIPT_PATH_1}" =~ /bash$ ]] && readlink -f "${_SCRIPT_PATH_1}" || exit 1)"
  _SCRIPT_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
  _ROOT_DIR="$(cd "${_SCRIPT_DIR}/.." && pwd -P || exit 1)"
  _SHELL_GR_DIR="${_ROOT_DIR}"
fi
# Library Sourcing
# source "${_SHELL_GR_DIR}/lib/color.bash" # NC, RED # SKIPPED

# generic
export ERROR_UNKNOWN=101
export ERROR_INVALID_FN_CALL=102
export ERROR_INVALID_STATE=103
# specific
export ERROR_COMMAND_DOES_NOT_EXIST=104

# TODO: consider removing this and replacing with simpler fail without error codes
# At the end, why do I need error codes?
error_exit() {
  local msg="${1:-"Unknown Error"}"
  local code="${2:-${UNKNOWN_ERROR}}"
  printf "${RED}Error: %s${NC}\n" "${msg}" >&2
  exit "${code}"
}

fail() {
  printf "%s\n" "$*" >&2
  exit 1
}

assert_command_exist() {
  local command="$1"
  if ! command -v "${command}" &>/dev/null; then
    error_exit "'${command}' doesn't exist. Please install '${command}'." "${COMMAND_DONT_EXIST}"
  else
    printf "%s\n" "'${command}' detected..."
    printf "%s\n" ""
  fi
}

assert_not_empty() {
  local -r var_name="${1}"
  local -r var_value="${!var_name}"
  if [ -z "${var_value}" ]; then
    error_exit "${var_name} must not be empty"
  fi
}

run_with_unset_e() {
  # Check the current 'set -e' state
  local e_enabled
  if set +o | grep "set -o errexit" &>/dev/null; then
    e_enabled=1
  else
    e_enabled=0
  fi
  # If enabled, disable
  if [ ${e_enabled} -eq 1 ]; then
    set +e
  fi
  # Run the passed command(s)
  "$@"
  local -r res=$?
  # Enable 'errexit' if it was enabled
  if [ ${e_enabled} -eq 1 ]; then
    set -e
  fi
  # Return the result of the command
  return $res
}
# source "${SHELL_GR_DIR}/lib/error.bash" # END
# shellcheck source=.github_deps/rynkowsg/shell-gr@01e853a/lib/mask.bash
# source "${SHELL_GR_DIR}/lib/mask.bash" # BEGIN
#!/usr/bin/env bash
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Function to mask the input with asterisks
mask() {
  local input="$1"
  local masked="${input//?/*}"
  echo "${masked}"
}
# source "${SHELL_GR_DIR}/lib/mask.bash" # END
# shellcheck source=.github_deps/rynkowsg/shell-gr@01e853a/lib/normalize.bash
# source "${SHELL_GR_DIR}/lib/normalize.bash" # GR_NORMALIZE__normalize # BEGIN
#!/usr/bin/env bash
# Copyright (c) 2024. All rights reserved.
# License: MIT License

# Path Initialization
if [ -n "${SHELL_GR_DIR:-}" ]; then
  _SHELL_GR_DIR="${SHELL_GR_DIR}"
elif [ -z "${_SHELL_GR_DIR:-}" ]; then
  _SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
  _SCRIPT_PATH="$([[ ! "${_SCRIPT_PATH_1}" =~ /bash$ ]] && readlink -f "${_SCRIPT_PATH_1}" || exit 1)"
  _SCRIPT_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
  _ROOT_DIR="$(cd "${_SCRIPT_DIR}/.." && pwd -P || exit 1)"
  _SHELL_GR_DIR="${_ROOT_DIR}"
fi
# Library Sourcing
# source "${_SHELL_GR_DIR}/lib/log.bash" # log_debug # BEGIN
#!/usr/bin/env bash
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
if [ -n "${SHELL_GR_DIR:-}" ]; then
  _SHELL_GR_DIR="${SHELL_GR_DIR}"
elif [ -z "${_SHELL_GR_DIR:-}" ]; then
  _SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
  _SCRIPT_PATH="$([[ ! "${_SCRIPT_PATH_1}" =~ /bash$ ]] && readlink -f "${_SCRIPT_PATH_1}" || exit 1)"
  _SCRIPT_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
  _ROOT_DIR="$(cd "${_SCRIPT_DIR}/.." && pwd -P || exit 1)"
  _SHELL_GR_DIR="${_ROOT_DIR}"
fi
# Library Sourcing
# source "${_SHELL_GR_DIR}/lib/color.bash" # NC, RED, YELLOW, is_color # SKIPPED
# source "${_SHELL_GR_DIR}/lib/debug.bash" # is_debug # BEGIN
#!/usr/bin/env bash
# Copyright (c) 2024 Greg Rynkowski. All rights reserved.
# License: MIT License

# Debug disabled by default
DEBUG=${DEBUG:-0}

is_debug() {
  case "${DEBUG}" in
    1 | "true") return 0 ;; # true
    *) return 1 ;;          # false
  esac
}
# source "${_SHELL_GR_DIR}/lib/debug.bash" # is_debug # END

# Expected env vars for log functions:
# COLOR - to enable/disable colors
# DEBUG - to enable/disable debug logs
# PREFIX - log prefix

__LOG_PREFIX="${LOG_PREFIX:-}"

# shellcheck disable=SC2059
log_error_f() {
  if is_color; then
    printf "${RED}${__LOG_PREFIX}${1}${NC}" "${@:2}"
  else
    printf "$@"
  fi
}

log_error() {
  log_error_f "%s\n" "$@"
}

# shellcheck disable=SC2059
log_warning_f() {
  if is_color; then
    printf "${YELLOW}${__LOG_PREFIX}${1}${NC}" "${@:2}"
  else
    printf "$@"
  fi
}

log_warning() {
  log_warning_f "%s\n" "$@"
}

log_info_f() {
  # shellcheck disable=SC2059
  printf "${__LOG_PREFIX}${1}" "${@:2}"
}

log_info() {
  log_info_f "${__LOG_PREFIX}%s\n" "$@"
}

log_debug_f() {
  if is_debug; then
    # shellcheck disable=SC2059
    printf "${__LOG_PREFIX}${1}" "${@:2}"
  fi
}

log_debug() {
  log_debug_f "%s\n" "$@"
}
# source "${_SHELL_GR_DIR}/lib/log.bash" # log_debug # END

# Recovers builtin cd if it is overridden
GR_NORMALIZE__recover_builtin_cd() {
  if declare -f cd >/dev/null; then
    unset -f cd
    log_debug "Reverted cd to its builtin behavior."
  fi
}

# Normalizes the environment.
GR_NORMALIZE__normalize() {
  GR_NORMALIZE__recover_builtin_cd
}
# source "${SHELL_GR_DIR}/lib/normalize.bash" # GR_NORMALIZE__normalize # END

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
