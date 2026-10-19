# use-env

Explicit, per-terminal environment profiles for zsh.

A profile is a small file of environment variables (`AWS_PROFILE`, `KUBECONFIG`, …).
`use-env <profile>` opens a new zsh with those variables set, and `exit` takes you
back with all of them gone. Every terminal is independent, and a terminal with no
profile has none of them set.

```
$ use-env example        # enter a profile
$ use-env                # no argument: pick a profile from a list (fzf, or a numbered menu)
$ use-env -l             # list profiles
$ exit                   # leave the profile
```

## Setup

### 1. Get the tool

Clone this repository anywhere, e.g. `~/Development/shell-profiles`.

### 2. Configure `~/.zshrc`

Source `use-env.zsh` **after** oh-my-zsh (or your theme) is loaded:

```zsh
source ~/Development/shell-profiles/use-env.zsh
```

On its own, this provides the `use-env` command and Tab completion of profile names.
It does not change your prompt. To show the active profile, pick **one** option:

**a) A native agnoster block** (oh-my-zsh `agnoster` theme). The profile becomes the
first block of the prompt strip, in the profile's colours. Set the variable before
the `source` line:

```zsh
USE_ENV_PROMPT=agnoster
source ~/Development/shell-profiles/use-env.zsh
```

**b) Anywhere in any prompt.** `shell_profile_prompt_info` prints a coloured label.
Use single quotes, so it is evaluated on every prompt:

```zsh
source ~/Development/shell-profiles/use-env.zsh
RPROMPT='$(shell_profile_prompt_info)'       # right side
# PROMPT='$(shell_profile_prompt_info) '$PROMPT   # or in front of the left prompt
```

`prompt_subst` must be enabled (oh-my-zsh does this already; otherwise add
`setopt prompt_subst`).

**c) Build your own** from the variables listed under *Inside a profile shell*.

If the same `.zshrc` is shared across machines (dotfiles), guard the source line:

```zsh
if [[ -r ~/Development/shell-profiles/use-env.zsh ]]; then
  USE_ENV_PROMPT=agnoster
  source ~/Development/shell-profiles/use-env.zsh
fi
```

### 3. Create profiles

Profiles live in `~/.config/use-env/<name>.env`. The directory is
`$XDG_CONFIG_HOME/use-env` if `XDG_CONFIG_HOME` is set, and can be overridden with
`USE_ENV_DIR` (set it before the `source` line). They are kept outside this
repository on purpose: the tool is shareable, the profiles are yours.

See [`examples/example.env`](examples/example.env):

```ini
# prompt block background and text
@bg=160
@fg=183
AWS_PROFILE=example-profile
KUBECONFIG=$HOME/.kube/example.yaml
# any variable works, e.g. hide agnoster's own AWS block
SHOW_AWS_PROMPT=false
```

- `KEY=value` lines are exported in the profile shell. `$VARS` and `$(commands)` in
  values are expanded. Use `$HOME`, not `~`.
- `@bg` / `@fg` set the prompt colours: names (`red`, `green`, …), `0`–`255`, or
  `#rrggbb` (needs a true-colour terminal). Defaults: green background, black text.
- Blank lines and lines starting with `#` are ignored. A `#` after a value is part of
  the value, not a comment. Any other line is an error, and the profile is not entered.

## Inside a profile shell

| Variable | Value |
|---|---|
| `SHELL_PROFILE` | profile name |
| `SHELL_PROFILE_BG`, `SHELL_PROFILE_FG` | prompt colours from `@bg` / `@fg` |
| everything from the profile file | as written |

Programs started from this shell inherit these variables, including editors, `k9s`
and AI coding agents.

## Behaviour

- **One profile at a time.** `use-env` refuses to run inside a profile shell; `exit` first.
- **Your normal shell.** The profile shell is a regular interactive zsh that loads
  your `.zshrc`. Exported variables carry over from the parent shell; unexported
  variables and ad-hoc aliases don't.
- **History** is shared as usual when your setup uses a single `HISTFILE` with
  `share_history` (oh-my-zsh's default).
