# Contributing to CZSH

Thanks for improving CZSH. Changes should keep the project reproducible on both
macOS and Linux and should preserve existing user configuration whenever
possible.

## Development setup

1. Fork and clone the repository.
2. Create a focused branch from `main`.
3. Install the validation tools available for your platform: Bash, Zsh, tmux,
   and ShellCheck.
4. Run the local validation suite before submitting a pull request:

   ```bash
   ./scripts/validate.sh
   ```

Do not run the installer against your primary home directory while developing
destructive installer changes. Use a disposable user account, container, or
virtual machine.

## Project structure

- `features/install/` contains installation and update steps.
- `features/runtime/` is loaded before Oh My Zsh.
- `features/post/` is loaded after Oh My Zsh.
- `features/lib/` contains shared installer functions.
- `dotfiles/` contains managed application configuration.
- `bin/` contains helper commands installed into `~/.config/czsh/bin`.

Keep platform detection in `features/lib/platform.sh` and avoid duplicating
package-manager or architecture logic in individual features.

## Change guidelines

- Keep installation features idempotent unless the behavior is explicitly
  documented as opt-in and additive.
- Preserve existing files by backing them up before replacement.
- Quote paths and variables that may contain whitespace.
- Avoid adding commands to prompt or tmux refresh paths unless they are cached
  or asynchronous.
- Update the README whenever user-visible behavior changes.
- Add an entry under `[Unreleased]` in [CHANGELOG.md](CHANGELOG.md) for any
  user-visible change.
- Never include credentials, tokens, machine-specific paths, or personal data.

## Commits and pull requests

Use short, imperative commit subjects with a conventional prefix where useful,
for example `feat(tmux): add pane synchronization indicator` or
`fix(installer): preserve existing XDG configuration`.

Pull requests should explain the motivation, list relevant platforms, describe
validation performed, and include screenshots for visible terminal changes.
