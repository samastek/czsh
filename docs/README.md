# CZSH learning guide

This handbook teaches the workflow that CZSH installs. It is intentionally
task-oriented: each chapter explains the idea, shows realistic examples, and
ends with a small exercise.

You do not need to memorize every command. Start with the first three habits:

1. Press <kbd>Ctrl</kbd>+<kbd>R</kbd> instead of repeatedly pressing the up
   arrow.
2. Use <code>z keyword</code> instead of typing a full directory path.
3. Start tmux and press <kbd>Ctrl</kbd>+<kbd>A</kbd>, then <kbd>f</kbd>, to
   pick a project.

## Choose a learning path

| If you want to... | Read |
| --- | --- |
| Take a guided 20-minute tour | [First session](#first-session) |
| Replace older Unix commands with faster tools | [Modern CLI tools](modern-cli.md) |
| Find old commands, jump to projects, and load project environments | [History, navigation, and environments](history-navigation-environments.md) |
| Make tmux the center of the terminal workflow | [Tmux workflow](tmux-workflow.md) |
| Review, stage, and navigate Git changes interactively | [Git workflow](git-workflow.md) |
| Customize, update, diagnose, or benchmark CZSH | [Customization and maintenance](customization-maintenance.md) |
| Look up a key or command quickly | [Cheat sheet](cheat-sheet.md) |

## The mental model

CZSH combines several small tools rather than hiding everything behind one
large command:

~~~text
Zsh prompt
├── Atuin: command history
├── zoxide: directory history
├── direnv: per-project environment
├── FZF: interactive selection
│   ├── shell completion
│   └── file and text search
└── tmux: persistent workspaces
    ├── sessionizer: choose a project
    ├── panes and windows: arrange work
    ├── popups: Lazygit and Lazydocker
    └── continuum/resurrect: save and restore
~~~

The tools reinforce one another. Visiting a directory teaches zoxide about it.
Running a command teaches Atuin about it. Opening a project through the tmux
sessionizer combines existing tmux sessions, zoxide results, and directories
under <code>~/workspace</code>.

## First session

Open a new terminal or reload the current shell:

~~~sh
exec zsh
~~~

Confirm the managed environment is healthy:

~~~sh
czsh doctor
~~~

### 1. Explore files and text

Run these from the CZSH repository:

~~~sh
l
fd -e md
rg "tmux" docs
cat config.conf
~~~

Then try CZSH's interactive search:

~~~sh
s "CZSH_THEME"
~~~

Type to narrow the result, move with the arrow keys, and press
<kbd>Enter</kbd>. The selected match is previewed with bat.

### 2. Recall a command

Run a distinctive command:

~~~sh
printf 'learning-czsh\n'
~~~

Press <kbd>Ctrl</kbd>+<kbd>R</kbd>, type <code>learning</code>, and press
<kbd>Tab</kbd>. Atuin places the command on the prompt so it can be reviewed
or edited before execution. With Atuin's default setting, <kbd>Enter</kbd>
executes the selected command immediately.

### 3. Teach zoxide a project

Visit a few directories normally:

~~~sh
cd ~/workspace/czsh
cd /tmp
cd ~/workspace/czsh
~~~

Now jump using only a memorable fragment:

~~~sh
z czsh
~~~

Use <code>zi</code> when several locations might match and you want an FZF
picker.

### 4. Try a project environment

In a disposable directory:

~~~sh
mkdir -p /tmp/czsh-direnv-demo
cd /tmp/czsh-direnv-demo
printf '%s\n' 'export CZSH_DEMO=loaded' > .envrc
direnv allow
echo "$CZSH_DEMO"
cd ..
echo "$CZSH_DEMO"
~~~

The first <code>echo</code> prints <code>loaded</code>; the second is empty.
This is the central direnv idea: the environment enters and leaves with the
project. Review every <code>.envrc</code> before allowing it because it is
executable shell code.

### 5. Start the tmux workflow

Start tmux:

~~~sh
tmux
~~~

Press <kbd>Ctrl</kbd>+<kbd>A</kbd>, release both keys, then press
<kbd>f</kbd>. Pick a project. CZSH creates or switches to a named session in
that directory.

Inside the selected session, try:

- <kbd>Ctrl</kbd>+<kbd>A</kbd>, then <kbd>|</kbd> for a side-by-side pane.
- <kbd>Ctrl</kbd>+<kbd>A</kbd>, then <kbd>-</kbd> for a top-and-bottom pane.
- <kbd>Ctrl</kbd>+<kbd>A</kbd>, then <kbd>g</kbd> for a Lazygit popup.
- <kbd>Ctrl</kbd>+<kbd>A</kbd>, then <kbd>e</kbd> for the built-in help.

## How to discover commands

When you meet an unfamiliar command, use this sequence:

~~~sh
type z
type l
alias l
rg --help
man tmux
cheat rg
~~~

- <code>type</code> explains whether a name is an alias, function, builtin, or
  executable.
- <code>alias NAME</code> shows the expansion of an alias.
- <code>COMMAND --help</code> is usually the fastest exact reference.
- <code>man COMMAND</code> provides the complete manual.
- <code>cheat COMMAND</code> retrieves a short examples-first reference from
  cheat.sh and therefore requires network access.

Use <code>Ctrl+R</code> as personal documentation: once a useful command has
been run, a fragment of it is usually enough to retrieve it later.

## A suggested first week

| Day | Deliberate practice |
| --- | --- |
| 1 | Use <code>l</code>, <code>cat</code>, <code>fd</code>, and <code>rg</code>. |
| 2 | Use <kbd>Ctrl</kbd>+<kbd>R</kbd> for every command you remember imperfectly. |
| 3 | Replace long <code>cd</code> paths with <code>z</code> and <code>zi</code>. |
| 4 | Add a harmless <code>.envrc</code> to one project. |
| 5 | Work for an hour entirely inside one tmux session. |
| 6 | Review a real change with Delta and Lazygit. |
| 7 | Add one personal alias and run <code>czsh doctor</code>. |

The [cheat sheet](cheat-sheet.md) is designed to stay open during that first
week.
