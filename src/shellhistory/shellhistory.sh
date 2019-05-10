# FUNCTIONS --------------------------------------------------------------------

if [ -n "${ZSH_VERSION}" ]; then
  _shellhistory_command_type() {
    whence -w "$1" | cut -d' ' -f2
  }

  _shellhistory_last_command() {
    # multi-line commands have prepended ';' (starting at line 2)
    # shellcheck disable=SC2154
    echo "${history[$HISTCMD]}" | sed -e '2,$s/^/;/'
  }

  _shellhistory_last_command_number() {
    # shellcheck disable=SC2086
    echo $HISTCMD
  }
elif [ -n "${BASH_VERSION}" ]; then
  _shellhistory_command_type() {
    type -t "$1"
  }

  _shellhistory_last_command() {
    # multi-line commands have prepended ';' (starting at line 2)
    fc -lnr -0 | sed -e '1s/^\t //;2,$s/^/;/'
  }

  _shellhistory_last_command_number() {
    fc -lr -0 | head -n1 | cut -f1
  }
fi

# shellcheck disable=SC2120
_shellhistory_parents() {
  local list pid
  list="$(ps -eo pid,ppid,command | tr -s ' ' | sed 's/^ //g')"
  pid=$$
  while [ "${pid}" -ne 0 ]; do
    echo "${list}" | grep "^${pid} " | cut -d' ' -f3-
    pid=$(echo "${list}" | grep "^${pid} " | cut -d' ' -f2)
  done
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
  _SHELLHISTORY_PWD_B64="$(base64 -w0 <<<"${_SHELLHISTORY_PWD}")"
}

_shellhistory_can_append() {
  local last_number
  # shellcheck disable=SC2086
  [ ${_SHELLHISTORY_BEFORE_DONE} -ne 1 ] && return 1
  last_number=$(_shellhistory_last_command_number)
  if [ -n "${_SHELLHISTORY_PREVCMD_NUM}" ]; then
    # shellcheck disable=SC2086
    [ "${last_number}" -eq ${_SHELLHISTORY_PREVCMD_NUM} ] && return 1
    _SHELLHISTORY_PREVCMD_NUM=${last_number}
  else
    _SHELLHISTORY_PREVCMD_NUM=${last_number}
  fi
}

_shellhistory_append() {
  if _shellhistory_can_append; then
    _shellhistory_append_to_file
  fi
}

_shellhistory_append_to_file() {
  printf ':%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s\n' \
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

_shellhistory_before() {
  # shellcheck disable=SC2086
  [ ${_SHELLHISTORY_BEFORE_DONE} -gt 0 ] && return

  _shellhistory_set_command
  _shellhistory_set_command_type
  _shellhistory_set_pwd
  _shellhistory_start_timer

  _SHELLHISTORY_AFTER_DONE=0
  _SHELLHISTORY_BEFORE_DONE=1
}

_shellhistory_after() {
  _shellhistory_set_code  # must always be done first
  _shellhistory_stop_timer

  [ ${_SHELLHISTORY_BEFORE_DONE} -eq 2 ] && _SHELLHISTORY_BEFORE_DONE=0
  [ ${_SHELLHISTORY_AFTER_DONE} -eq 1 ] && return

  _shellhistory_append
  unset _SHELLHISTORY_START_TIME

  _SHELLHISTORY_BEFORE_DONE=0
  _SHELLHISTORY_AFTER_DONE=1

  return ${_SHELLHISTORY_CODE}
}

_shellhistory_get_debug_trap() {
  local trap
  trap="$(trap -p | grep ' DEBUG$')" || return 0
  trap=${trap:9}
  trap=${trap:0:-7}
  case ${trap} in
    *';') ;;
    *) trap+=";" ;;
  esac
  echo "${trap}"
}

_shellhistory_enable() {
  _SHELLHISTORY_BEFORE_DONE=2
  _SHELLHISTORY_AFTER_DONE=1
  if [ "${ZSH_VERSION}" ]; then
    preexec_functions+=(_shellhistory_before)
    precmd_functions=(_shellhistory_after "${precmd_functions[@]}")
  elif [ "${BASH_VERSION}" ]; then
    PROMPT_COMMAND="_shellhistory_after;${PROMPT_COMMAND}"
    # shellcheck disable=SC2064
    trap "$(_shellhistory_get_debug_trap)_shellhistory_before;" DEBUG
  fi
}

_shellhistory_disable() {
  local trap
  local new_prompt
  _SHELLHISTORY_AFTER_DONE=1
  if [ "${ZSH_VERSION}" ]; then
    # shellcheck disable=SC2206
    preexec_functions=(${preexec_functions:#_shellhistory_before})
    # shellcheck disable=SC2206
    precmd_functions=(${precmd_functions:#_shellhistory_after})
  elif [ "${BASH_VERSION}" ]; then
    trap="$(_shellhistory_get_debug_trap)"
    trap=${trap//_shellhistory_before;}
    new_prompt="${PROMPT_COMMAND//_shellhistory_after;}"
    PROMPT_COMMAND="trap '${trap:--}' DEBUG; PROMPT_COMMAND='${new_prompt}'"
  fi
}

_shellhistory_usage() {
  echo "usage: shellhistory <COMMAND>"
}

_shellhistory_help() {
  _shellhistory_usage
  echo
  echo "Commands:"
  echo "  disable     disable shellhistory"
  echo "  enable      enable shellhistory"
  echo "  help        print this help and exit"
}

# GLOBAL VARIABLES -------------------------------------------------------------
_SHELLHISTORY_CODE=
_SHELLHISTORY_COMMAND=
_SHELLHISTORY_HOSTNAME="$(hostname)"
_SHELLHISTORY_PARENTS="$(_shellhistory_parents)"
_SHELLHISTORY_PARENTS_B64="$(echo "${_SHELLHISTORY_PARENTS}" | base64 -w0)"
_SHELLHISTORY_PWD=
_SHELLHISTORY_PWD_B64=
_SHELLHISTORY_START_TIME=
_SHELLHISTORY_STOP_TIME=
_SHELLHISTORY_TTY="$(tty)"
_SHELLHISTORY_TYPE=
_SHELLHISTORY_UUID="${_SHELLHISTORY_UUID:-$(uuidgen)}"

_SHELLHISTORY_AFTER_DONE=
_SHELLHISTORY_BEFORE_DONE=
_SHELLHISTORY_PREVCMD_NUM=

SHELLHISTORY_FILE="${SHELLHISTORY_FILE:-$HOME/.shellhistory/history}"

export SHELLHISTORY_FILE
export _SHELLHISTORY_UUID

# MAIN COMMAND -----------------------------------------------------------------
shellhistory() {
  case "$1" in
    disable) _shellhistory_disable ;;
    enable) _shellhistory_enable ;;
    help) _shellhistory_help ;;
    *) _shellhistory_usage >&2; return 1 ;;
  esac
}
