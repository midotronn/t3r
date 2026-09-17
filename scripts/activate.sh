#!/usr/bin/env bash

T3R_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENVLA_OFT_ROOT="${OPENVLA_OFT_ROOT:-${T3R_ROOT}/openvla-oft}"
LIBERO_ROOT="${LIBERO_ROOT:-/workspace/LIBERO}"
EFFICIENTTAM_ROOT="${EFFICIENTTAM_ROOT:-/workspace/EfficientTAM}"
COGACT_ROOT="${COGACT_ROOT:-/workspace/CogACT}"

if [[ ! -f "${OPENVLA_OFT_ROOT}/pyproject.toml" ]]; then
  echo "OpenVLA-OFT submodule is missing. Run:" >&2
  echo "  git submodule update --init --recursive" >&2
  return 1 2>/dev/null || exit 1
fi

_t3r_prepend_pythonpath() {
  local path="$1"
  if [[ -d "${path}" ]]; then
    case ":${PYTHONPATH:-}:" in
      *":${path}:"*) ;;
      *) PYTHONPATH="${path}${PYTHONPATH:+:${PYTHONPATH}}" ;;
    esac
  fi
}

_t3r_prepend_pythonpath "${T3R_ROOT}"
_t3r_prepend_pythonpath "${OPENVLA_OFT_ROOT}"
_t3r_prepend_pythonpath "${LIBERO_ROOT}"
_t3r_prepend_pythonpath "${COGACT_ROOT}"
_t3r_prepend_pythonpath "${EFFICIENTTAM_ROOT}"

export T3R_ROOT
export OPENVLA_OFT_ROOT
export LIBERO_ROOT
export EFFICIENTTAM_ROOT
export COGACT_ROOT
export PYTHONPATH

unset -f _t3r_prepend_pythonpath
