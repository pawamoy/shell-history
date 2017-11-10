#!/bin/bash

if ! command -v flask >/dev/null; then
  echo "Flask does not seem to be installed." >&2
  echo "Install it with 'pip install flask' (might need sudo)" >&2
  exit 1
fi

working_dir=$(dirname "$(readlink -f "$0")")

export FLASK_APP="${working_dir}/app.py"

flask run
