#!/usr/bin/env bash
#  Copyright (c) 2024 Greg Rynkowski. All rights reserved.
#  License: MIT License

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
# Lint bash source files
#
# Example:
#
#     @bin/lint.bash
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Bash Strict Mode Settings
set -euo pipefail
# Path Initialization
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P || exit 1)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P || exit 1)"
# Library Sourcing
SHELL_GR_DIR="${SHELL_GR_DIR:-"${ROOT_DIR}/.github_deps/rynkowsg/shell-gr@01e853a"}"
# shellcheck source=.github_deps/rynkowsg/shell-gr@01e853a/lib/tool/lint.bash
source "${SHELL_GR_DIR}/lib/tool/lint.bash" # lint

main() {
  local error=0
  lint bash \
    < <(
      find "${ROOT_DIR}" -type f \( -name '*.bash' -o -name '*.sh' \) \
        | grep -v -E '(.github_deps|/gen/)' \
        | sort
    ) \
    || ((error += $?))
  lint bats \
    < <(
      find "${ROOT_DIR}" -type f -name '*.bats' \
        | sort
    ) \
    || ((error += $?))
  if ((error > 0)); then
    exit "$error"
  fi
}

main
