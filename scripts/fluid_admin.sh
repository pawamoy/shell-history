#!/usr/bin/env bash
flask_admin="$(find "$1" -type d -name flask_admin)"
html_file="${flask_admin}/templates/bootstrap3/admin/base.html"
sed -i 's/container/container-fluid/' "${html_file}"
sed -i 's/navbar-default/navbar-default navbar-static-top/' "${html_file}"
