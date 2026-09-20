# Git workflow

CZSH offers two levels of Git interaction:

1. Normal Git commands, displayed through Delta.
2. A complete Lazygit interface, especially convenient as a tmux popup.

Use whichever level matches the task. They all operate on the same repository
and can be mixed freely.

## Passive Git context

Outside tmux, the prompt shows the branch and whether staged or unstaged
changes exist. Inside tmux, the status bar carries richer Git information:

| Marker | Meaning |
| --- | --- |
| <code> branch</code> | Current branch |
| <code>⇡N</code> / <code>⇣N</code> | Ahead / behind upstream |
| <code>+N</code> | Staged |
| <code>~N</code> | Modified |
| <code>?N</code> | Untracked |
| <code>!N</code> | Conflicted |
| <code>≡N</code> | Stashed |

This is context, not a replacement for <code>git status</code>. Run the full
command before committing or discarding changes.

## Delta: readable Git output

CZSH exports Delta as <code>GIT_PAGER</code>, so familiar Git commands become
easier to scan without changing their behavior:

~~~sh
git diff
git diff --staged
git show HEAD
git log -p
git blame src/main.rs
~~~

Pager basics:

| Key | Action |
| --- | --- |
| <kbd>Space</kbd> / <kbd>b</kbd> | Page forward / backward |
| <kbd>j</kbd> / <kbd>k</kbd> | Move down / up |
| <kbd>/</kbd> | Search |
| <kbd>n</kbd> / <kbd>Shift</kbd>+<kbd>N</kbd> | Next / previous search result |
| <kbd>q</kbd> | Quit |

These are less-style pager keys. Git may omit the pager when output fits on one
screen.

Bypass the configured pager for one command:

~~~sh
git --no-pager diff
~~~

Test Delta independently:

~~~sh
delta file-before.txt file-after.txt
diff -u file-before.txt file-after.txt | delta
~~~

### A focused staging loop

~~~sh
git status
git diff
git add -p
git diff --staged
git commit
~~~

The patch mode of <code>git add</code> lets you review and stage individual
hunks while keeping Git itself as the source of truth.

## Lazygit: full repository interface

Run it directly:

~~~sh
lazygit
~~~

Inside tmux, prefix + <kbd>g</kbd> opens Lazygit in a large popup rooted at
the current pane's directory.

Lazygit is best learned through its contextual help:

- Press <kbd>?</kbd> to see keys for the focused panel.
- Use arrow keys or <kbd>h/j/k/l</kbd> to move.
- Press <kbd>Space</kbd> for common selection/staging actions.
- Press <kbd>Enter</kbd> to inspect or open an item.
- Press <kbd>q</kbd> to leave.

Because keys change with the focused panel and Lazygit version, the in-app
<kbd>?</kbd> view is more reliable than memorizing a large static table.

### Suggested first exercise

In a repository with one harmless modified file:

1. Open Lazygit.
2. Focus the files panel.
3. View the diff.
4. Stage the file.
5. Move to staged changes and unstage it.
6. Press <kbd>?</kbd> in two different panels and compare their actions.
7. Quit without committing.

## Worktrees

Git worktrees allow two branches from one repository to be checked out into
different directories. They work particularly well with project sessions:

~~~sh
git worktree add ../project-feature -b feature/example
cd ../project-feature
~~~

Once zoxide has observed the new directory, it also becomes available through
<code>z</code>, <code>zi</code>, and the tmux sessionizer.

Inspect existing worktrees with:

~~~sh
git worktree list
~~~

## Updating many repositories

From a deliberate workspace root:

~~~sh
cd ~/workspace
git-update-all
~~~

CZSH finds Git directories with fd and runs:

~~~sh
git pull --rebase --autostash
~~~

This is fast and convenient, but it applies to every repository below the
current directory. For repositories with sensitive branches or complex local
work, update individually.

## Which interface should I use?

| Task | Good starting point |
| --- | --- |
| Inspect one diff | <code>git diff</code> with Delta |
| Find an old commit | <code>git log --oneline --graph</code> or Lazygit |
| Stage selected changes | <code>git add -p</code> or Lazygit |
| Understand a repository's total state | Lazygit |
| Script or document a reproducible operation | Normal Git commands |
| Work on multiple branches simultaneously | Git worktrees and tmux sessions |

## Practice

1. Compare <code>git diff</code> and Lazygit's diff view.
2. Use <code>git log --oneline --graph</code> to find an older commit.
3. Stage one harmless hunk with <code>git add -p</code>, then unstage it with
   <code>git restore --staged FILE</code>.
4. Open Lazygit from the tmux popup and use contextual help.
