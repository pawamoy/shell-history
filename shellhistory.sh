#!/usr/bin/env bash

# FUNCTIONS --------------------------------------------------------------------

# shellcheck disable=SC2120
_shellhistory_parents() {
  local list pid
  list="$(ps -eo pid,ppid,command | tr -s ' ' | sed 's/^ //g')"
  pid=${1:-$$}
  while [ "${pid}" -ne 0 ]; do
    echo "${list}" | grep "^${pid} " | cut -d' ' -f3-
    pid=$(echo "${list}" | grep "^${pid} " | cut -d' ' -f2)
  done
}

_shellhistory_last_command() {
  # multiline commands have preprended ';' (starting at line 2)
  fc -lnr -0 | sed -e '1s/^\t //;2,$s/^/;/'
}

_shellhistory_last_command_number() {
  fc -lr -0 | head -n1 | cut -f1
}

_shellhistory_bash_command_type() {
  type -t $1
}

_shellhistory_zsh_command_type() {
  whence -w $1 | cut -d' ' -f2
}

_shellhistory_time_now() {
  local now
  now=$(date '+%s%N')
  echo "${now:0:-3}"
}

_shellhistory_start_timer() {
  _SHELLHISTORY_START_TIME=${_SHELLHISTORY_START_TIME:-$(_shellhistory_time_now)}
}

_shellhistory_stop_timer() {
  _SHELLHISTORY_STOP_TIME=$(_shellhistory_time_now)
}

_shellhistory_set_command() {
  _SHELLHISTORY_COMMAND="$(_shellhistory_last_command)"
}

_shellhistory_set_command_type() {
  # FIXME: what about "VAR=value command do something"?
  # See https://github.com/Pawamoy/shell-history/issues/13
  _SHELLHISTORY_TYPE="$(_shellhistory_command_type "${_SHELLHISTORY_COMMAND%% *}")"
}

_shellhistory_set_code() {
  _SHELLHISTORY_CODE=$?
}

_shellhistory_set_pwd() {
  _SHELLHISTORY_PWD="${PWD}"
  _SHELLHISTORY_PWD_B64="$(base64 -w0 <<<"${PWD}")"
}

_shellhistory_can_append() {
  local last_number
  [ ! -n "${_SHELLHISTORY_START_TIME}" ] && return 1
  last_number=$(_shellhistory_last_command_number)
  if [ -n "${_SHELLHISTORY_PREVCMD_NUM}" ]; then
    [ "${last_number}" -eq ${_SHELLHISTORY_PREVCMD_NUM} ] && return 1
    _SHELLHISTORY_PREVCMD_NUM=${last_number}
  else
    _SHELLHISTORY_PREVCMD_NUM=${last_number}
  fi
}

_shellhistory_append() {
  ! _shellhistory_can_append && return 1
  # if [ ${_SHELLHISTORY_APPEND_TO_FILE} -eq 1 ]; then
    _shellhistory_append_to_file
  # fi
  # if [ ${_SHELLHISTORY_APPEND_TO_DB} -eq 1 ]; then
    # _shellhistory_append_to_db
  # fi
}

_shellhistory_append_to_file() {
  printf ":%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s\n" \
    "${_SHELLHISTORY_START_TIME}" \
    "${_SHELLHISTORY_STOP_TIME}" \
    "${_SHELLHISTORY_UUID}" \
    "${_SHELLHISTORY_PARENTS_B64}" \
    "${_SHELLHISTORY_HOSTNAME}" \
    "${USER}" \
    "${_SHELLHISTORY_TTY}" \
    "${_SHELLHISTORY_PWD_B64}" \
    "${SHELL}" \
    "${SHLVL}" \
    "${_SHELLHISTORY_TYPE}" \
    "${_SHELLHISTORY_CODE}" \
    "${_SHELLHISTORY_COMMAND}" >> "${SHELLHISTORY_FILE}"
}

_shellhistory_append_to_db() {
  # FIXME: datetime as "YYYY-MM-DD HH:MM:SS.SSS"
  # FIXME: compute duration
  # FIXME: sanitize!!!!
  local query="insert into history (start,stop,duration,host,user,uuid,tty,parents,shell,level,type,code,path,cmd) values (
    '${_SHELLHISTORY_START_TIME}',
    '${_SHELLHISTORY_STOP_TIME}',
    '0',
    '${_SHELLHISTORY_HOSTNAME}',
    '${USER}',
    '${_SHELLHISTORY_UUID}',
    '${_SHELLHISTORY_TTY}',
    '${_SHELLHISTORY_PARENTS}',
    '${SHELL}',
    ${SHLVL},
    '${_SHELLHISTORY_TYPE}',
    ${_SHELLHISTORY_CODE},
    '${_SHELLHISTORY_PWD}',
    '${_SHELLHISTORY_COMMAND}'
  );"

  # FIXME: commented out for security reasons
  # sqlite3 "${SHELLHISTORY_DB}" "${query}"
}

_shellhistory_before() {
  _shellhistory_set_command
  _shellhistory_set_command_type
  _shellhistory_set_pwd
  _shellhistory_start_timer
}

_shellhistory_after() {
  _shellhistory_stop_timer
  _shellhistory_append
}

_shellhistory_enable() {
  _SHELLHISTORY_ENABLED=1
  # mkdir -p "${SHELLHISTORY_ROOT}" &>/dev/null
  if [ "${ZSH_VERSION}" ]; then
    _shellhistory_command_type() { _shellhistory_zsh_command_type "$1"; }
      # FIXME: don't override possible previous contents of precmd
    precmd() { shellhistory run; }
  elif [ "${BASH_VERSION}" ]; then
    _shellhistory_command_type() { _shellhistory_bash_command_type "$1"; }
    PROMPT_COMMAND='shellhistory run;'$'\n'"${PROMPT_COMMAND}"
  fi
}

_shellhistory_disable() {
  if [ ${_SHELLHISTORY_TRAP_SET} -eq 1 ]; then
    trap - DEBUG
    _SHELLHISTORY_TRAP_SET=0
  fi
  _SHELLHISTORY_ENABLED=0
}

_shellhistory_run() {
  if [ ${_SHELLHISTORY_TRAP_SET} -eq 1 ]; then
    _shellhistory_after
  elif [ ${_SHELLHISTORY_ENABLED} -eq 1 ]; then
    _SHELLHISTORY_TRAP_SET=1
    trap '_shellhistory_before' DEBUG
  fi
  unset _SHELLHISTORY_START_TIME
}

_shellhistory_append_to() {
  case "$1" in
    file)
      _SHELLHISTORY_APPEND_TO_DB=0
      _SHELLHISTORY_APPEND_TO_FILE=1
    ;;
    db)
      _SHELLHISTORY_APPEND_TO_DB=1
      _SHELLHISTORY_APPEND_TO_FILE=0
    ;;
    both)
      _SHELLHISTORY_APPEND_TO_DB=1
      _SHELLHISTORY_APPEND_TO_FILE=1
    ;;
    *)
      echo "shellhistory: append-to: choose between 'file', 'db', or 'both'." >&2
      return 1
    ;;
  esac
}

_shellhistory_usage() {
  echo "usage: shellhistory <COMMAND> [ARGS]"
}

_shellhistory_help() {
  _shellhistory_usage
  echo
  echo "Commands:"
  # echo "  append-to <file|db|both>    tell where to append last command"
  # echo "                              (default both)"
  echo "  disable     disable shellhistory"
  echo "  enable      enable shellhistory"
  echo "  help        print this help and exit"
  echo "  run         try to append last command"
}

# GLOBAL VARIABLES -------------------------------------------------------------

# SHELLHISTORY_ROOT="${SHELLHISTORY_ROOT:-$HOME/.shell_history}"
# SHELLHISTORY_DB="${SHELLHISTORY_DB:-$SHELLHISTORY_ROOT/db}"
SHELLHISTORY_FILE="${SHELLHISTORY_FILE:-$HOME/.shell_history/history}"

# shellcheck disable=SC2119
_SHELLHISTORY_PARENTS="$(_shellhistory_parents)"
_SHELLHISTORY_PARENTS_B64="$(echo "${_SHELLHISTORY_PARENTS}" | base64 -w0)"
_SHELLHISTORY_HOSTNAME="$(hostname)"
_SHELLHISTORY_UUID="${_SHELLHISTORY_UUID:-$(uuidgen)}"
_SHELLHISTORY_TTY="$(tty)"
_SHELLHISTORY_START_TIME=
_SHELLHISTORY_STOP_TIME=
_SHELLHISTORY_TYPE=

_SHELLHISTORY_PREVCMD_NUM=
_SHELLHISTORY_TRAP_SET=0
_SHELLHISTORY_ENABLED=0
_SHELLHISTORY_APPEND_TO_FILE=1
_SHELLHISTORY_APPEND_TO_DB=1

# export SHELLHISTORY_ROOT
# export SHELLHISTORY_DB
export SHELLHISTORY_FILE
export _SHELLHISTORY_UUID

# MAIN COMMAND -----------------------------------------------------------------

shellhistory() {
  _shellhistory_set_code  # must always be done first

  case "$1" in
    # append-to) _shellhistory_append_to "$2" ;;
    disable) _shellhistory_disable ;;
    enable) _shellhistory_enable ;;
    help) _shellhistory_help ;;
    run) _shellhistory_run ;;
    *) _shellhistory_usage >&2; exit 1 ;;
  esac
}
