mkdir "${HOME}/.shell_history/" &>/dev/null
SHELLHISTORY_FILE="${HOME}/.shell_history/history"
SHELLHISTORY_DB="${HOME}/.shell_history/db"
_SHELLHISTORY_TRAP_SET=0
_SHELLHISTORY_ENABLED=0
_SHELLHISTORY_TIMER=
_SHELLHISTORY_PREVCMD_NUM=

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

# Variables that will not change
_SHELLHISTORY_HOSTNAME="$(hostname)"
_SHELLHISTORY_UUID="${_SHELLHISTORY_UUID:-$(uuidgen)}"
_SHELLHISTORY_TTY="$(tty)"
# shellcheck disable=SC2119
_SHELLHISTORY_PARENTS="$(_shellhistory_parents | base64 -w0)"

export SHELLHISTORY_FILE
export SHELLHISTORY_DB
export _SHELLHISTORY_UUID

_shellhistory_last_command() {
  # multiline commands have preprended ';' (starting at line 2)
  fc -lnr -0 | sed -e '1s/^\t //;2,$s/^/;/'
}

_shellhistory_last_command_number() {
  fc -lr -0 | head -n1 | cut -f1
}

_shellhistory_timer_now() {
  local now
  now=$(date '+%s%N')
  echo "${now:0:-3}"
}

_shellhistory_timer_start() {
  _SHELLHISTORY_TIMER=${_SHELLHISTORY_TIMER:-$(_shellhistory_timer_now)}
}

_shellhistory_can_append() {
  local last_number
  [ ! -n "${_SHELLHISTORY_TIMER}" ] && return 1
  last_number=$(_shellhistory_last_command_number)
  if [ -n "${_SHELLHISTORY_PREVCMD_NUM}" ]; then
    [ "${last_number}" -eq ${_SHELLHISTORY_PREVCMD_NUM} ] && return 1
    _SHELLHISTORY_PREVCMD_NUM=${last_number}
  else
    _SHELLHISTORY_PREVCMD_NUM=${last_number}
    return 1
  fi
}

_shellhistory_append() {
  local now dir code=$1
  # immediately get time
  now=$(_shellhistory_timer_now)
  # check that we can append
  ! _shellhistory_can_append && return 1
  # avoid delimiter corruption
  dir="$(base64 -w0 <<<"${PWD}")"
  printf ":%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s\n" \
    "${_SHELLHISTORY_TIMER}" \
    "${now}" \
    "${_SHELLHISTORY_UUID}" \
    "${_SHELLHISTORY_PARENTS}" \
    "${_SHELLHISTORY_HOSTNAME}" \
    "${USER}" \
    "${_SHELLHISTORY_TTY}" \
    "${dir}" \
    "${SHELL}" \
    "${SHLVL}" \
    "${code}" \
    "$(_shellhistory_last_command)" >> "${SHELLHISTORY_FILE}"
}

enable_shellhistory() {
  _SHELLHISTORY_ENABLED=1
  # do not set trap here, must be done LAST
}

disable_shellhistory() {
  if [ ${_SHELLHISTORY_TRAP_SET} -eq 1 ]; then
    trap - DEBUG
    _SHELLHISTORY_TRAP_SET=0
  fi
  _SHELLHISTORY_ENABLED=0
}

_shellhistory() {
  if [ ${_SHELLHISTORY_TRAP_SET} -eq 1 ]; then
    _shellhistory_append "$1"
  elif [ ${_SHELLHISTORY_ENABLED} -eq 1 ]; then
    _SHELLHISTORY_TRAP_SET=1
    trap '_shellhistory_timer_start' DEBUG
  fi
  unset _SHELLHISTORY_TIMER
}

enable_shellhistory

if [ "${ZSH_VERSION}" ]; then
  # FIXME: don't override possible previous contents of precmd
  precmd() { _shellhistory $?; }
elif [ "${BASH_VERSION}" ]; then
  PROMPT_COMMAND='_shellhistory $?;'$'\n'"${PROMPT_COMMAND}"
fi
