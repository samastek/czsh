# CZSH cheat sheet

Keep this page nearby while building muscle memory. The longer explanations
live in the other chapters of the [learning guide](README.md).

## Everyday shell

| Command or key | Action |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>R</kbd> | Search command history with Atuin |
| <kbd>Tab</kbd> | Context-aware fuzzy completion |
| <code>l</code> | Detailed eza listing with Git and icons |
| <code>cat FILE</code> | Plain-style bat output |
| <code>fd PATTERN</code> | Find paths by name |
| <code>rg PATTERN</code> | Search file contents |
| <code>s QUERY</code> | Interactive text search with preview |
| <code>f</code> | Pick a file and print its detected type |
| <code>y [PATH]</code> | Open Yazi and cd to its exit directory |
| <code>z WORDS</code> | Jump to a ranked directory |
| <code>zi [WORDS]</code> | Pick a ranked directory interactively |
| <code>myip</code> | Show public IP |
| <code>kp</code> | Select processes and send TERM |
| <code>kp -9</code> | Select processes and send KILL |
| <code>cheat COMMAND</code> | Fetch a short examples-first reference |

## Search examples

~~~sh
fd -e md
fd -t d config
fd -H -t f

rg -n "TODO"
rg -i -w "error"
rg -g '*.zsh' "eval"
rg --hidden "shellcheck"

s "status-interval"
~~~

## History, directories, and environments

~~~sh
atuin search --cwd "$PWD" git
atuin search --exit 0 deploy
atuin stats

z project-name
zi
zoxide query -l

cat .envrc
direnv allow
direnv status
direnv deny
~~~

Common <code>.envrc</code>:

~~~sh
export APP_ENV=development
PATH_add bin
dotenv_if_exists .env
layout python3
~~~

## Git

| Command | Action |
| --- | --- |
| <code>git diff</code> | Diff through Delta |
| <code>git status</code> | Show repository state |
| <code>git log --oneline --graph</code> | Compact history |
| <code>git add -p</code> | Interactively stage hunks |
| <code>git restore --staged FILE</code> | Unstage a file |
| <code>git switch BRANCH</code> | Change branches |
| <code>git stash</code> | Stash current changes |
| <code>git worktree list</code> | List worktrees |
| <code>git soft-reset-base</code> | Soft-reset to the current branch's creation commit |
| <code>lazygit</code> | Full repository TUI |
| <code>git-update-all</code> | Pull repositories below current directory |

Treat <code>kp -9</code> as a destructive operation: read the process
selection before confirming.

## Tmux

Prefix is <kbd>Ctrl</kbd>+<kbd>A</kbd>.

### Sessions and help

| Binding | Action |
| --- | --- |
| prefix + <kbd>f</kbd> | Pick project/session |
| <kbd>Ctrl</kbd>+<kbd>F</kbd> | Pick project/session without prefix |
| prefix + <kbd>d</kbd> | Detach |
| prefix + <kbd>s</kbd> | Built-in session picker |
| prefix + <kbd>e</kbd> | CZSH keybinding help |
| prefix + <kbd>?</kbd> | All active tmux bindings |

### Windows and panes

| Binding | Action |
| --- | --- |
| prefix + <kbd>c</kbd> | New window in current directory |
| prefix + <kbd>|</kbd> | Split side by side |
| prefix + <kbd>-</kbd> | Split top and bottom |
| prefix + <kbd>h/j/k/l</kbd> | Move across panes |
| <kbd>Ctrl</kbd>+<kbd>H/J/K/L</kbd> | Move across Vim splits and tmux panes |
| prefix + <kbd>Shift</kbd>+<kbd>H/J/K/L</kbd> | Resize panes |
| prefix + <kbd>z</kbd> | Toggle pane zoom |
| <kbd>Shift</kbd>+<kbd>Left/Right</kbd> | Change window |

### Popups and persistence

| Binding | Action |
| --- | --- |
| prefix + <kbd>g</kbd> | Lazygit popup |
| prefix + <kbd>Shift</kbd>+<kbd>D</kbd> | Lazydocker popup |
| prefix + <kbd>/</kbd> | Search windows and panes |
| prefix + <kbd>Ctrl</kbd>+<kbd>S</kbd> | Save session state |
| prefix + <kbd>Ctrl</kbd>+<kbd>R</kbd> | Restore session state |
| prefix + <kbd>r</kbd> | Reload tmux configuration |

### Copy mode

| Binding | Action |
| --- | --- |
| prefix + <kbd>Enter</kbd> | Enter copy mode |
| <kbd>v</kbd> | Begin selection |
| <kbd>Ctrl</kbd>+<kbd>V</kbd> | Rectangle selection |
| <kbd>y</kbd> | Copy to system clipboard |
| <kbd>Esc</kbd> | Cancel |

Mouse-drag selection copies to the clipboard and stays at the selected
scrollback position.

## Prompt Git markers

| Marker | Meaning |
| --- | --- |
| <code> branch</code> | Branch |
| <code>⇡N</code> / <code>⇣N</code> | Ahead / behind |
| <code>+N</code> | Staged |
| <code>~N</code> | Modified |
| <code>?N</code> | Untracked |
| <code>!N</code> | Conflicted |
| <code>≡N</code> | Stashed |

## Maintenance

~~~sh
czsh doctor
./install.sh
./install.sh --upgrade
./install.sh --neovim
./install.sh --uninstall
./scripts/validate.sh
./scripts/bench.sh
exec zsh
~~~

## Discover instead of memorize

~~~sh
type NAME
alias NAME
COMMAND --help
man COMMAND
cheat COMMAND
tmux-help
~~~
