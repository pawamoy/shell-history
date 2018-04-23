#!/usr/bin/env bash
html_file="${SHELLHISTORY_VENV}/lib/python$(python -V | cut -d' ' -f2 | cut -d. -f-2)/site-packages/flask_admin/templates/bootstrap3/admin/base.html"
sed -i 's/container/container-fluid/' "${html_file}"
sed -i 's/navbar-default/navbar-default navbar-static-top/' "${html_file}"
