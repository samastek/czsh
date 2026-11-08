# History, navigation, and project environments

Shell history, zoxide, and direnv solve three related problems:

- <kbd>Ctrl</kbd>+<kbd>R</kbd> finds what you ran.
- zoxide remembers where you worked.
- direnv remembers what a project needs in its environment.

Together they remove much of the repeated setup from changing projects.

## FZF: searchable shell history

CZSH binds <kbd>Ctrl</kbd>+<kbd>R</kbd> to FZF's history widget, which searches
the normal Zsh history file.

1. Press <kbd>Ctrl</kbd>+<kbd>R</kbd>.
2. Type fragments from anywhere in the command.
3. Move to the desired result with the arrow keys or <kbd>Ctrl</kbd>+<kbd>J</kbd>/<kbd>K</kbd>.
4. Press <kbd>Enter</kbd> to put it on the prompt, review or edit it, then run it.

Press <kbd>Ctrl</kbd>+<kbd>R</kbd> again inside the picker to switch between
newest-first and relevance ordering. Prefix a word with <code>'</code> for an
exact match, or <code>^</code> to match the start of the command.

For example, after running:

~~~sh
docker compose -f compose.dev.yml up --build
~~~

you might retrieve it later with <code>compose build</code>. Fuzzy search does
not require those words to be adjacent.

Plain Zsh commands cover history outside the picker:

~~~sh
history -20          # last 20 commands
fc -l 1 | rg docker  # search all history
~~~

Do not type secrets directly into commands when an application can read them
from a prompt, file, or keychain. A command that starts with a space is not
saved to history.

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
2. Inside the <kbd>Ctrl</kbd>+<kbd>R</kbd> picker, press <kbd>Ctrl</kbd>+<kbd>R</kbd>
   again and compare the two orderings.
3. Visit three projects, then use <code>zi</code> to choose between them.
4. Create a disposable <code>.envrc</code>, allow it, leave the directory,
   and confirm that its variable disappears.
