# Modern CLI tools

CZSH installs modern tools alongside the traditional Unix commands. Most are
compatible in spirit, not flag-for-flag, so learn the common cases first and
use <code>--help</code> for the rest.

## Quick mapping

| Traditional habit | CZSH tool | Why use it |
| --- | --- | --- |
| <code>ls -la</code> | <code>l</code> / <code>eza</code> | Git status, icons, readable defaults |
| <code>cat file</code> | <code>cat</code> / <code>bat</code> | Syntax highlighting and Git-aware display |
| <code>find</code> | <code>fd</code> | Short syntax, smart defaults, parallel execution |
| <code>grep -R</code> | <code>rg</code> | Very fast recursive text search |
| Manual JSON reading | <code>jq</code> | Query and transform structured data |
| <code>cd</code> with long paths | <code>z</code> / <code>zi</code> | Ranked directory history |
| Plain Git diff pager | <code>delta</code> | Syntax-aware, readable diffs |
| Repeated <code>cd</code> in a file manager | <code>y</code> | TUI file manager that can change the shell directory |
| <code>top</code> / <code>htop</code> | <code>btop</code> | Interactive, mouse-aware CPU/memory/process monitor |
| <code>du -sh *</code> | <code>dust</code> | Sorted, tree-shaped disk usage at a glance |
| Reading raw Markdown in a pager | <code>glow</code> | Rendered Markdown, including tables and code blocks |
| Plaintext secrets in a repo | <code>sops</code> | Encrypts values in YAML/JSON/env files, decryptable in CI |

## eza: directory listings

CZSH defines:

~~~sh
alias l='eza -la --git --icons'
~~~

Use it as the everyday detailed listing:

~~~sh
l
l src
~~~

Useful direct eza commands:

~~~sh
eza --tree --level=2
eza -lah --sort=modified
eza -la --git --group-directories-first
~~~

The Git column describes the repository state of each entry. Icons require a
Nerd Font selected in the terminal application, not merely installed on disk.

To bypass the alias for a script-like one-off command:

~~~sh
command ls -la
~~~

## bat: reading files

CZSH maps <code>cat</code> to <code>bat -p</code>. The <code>-p</code> option
keeps output plain by hiding bat's border and line-number decorations while
retaining syntax highlighting.

~~~sh
cat README.md
bat --style=numbers README.md
bat -n features/post/10-prompt.zsh
bat -r 20:45 README.md
~~~

Use the system cat explicitly when exact byte-for-byte behavior matters:

~~~sh
command cat file.bin
~~~

For pipelines, most programs detect that output is not a terminal and suppress
color automatically. If another program dislikes colored input, bypass the
alias with <code>command cat</code>.

## ripgrep: searching file contents

The executable is named <code>rg</code>. Its default recursive search respects
<code>.gitignore</code> and skips hidden and binary files.

~~~sh
# Search recursively from the current directory
rg "TODO"

# Include line numbers and search only Zsh files
rg -n "eval" -g '*.zsh'

# Match whole words, ignoring case
rg -i -w "error"

# Print only filenames containing a match
rg -l "CZSH_THEME"

# Include hidden files while still respecting ignore rules
rg --hidden "shellcheck"

# Search ignored files too, but continue to skip .git internals
rg --hidden --no-ignore -g '!.git/' "needle"
~~~

Use single quotes around patterns containing <code>$</code>, <code>*</code>,
brackets, or other shell-significant characters.

### Interactive CZSH search

The <code>s</code> function combines ripgrep, FZF, and a bat preview:

~~~sh
s "status-interval"
s "function_name"
~~~

Type more text inside FZF to narrow the matches, use the arrow keys to move,
and press <kbd>Enter</kbd> to accept. Press <kbd>Esc</kbd> to cancel.

## fd: finding paths

fd searches names; rg searches file contents. fd also respects
<code>.gitignore</code> and skips hidden paths by default.

~~~sh
# Find Markdown files
fd -e md

# Find directories with config in their name
fd -t d config

# Include hidden files
fd -H -t f

# Search below one directory
fd -e zsh . features

# Run a command for every match
fd -e md -x wc -l
~~~

The general shape is <code>fd OPTIONS PATTERN PATH</code>. A dot is useful when
you want “match everything”:

~~~sh
fd -t f . docs
~~~

CZSH's <code>f</code> helper opens a fuzzy file picker with a bat preview and
prints the selected file's detected type:

~~~sh
f
~~~

It is an inspection helper, not a file opener. Use an editor with fd and FZF
when you want to open the selection:

~~~sh
nvim "$(fd -t f | fzf)"
~~~

## FZF: the common picker language

FZF appears in completion, searches, process selection, Git helpers, and tmux
popups. The core interactions transfer between all of them:

| Key | Action |
| --- | --- |
| Type text | Narrow candidates with a fuzzy query |
| Arrow keys or <kbd>Ctrl</kbd>+<kbd>J/K</kbd> | Move |
| <kbd>Enter</kbd> | Accept |
| <kbd>Esc</kbd> or <kbd>Ctrl</kbd>+<kbd>C</kbd> | Cancel |

At a normal shell prompt, press <kbd>Tab</kbd> to invoke fuzzy completion:

~~~sh
cd ~/wor<Tab>
git checkout <Tab>
kill <Tab>
~~~

Completion understands the command, so the candidates differ by context.
CZSH customizes completion keys as follows:

| Key in completion | Action |
| --- | --- |
| <kbd>Tab</kbd> | Move to the next item |
| <kbd>Shift</kbd>+<kbd>Tab</kbd> | Move to the previous item |
| <kbd>Ctrl</kbd>+<kbd>Space</kbd> | Mark or unmark the item, then move down |
| <kbd>Enter</kbd> | Insert the marked items |
| <kbd>F1</kbd> / <kbd>F2</kbd> | Move between completion groups |
| <kbd>/</kbd> | Accept a directory and continue completing below it |

## jq: querying JSON

The dot means “the current JSON value.” Build from that idea:

~~~sh
# Pretty-print
curl -s https://api.github.com/repos/jqlang/jq | jq .

# Select one field
curl -s https://api.github.com/repos/jqlang/jq | jq -r '.default_branch'

# Select fields from every object in an array
printf '%s\n' '[{"name":"api","port":8080},{"name":"web","port":3000}]' |
  jq -r '.[] | "\(.name):\(.port)"'

# Filter an array
printf '%s\n' '[1,2,3,4]' | jq '.[] | select(. > 2)'
~~~

Without <code>-r</code>, jq emits JSON strings including their quotes.
Use <code>-r</code> when the result is intended for another shell command.

## Yazi: terminal file management

Launch it through the CZSH wrapper:

~~~sh
y
y ~/Downloads
~~~

Navigate in Yazi, then quit. The wrapper reads Yazi's exit directory and
changes the parent shell to it. Running <code>yazi</code> directly cannot
change its parent shell's directory.

Run <code>yazi --help</code> for command-line options and press
<kbd>~</kbd> inside Yazi for its keymap help.

## Lazydocker and Lazyjournal

Lazydocker provides an interactive view of Docker containers, images, volumes,
logs, and Compose services:

~~~sh
lazydocker
~~~

Inside tmux, prefix + <kbd>Shift</kbd>+<kbd>D</kbd> opens it as a popup. Press
<kbd>?</kbd> for context-sensitive keys and <kbd>q</kbd> to quit. CZSH installs
Lazydocker, but it does not install or start Docker Engine.

On supported Linux systems with <code>journalctl</code>, CZSH also installs
Lazyjournal:

~~~sh
lazyjournal
~~~

Use it to browse and filter systemd journal entries interactively. It is not
installed on macOS or on Linux systems without journalctl.

## btop: resource monitor

~~~sh
btop
~~~

Press <kbd>Esc</kbd> or <kbd>q</kbd> to quit, <kbd>m</kbd> to cycle layout
presets, and click or use arrow keys to select a process before pressing
<kbd>k</kbd> to signal it. Prefer CZSH's <code>kp</code> for a quick
fuzzy-picked kill; reach for <code>btop</code> when you need to watch load
over time.

## dust: disk usage

~~~sh
dust
dust -d 2 ~/workspace
dust -X node_modules
~~~

Output is sorted largest-first with an inline bar chart, so the heaviest
directories are visible without scrolling past everything else the way
<code>du -sh *</code> requires.

## glow: reading Markdown

~~~sh
glow README.md
glow docs/
glow -p docs/cheat-sheet.md
~~~

<code>glow -p</code> paginates long documents. Run <code>glow</code> with a
directory to get a fuzzy picker over every Markdown file beneath it.

## sops: encrypting secrets

<code>sops</code> encrypts individual values inside a YAML, JSON, ENV, or INI
file, so the file stays diffable and reviewable in Git while the secret
values themselves stay opaque. It needs a key backend (age or a cloud KMS)
before first use:

~~~sh
age-keygen -o ~/.config/sops/age/keys.txt
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
~~~

Create a repo-level `.sops.yaml` pointing at your public key, then:

~~~sh
sops secrets.enc.yaml       # opens the decrypted content in $EDITOR, re-encrypts on save
sops -d secrets.enc.yaml    # decrypt to stdout
~~~

CZSH installs the `sops` binary only; it does not generate keys or a
`.sops.yaml` for you.

## Small CZSH helpers

~~~sh
myip            # print the public IP address
kp              # select processes and send TERM
kp -9           # select processes and send KILL
git-update-all  # pull repositories below the current directory
~~~

Prefer plain <code>kp</code>. It allows a process to shut down cleanly.
<code>kp -9</code> is an explicit last resort and can cause data loss.

<code>git-update-all</code> searches below the current directory, so run it
from a deliberate workspace root:

~~~sh
cd ~/workspace
git-update-all
~~~

It performs <code>git pull --rebase --autostash</code> in each discovered
repository. Review repositories with important uncommitted work before using
it.

## Practice

1. Find every Markdown file with fd.
2. Search those documents for “tmux” with rg.
3. Inspect one result with bat.
4. Use <code>s "tmux"</code> and compare the interactive workflow.
5. Open Yazi with <code>y</code>, navigate elsewhere, quit, and check
   <code>pwd</code>.
