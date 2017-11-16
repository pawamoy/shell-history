#!/usr/bin/env bash

if ! command -v python3 >/dev/null; then
  echo "Install Python 3 before continuing." >&2
  exit 1
fi

if ! command -v virtualenv >/dev/null; then
  echo "Install virtualenv before continuing" >&2
  exit 1
fi

if [ ! -d ~/.shell_history ]; then
  mkdir ~/.shell_history
fi

WD="$(dirname "$(dirname "$(readlink -f "$0")")")"
SHELLHISTORY_VENV="${SHELLHISTORY_VENV:-$WD/venv}"
export SHELLHISTORY_VENV

if [ ! -d "${SHELLHISTORY_VENV}" ]; then
  echo "Creating virtualenv"
  virtualenv -p python3 "${SHELLHISTORY_VENV}" &>/dev/null || exit 1
fi

echo "Installing dependencies"
. "${SHELLHISTORY_VENV}/bin/activate"
{
  pip install -U pip
  pip install -r "${WD}/requirements.txt" || exit 1
  "${WD}/scripts/fluid_admin.sh"
} &>/dev/null

echo "To generate the necessary data, you need to source shellhistory.sh at shell startup:"
echo ". '${WD}/shellhistory.sh'"
