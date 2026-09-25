# Tmux workflow

Tmux keeps terminal work alive independently of one terminal window or SSH
connection. CZSH adds project selection, Vim-aware navigation, application
popups, and automatic persistence.

## The four objects

~~~text
tmux server
└── session: one project or work context
    ├── window: a full-screen activity
    │   ├── pane: shell, editor, log, or process
    │   └── pane
    └── window
~~~

- A server owns all tmux state.
- A session is usually one project.
- A window is similar to a terminal tab.
- A pane is one rectangular terminal inside a window.

Detaching closes the client view, not the session. Processes continue running.

## Prefix notation

The CZSH prefix is <kbd>Ctrl</kbd>+<kbd>A</kbd>. When this guide says
“prefix + c”:

1. Hold <kbd>Ctrl</kbd>, press <kbd>A</kbd>, then release both.
2. Press lowercase <kbd>c</kbd> without Ctrl.

A letter explicitly preceded by <kbd>Shift</kbd> means holding that modifier.

Start a server and session with:

~~~sh
tmux
~~~

Detach with prefix + <kbd>d</kbd>. Reattach later:

~~~sh
tmux attach
~~~

## Project sessions

Press prefix + <kbd>f</kbd>, or press <kbd>Ctrl</kbd>+<kbd>F</kbd> without
the prefix while inside tmux.

The picker combines existing sessions, zoxide history, and project directories
under <code>~/workspace</code>. Existing tmux sessions stay at the top in green
<code>● SESSION</code> rows marked as running, with current/attached state and
window count; the current session is muted gray. Directories
that can open a project are shown as a blue <code>◆ PROJECT</code> row with the
project name and full path. If a directory already has a session, only its
session row is shown. Choosing a directory:

1. derives a safe default session name from the directory name,
2. opens a naming prompt for a new session,
3. uses the default when <kbd>Enter</kbd> is pressed on an empty prompt, and
4. creates the session in that directory and switches the current client to it.

Custom names may contain letters, numbers, underscores, and hyphens. Press
<kbd>Ctrl</kbd>+<kbd>C</kbd> at the naming prompt to cancel without creating a
session. Selecting an existing session switches immediately without showing
the naming prompt.

Type part of a project name, move to the result, and press
<kbd>Enter</kbd>. Press <kbd>Esc</kbd> to cancel.

Manual session commands remain available:

~~~sh
tls                 # list sessions
tns documentation   # create a named session
ta documentation    # attach to it
tks documentation   # terminate it
~~~

Inside tmux, the built-in session picker is prefix + <kbd>s</kbd> and session
rename is prefix + <kbd>$</kbd>. Destroying the current session moves the client
to the next remaining session in alphabetical order instead of closing the tmux
client. If no other sessions remain, the client detaches normally.

## Windows

Use windows for activities that each deserve the full terminal area:

| Binding | Action |
| --- | --- |
| prefix + <kbd>c</kbd> | New window in the current pane's directory |
| prefix + <kbd>,</kbd> | Rename the current window |
| prefix + <kbd>w</kbd> | Interactive window picker |
| prefix + <kbd>1</kbd>…<kbd>9</kbd> | Jump to a numbered window |
| <kbd>Shift</kbd>+<kbd>Left/Right</kbd> | Previous or next window |
| prefix + <kbd>&</kbd> | Close the current window |
| prefix + <kbd>&lt;</kbd>/<kbd>&gt;</kbd> | Move the window left or right |

CZSH automatically names a window after the active pane's directory. Rename a
window when a semantic label such as <code>tests</code> or <code>logs</code>
is more useful.

## Panes

| Binding | Action |
| --- | --- |
| prefix + <kbd>|</kbd> | Split side by side |
| prefix + <kbd>-</kbd> | Split top and bottom |
| prefix + <kbd>h/j/k/l</kbd> | Move left/down/up/right |
| prefix + <kbd>Shift</kbd>+<kbd>H/J/K/L</kbd> | Resize by five cells; repeatable |
| prefix + <kbd>z</kbd> | Toggle zoom for the active pane |
| prefix + <kbd>x</kbd> | Close the active pane |
| prefix + <kbd>q</kbd>, then a number | Select a numbered pane |

New panes start in the current pane's working directory.

### Seamless Vim and Neovim navigation

Use <kbd>Ctrl</kbd>+<kbd>H/J/K/L</kbd> to move in one direction. When the
current pane is running Vim or Neovim, the keys move between editor splits.
At an editor edge, the same keys cross into the neighboring tmux pane.

This lets one spatial model work across both layers:

~~~text
Ctrl+H  left
Ctrl+J  down
Ctrl+K  up
Ctrl+L  right
~~~

The installer links the editor-side navigator bridge for both Vim and Neovim.
Run <code>czsh doctor</code> if the keys work in tmux but not across editor
splits.

## Popups

Popups provide temporary full-screen tools without consuming a window:

| Binding | Popup |
| --- | --- |
| prefix + <kbd>g</kbd> | Lazygit in the active pane's directory |
| prefix + <kbd>Shift</kbd>+<kbd>D</kbd> | Lazydocker |
| prefix + <kbd>/</kbd> | Search all sessions, windows, and panes |
| prefix + <kbd>e</kbd> | CZSH tmux help |

In the window/pane search popup, type a session, directory, command, or window
name. The selected pane becomes active.

For Lazygit, lowercase <kbd>g</kbd> is used. Lazydocker uses uppercase
<kbd>D</kbd>, so hold <kbd>Shift</kbd> for that binding.

## Copy mode and scrollback

Enter copy mode with prefix + <kbd>Enter</kbd>.

| Key in copy mode | Action |
| --- | --- |
| Vim movement keys | Move through the 50,000-line history |
| <kbd>v</kbd> | Begin selection |
| <kbd>Ctrl</kbd>+<kbd>V</kbd> | Toggle rectangular selection |
| <kbd>y</kbd> | Copy and stay in copy mode |
| <kbd>Esc</kbd> | Cancel |

Mouse support is enabled for pane selection, resizing, and scrollback. In a
shell pane, the wheel scrolls tmux history; in mouse-aware applications such as
Codex, it scrolls the application. GNOME Terminal lets you bypass tmux mouse
handling by holding <kbd>Shift</kbd> while dragging, so the terminal selects
text without entering tmux copy mode. To browse tmux history with the
keyboard, enter copy mode with prefix + <kbd>Enter</kbd>. The <kbd>y</kbd> key
copies to the system clipboard and stays in copy mode; <kbd>Escape</kbd> leaves
it.

## Persistence

tmux-continuum saves state every 15 minutes and asks tmux-resurrect to restore
it when a new tmux server starts.

Manual controls are useful before a reboot or a large rearrangement:

| Binding | Action |
| --- | --- |
| prefix + <kbd>Ctrl</kbd>+<kbd>S</kbd> | Save now |
| prefix + <kbd>Ctrl</kbd>+<kbd>R</kbd> | Restore now |

Resurrect can restore sessions, windows, panes, directories, and captured pane
contents. It cannot reliably recreate arbitrary in-memory application state.
Save work inside editors and applications normally.

## Reading the status bar

The current window is green. The right side can show:

- A battery indicator on supported laptops.
- Available RAM on supported systems.
- <code>sync</code> when pane input synchronization is enabled.
- The hostname when connected through SSH.
- Date and time.

## A practical project layout

One session might use:

~~~text
session: customer-api
├── window 1: editor
│   ├── pane 1: nvim
│   └── pane 2: test watcher
├── window 2: server
│   ├── pane 1: application
│   └── pane 2: logs
└── window 3: shell
~~~

Build it:

1. Pick the project with prefix + <kbd>f</kbd>.
2. Start the editor in window 1.
3. Split with prefix + <kbd>|</kbd> and start tests.
4. Create window 2 with prefix + <kbd>c</kbd>.
5. Split with prefix + <kbd>-</kbd> for logs.
6. Save with prefix + <kbd>Ctrl</kbd>+<kbd>S</kbd>.

## Recovery and help

~~~sh
tmux list-sessions
tmux attach -t SESSION
tmux kill-session -t SESSION
tmux source-file ~/.tmux.conf
tmux-help
~~~

Use prefix + <kbd>e</kbd> for the same help in a popup and prefix +
<kbd>?</kbd> for tmux's complete active key table.

## Practice

1. Create a project session with the picker.
2. Create two windows and two panes.
3. Move through panes with both prefix navigation and Ctrl navigation.
4. Open Lazygit, close the popup, and search for a pane.
5. Detach, close the terminal, open a new terminal, and reattach.
