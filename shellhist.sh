SHELLHIST_FILE="${HOME}/.shell_extended_history"
_SHELLHIST_TRAP_SET=0
_SHELLHIST_ENABLED=0
_SHELLHIST_TIMER=
_SHELLHIST_PREVCMD_NUM=

_parents() {
  local list pid
  list="$(ps -eo pid,ppid,command | tr -s ' ' | sed 's/^ //g')"
  pid=${1:-$$}
  while [ ${pid} -ne 0 ]; do
    echo "${list}" | grep "^${pid} " | cut -d' ' -f3-
    pid=$(echo "${list}" | grep "^${pid} " | cut -d' ' -f2)
  done
}

# Variables that will not change
_SHELLHIST_HOSTNAME="$(hostname)"
_SHELLHIST_UUID="${_SHELLHIST_UUID:-$(uuidgen)}"
_SHELLHIST_TTY="$(tty)"
_SHELLHIST_PARENTS="$(_parents | base64 -w0)"

export SHELLHIST_FILE
export _SHELLHIST_UUID

_last_command() {
  # multiline commands have preprended ';' (starting at line 2)
  fc -lnr -0 | sed -e '1s/^\t //;2,$s/^/;/'
}

_last_command_number() {
  fc -lr -0 | head -n1 | cut -f1
}

_shellhist_timer_now() {
  local now
  now=$(date '+%s%N')
  echo "${now:0:-3}"
}

_shellhist_timer_start() {
  _SHELLHIST_TIMER=${_SHELLHIST_TIMER:-$(_shellhist_timer_now)}
}

_can_append() {
  local last_number
  [ ! -n "${_SHELLHIST_TIMER}" ] && return 1
  last_number=$(_last_command_number)
  if [ -n "${_SHELLHIST_PREVCMD_NUM}" ]; then
    [ ${last_number} -eq ${_SHELLHIST_PREVCMD_NUM} ] && return 1
    _SHELLHIST_PREVCMD_NUM=${last_number}
  else
    _SHELLHIST_PREVCMD_NUM=${last_number}
    return 1
  fi
}

_shellhist_append() {
  local now dir code=$1
  # immediately get time
  now=$(_shellhist_timer_now)
  # check that we can append
  ! _can_append && return 1
  # avoid delimiter corruption
  dir="$(base64 -w0 <<<"${PWD}")"
  printf ":%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s\n" \
    "${_SHELLHIST_TIMER}" \
    "${now}" \
    "${_SHELLHIST_UUID}" \
    "${_SHELLHIST_PARENTS}" \
    "${_SHELLHIST_HOSTNAME}" \
    "${USER}" \
    "${_SHELLHIST_TTY}" \
    "${dir}" \
    "${SHELL}" \
    "${SHLVL}" \
    "${code}" \
    "$(_last_command)" >> "${SHELLHIST_FILE}"
}

enable_shellhist() {
  _SHELLHIST_ENABLED=1
  # do not set trap here, must be done LAST
}

disable_shellhist() {
  if [ ${_SHELLHIST_TRAP_SET} -eq 1 ]; then
    trap - DEBUG
    _SHELLHIST_TRAP_SET=0
  fi
  _SHELLHIST_ENABLED=0
}

_shellhist() {
  if [ ${_SHELLHIST_TRAP_SET} -eq 1 ]; then
    _shellhist_append "$1"
  elif [ ${_SHELLHIST_ENABLED} -eq 1 ]; then
    _SHELLHIST_TRAP_SET=1
    trap '_shellhist_timer_start' DEBUG
  fi
  unset _SHELLHIST_TIMER
}

enable_shellhist

if [ "${ZSH_VERSION}" ]; then
  # FIXME: don't override possible previous contents of precmd
  precmd() { _shellhist $?; }
elif [ "${BASH_VERSION}" ]; then
  PROMPT_COMMAND='_shellhist $?;'$'\n'"${PROMPT_COMMAND}"
fi
