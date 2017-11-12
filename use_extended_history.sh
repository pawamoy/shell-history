export SHELLHIST_FILE="${HOME}/.shell_extended_history"
_SHELLHIST_TRAP_SET=0
_SHELLHIST_ENABLED=0
_SHELLHIST_TIMER=

_zsh_last_command() {
  fc -ln -1 -1
}

_bash_last_command() {
  local cmd
  cmd="$(HISTTIMEFORMAT='' builtin history 1)"
  echo "${cmd#*  }"
}

# from https://stackoverflow.com/questions/1862510
_shellhist_timer_now() {
  local now
  now=$(date '+%s%N')
  echo "${now:0:-3}"
}

_shellhist_timer_start() {
  _SHELLHIST_TIMER=${_SHELLHIST_TIMER:-$(_shellhist_timer_now)}
}

_shellhist_append() {
  local now dir cmd code=$1
  # immediately get time
  now=$(_shellhist_timer_now)
  # timer was never started
  [ ! -n "${_SHELLHIST_TIMER}" ] && return
  # avoid delimiter corruption
  dir=$(base64 <<<"${PWD}")
  # multiline commands have preprended ';' (starting at line 2)
  cmd="$(_last_command | sed -e '2,$s/^/;/')"
  printf ":%s:%s:%s:%s:%s:%s:%s:%s:%s:%s\n" \
    "${_SHELLHIST_TIMER}" "${now}" \
    "$(hostname)" "${USER}" "${dir}" \
    "$$" "${SHELL}" "${SHLVL}" \
    "${code}" "${cmd}" >> "${SHELLHIST_FILE}"
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
  unset _SHELLHIST_TIMER;
}

enable_shellhist

if [ "${ZSH_VERSION}" ]; then
  _last_command() { _zsh_last_command; }
  precmd() { _shellhist $?; }
elif [ "${BASH_VERSION}" ]; then
  _last_command() { _bash_last_command; }
  PROMPT_COMMAND='_shellhist $?;'$'\n'"${PROMPT_COMMAND}"
fi
