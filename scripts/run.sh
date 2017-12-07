#!/usr/bin/env bash

WD="$(dirname "$(dirname "$(readlink -f "$0")")")"

if [ -d "${SHELLHISTORY_VENV}" ]; then
  . "${SHELLHISTORY_VENV}/bin/activate"
elif [ -d "${WD}/venv" ]; then
  . "${WD}/bin/activate"
fi

if ! command -v flask >/dev/null; then
  echo "Flask does not seem to be installed." >&2
  echo "Install it with 'pip install flask'" >&2
  exit 1
fi

SHELLHISTORY_FILE="${SHELLHISTORY_FILE:-$HOME/.shell_history/history}"
SHELLHISTORY_DB="${SHELLHISTORY_DB:-$HOME/.shell_history/db}"

export SHELLHISTORY_FILE
export SHELLHISTORY_DB

export FLASK_APP="${WD}/app.py"

flask run
