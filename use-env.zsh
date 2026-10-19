# use-env — explicit, per-terminal environment profiles for zsh.
#
# A profile is a file of KEY=value lines (plus optional @bg/@fg prompt colours)
# in $USE_ENV_DIR (default: ${XDG_CONFIG_HOME:-~/.config}/use-env/<name>.env).
# `use-env <name>` starts a child zsh with those variables exported; `exit`
# drops them all. Profiles cannot be nested.
#
# Source this file from ~/.zshrc (after oh-my-zsh / your theme is loaded).

: ${USE_ENV_DIR:=${XDG_CONFIG_HOME:-$HOME/.config}/use-env}

_use_env_profiles() {
  print -l -- $USE_ENV_DIR/*.env(N:t:r)
}

_use_env_usage() {
  cat <<'EOF'
usage: use-env [<profile>]   start a shell with <profile> (no argument: pick from a list)
       use-env -l|--list      list profiles
       use-env -h|--help      show this help

Leave a profile shell with `exit`.
EOF
}

use-env() {
  case $1 in
    -h|--help) _use_env_usage; return ;;
    -l|--list) _use_env_profiles; return ;;
    -*) _use_env_usage >&2; return 2 ;;
  esac

  if [[ -n $SHELL_PROFILE ]]; then
    print -u2 "use-env: already in profile '$SHELL_PROFILE'; run 'exit' first"
    return 1
  fi

  local name=$1
  if [[ -z $name ]]; then
    local -a profiles=(${(f)"$(_use_env_profiles)"})
    if (( ! $#profiles )); then
      print -u2 "use-env: no profiles in $USE_ENV_DIR"
      return 1
    fi
    if (( $+commands[fzf] )); then
      name=$(print -l -- $profiles | fzf --height=~10 --reverse --prompt='profile> ') || return 1
    else
      local PS3='profile> '
      select name in $profiles; do [[ -n $name ]] && break; done
      [[ -n $name ]] || return 1
    fi
  fi

  local file=$USE_ENV_DIR/$name.env
  if [[ ! -f $file ]]; then
    print -u2 "use-env: no profile '$name' (looked for $file)"
    return 1
  fi

  # Everything below runs in a subshell, so nothing leaks into the current shell.
  (
    local line key value
    integer n=0
    while IFS= read -r line || [[ -n $line ]]; do
      (( n++ ))
      [[ $line =~ '^[[:space:]]*(#.*)?$' ]] && continue
      if [[ $line != *=* ]]; then
        print -u2 "use-env: $file:$n: expected KEY=value"
        exit 1
      fi
      key=${line%%=*}
      value=${(e)${line#*=}}   # expands $VARS and $(commands) in values
      case $key in
        @bg) export SHELL_PROFILE_BG=$value ;;
        @fg) export SHELL_PROFILE_FG=$value ;;
        @*)
          print -u2 "use-env: $file:$n: unknown setting '$key'"
          exit 1
          ;;
        *)
          if [[ ! $key =~ '^[A-Za-z_][A-Za-z0-9_]*$' ]]; then
            print -u2 "use-env: $file:$n: invalid variable name '$key'"
            exit 1
          fi
          export "$key=$value"
          ;;
      esac
    done < $file
    export SHELL_PROFILE=$name
    exec zsh -i
  )
}

# Ready-made coloured label for any prompt, e.g. RPROMPT='$(shell_profile_prompt_info)'.
shell_profile_prompt_info() {
  [[ -z $SHELL_PROFILE ]] && return
  print -n "%K{${SHELL_PROFILE_BG:-green}}%F{${SHELL_PROFILE_FG:-black}} $SHELL_PROFILE %f%k"
}

# Optional adapter: draw the profile as a native agnoster segment (first in the strip).
# Enable with USE_ENV_PROMPT=agnoster before sourcing this file.
if [[ $USE_ENV_PROMPT == agnoster ]]; then
  if (( $+functions[build_prompt] && $+functions[prompt_segment] )); then
    prompt_shell_profile() {
      [[ -z $SHELL_PROFILE ]] && return
      prompt_segment "${SHELL_PROFILE_BG:-green}" "${SHELL_PROFILE_FG:-black}" "$SHELL_PROFILE"
    }
    if (( ! $+functions[_use_env_orig_build_prompt] )); then
      functions[_use_env_orig_build_prompt]=$functions[build_prompt]
      build_prompt() {
        local r=$?
        prompt_shell_profile
        () { return $1 } $r   # keep $? for agnoster's status segment
        _use_env_orig_build_prompt
      }
    fi
  else
    print -u2 "use-env: USE_ENV_PROMPT=agnoster set, but the agnoster theme is not loaded"
  fi
fi

# Tab completion of profile names (needs compinit, which oh-my-zsh runs).
if (( $+functions[compdef] )); then
  _use_env() { compadd -- ${(f)"$(_use_env_profiles)"} }
  compdef _use_env use-env
fi
