# History, navigation, and project environments

Atuin, zoxide, and direnv solve three related problems:

- Atuin remembers what you ran.
- zoxide remembers where you worked.
- direnv remembers what a project needs in its environment.

Together they remove much of the repeated setup from changing projects.

## Atuin: searchable shell history

CZSH binds <kbd>Ctrl</kbd>+<kbd>R</kbd> to Atuin. Atuin records more context
than a plain history file, including the directory, session, time, duration,
and exit status of a command.

### Everyday workflow

1. Press <kbd>Ctrl</kbd>+<kbd>R</kbd>.
2. Type fragments from anywhere in the command.
3. Move to the desired result.
4. Press <kbd>Tab</kbd> to return it to the prompt.
5. Review or edit it, then execute it.

With Atuin's default <code>enter_accept = true</code> setting,
<kbd>Enter</kbd> executes the selected command immediately. Use
<kbd>Tab</kbd> when you want the safer review-and-edit path. If you set
<code>enter_accept = false</code> in Atuin's config, both keys return the
selection to the prompt.

For example, after running:

~~~sh
docker compose -f compose.dev.yml up --build
~~~

you might retrieve it later with <code>compose build</code>. Fuzzy search does
not require those words to be adjacent.

The interactive display includes its current search and filter mode plus
keybinding hints. Those hints are the authoritative reference because Atuin
can use either Emacs or Vim keymaps.

### Search from the command line

Atuin is also useful outside the interactive picker:

~~~sh
# Search all history
atuin search docker

# Limit results to the current directory
atuin search --cwd "$PWD" migration

# Find successful commands
atuin search --exit 0 deploy

# Exclude commands that returned exit code 1
atuin search --exclude-exit 1 test

# Return only command text
atuin search --cmd-only --limit 10 git

# Inspect usage patterns
atuin stats
~~~

Run <code>atuin search --help</code> to see filters for date, host, session,
directory, shell, and exit status.

### Local history versus sync

Atuin works locally immediately. Cloud synchronization is optional and is not
enabled by the CZSH installer.

To create an Atuin account, let the CLI prompt for credentials rather than
putting a password in shell history:

~~~sh
atuin register
atuin status
atuin sync
~~~

On another machine:

~~~sh
atuin login
atuin sync
~~~

Save the encryption key shown during registration in a password manager.
History is encrypted with that key, and losing it can make synchronized data
unrecoverable. Inspect account and synchronization commands before enabling
them:

~~~sh
atuin account --help
atuin key
atuin status
~~~

### Privacy habits

Do not type secrets directly into commands when an application can read them
from a prompt, file descriptor, keychain, or environment provided securely.
Shell history tools cannot protect a secret that was entered as a command-line
argument.

For one-off sensitive commands, consult the tool's own history-filter settings:

~~~sh
atuin default-config | less
atuin info
~~~

## zoxide: ranked directory jumping

The first time you visit a directory, use normal <code>cd</code>. zoxide
observes directory changes and assigns frequently and recently used locations
a higher rank.

~~~sh
cd ~/workspace/czsh
cd ~/workspace/customer-api
cd ~/Documents/notes
~~~

Later, jump using fragments:

~~~sh
z czsh
z customer api
z notes
~~~

The fragments do not need to form the complete path. If the automatic choice
is ambiguous, use the interactive picker:

~~~sh
zi
zi api
~~~

Useful diagnostics:

~~~sh
zoxide query czsh
zoxide query -l
zoxide --help
~~~

zoxide becomes better through ordinary use. Avoid manually adding a large list
on day one; visit projects naturally and let ranking reflect real habits.

### How zoxide feeds tmux

The CZSH session picker includes:

- existing tmux sessions,
- paths known to zoxide, and
- directories up to two levels below <code>~/workspace</code>.

This means a project outside <code>~/workspace</code> can still appear in the
tmux picker after it has been visited and learned by zoxide.

## direnv: environments that follow directories

direnv watches for an <code>.envrc</code> file when the prompt changes. It
loads the file when entering the directory and reverses its environment
changes when leaving.

The safety model is explicit: a new or changed <code>.envrc</code> is blocked
until you review and allow it.

### Basic environment variables

Create <code>.envrc</code> in a project:

~~~sh
export APP_ENV=development
export API_URL=http://localhost:8080
~~~

Review it, then approve it:

~~~sh
cat .envrc
direnv allow
~~~

Test automatic load and unload:

~~~sh
echo "$APP_ENV"
cd ..
echo "$APP_ENV"
cd -
echo "$APP_ENV"
~~~

If you edit <code>.envrc</code>, direnv blocks the changed version until
<code>direnv allow</code> is run again.

### Add project scripts to PATH

Given a project-local <code>bin</code> directory:

~~~sh
PATH_add bin
~~~

Now executables under <code>./bin</code> are available only while inside the
project.

### Load an optional dotenv file

In <code>.envrc</code>:

~~~sh
dotenv_if_exists .env
~~~

Keep secret-bearing <code>.env</code> files out of Git. Commit a
<code>.env.example</code> containing safe placeholder names instead.

### Project-local Python environment

direnv's standard library can create and activate a virtual environment:

~~~sh
layout python3
~~~

After <code>direnv allow</code>, entering the directory activates the
environment and leaving deactivates it. The environment location is managed by
direnv; inspect it with:

~~~sh
direnv status
which python
python --version
~~~

### Run one command in a project environment

This is useful in scripts and CI because it does not depend on an interactive
shell hook:

~~~sh
direnv exec /path/to/project env
direnv exec . ./scripts/test.sh
~~~

### Debugging direnv

~~~sh
direnv status
direnv reload
direnv deny
direnv stdlib | less
~~~

Use <code>direnv deny</code> to revoke approval. Never approve an
<code>.envrc</code> from an untrusted repository without reading it: allowing
the file authorizes executable shell code, not just variable declarations.

## A complete project example

A small application might contain:

~~~text
my-app/
├── .env.example
├── .envrc
├── .gitignore
├── bin/
│   └── dev
└── src/
~~~

Its <code>.envrc</code>:

~~~sh
export APP_ENV=development
PATH_add bin
dotenv_if_exists .env
layout python3
~~~

Its <code>.gitignore</code>:

~~~text
.env
.direnv/
~~~

The first visit is:

~~~sh
cd ~/workspace/my-app
cat .envrc
direnv allow
~~~

Future visits can be:

~~~sh
z my-app
~~~

or, from inside tmux, <kbd>Ctrl</kbd>+<kbd>F</kbd> followed by the project
name. The directory change loads the environment automatically.

## Practice

1. Retrieve a command using two non-adjacent words with <kbd>Ctrl</kbd>+<kbd>R</kbd>.
2. Compare <code>atuin search git</code> with
   <code>atuin search --cwd "$PWD" git</code>.
3. Visit three projects, then use <code>zi</code> to choose between them.
4. Create a disposable <code>.envrc</code>, allow it, leave the directory,
   and confirm that its variable disappears.
