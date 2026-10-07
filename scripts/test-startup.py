#!/usr/bin/env python3

import os
import pty
import select
import signal
import shutil
from pathlib import Path
import subprocess
import tempfile
import time
import unittest


REPO_ROOT = Path(__file__).resolve().parent.parent


class StartupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="czsh-startup-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / "home with spaces"
        self.home.mkdir()
        self.env = {
            "HOME": str(self.home), "ZDOTDIR": str(self.home),
            "PATH": "/usr/bin:/bin", "TERM": "dumb",
            "USER": "czsh-test", "LOGNAME": "czsh-test",
            "CZSH_AUTO_DETECT_TOOLS": "false",
        }
        self.run_shell_script("scripts/prepare-smoke-home.sh", str(self.home))

    def run_shell_script(self, script, *args):
        subprocess.run(["bash", str(REPO_ROOT / script), *args],
                       env=self.env, check=True, capture_output=True, text=True)

    def write(self, name, text, executable=False):
        target = self.home / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text)
        if executable:
            target.chmod(0o755)
        return target

    def shell(self, code):
        result = subprocess.run(["zsh", "-ic", code], env=self.env,
                                cwd=self.home, capture_output=True, text=True,
                                timeout=15)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout.strip()

    @unittest.skipUnless(Path('/etc/zsh/zshrc').is_file() and
                         'skip_global_compinit' in Path('/etc/zsh/zshrc').read_text(),
                         'requires Ubuntu global completion initialization')
    def test_fixture_avoids_global_completion_prompt_for_insecure_directories(self):
        completions = self.home / 'insecure-completions'
        completions.mkdir(mode=0o777)
        completions.chmod(0o777)
        self.write('insecure-completions/_test', '#compdef test-command\n')
        env_file = self.home / '.zshenv'
        original = env_file.read_text() if env_file.exists() else ''
        env_file.write_text(original + 'fpath=("$HOME/insecure-completions" $fpath)\n')
        result = subprocess.run(['zsh', '-ic', 'print ready'], env=self.env,
                                cwd=self.home, capture_output=True, text=True,
                                timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), 'ready')
        self.assertNotIn('compinit', result.stderr)

    def test_validation_checks_bash_helpers_without_ripgrep(self):
        validation = self.home / 'validation'
        self.write('validation/scripts/validate.sh',
                   (REPO_ROOT / 'scripts/validate.sh').read_text())
        (validation / 'features').mkdir()
        for name in ('install.sh', 'utils.sh', 'get-docker.sh'):
            self.write(f'validation/{name}', 'true\n')
        self.write('validation/bin/broken-helper', '#!/usr/bin/env bash\nif\n')
        tools = self.home / 'validation-tools'
        tools.mkdir()
        for name in ('bash', 'dirname', 'find', 'sort', 'grep'):
            (tools / name).symlink_to(shutil.which(name))
        env = dict(self.env, PATH=str(tools))
        result = subprocess.run([str(tools / 'bash'), 'scripts/validate.sh'],
                                env=env, cwd=validation, capture_output=True,
                                text=True, timeout=15)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('syntax error', result.stderr)

    def test_inherited_homebrew_restores_paths_without_running_brew(self):
        prefix = self.home / "brew"
        brew = self.write("brew/bin/brew", "#!/bin/sh\nexit 99\n", True)
        (prefix / "sbin").mkdir()
        (prefix / "share/zsh/site-functions").mkdir(parents=True)
        self.env.update({
            "CZSH_AUTO_DETECT_TOOLS": "true", "BREW_LOCATION": str(brew),
            "HOMEBREW_PREFIX": str(prefix),
            "HOMEBREW_CELLAR": str(prefix / "Cellar"),
            "HOMEBREW_REPOSITORY": str(prefix / "Homebrew"),
        })
        self.assertEqual(self.shell(
            'print -r -- "$PATH"\nprint -rl -- $fpath\n'
        ).count(str(prefix / "sbin")), 1)
        self.assertIn(str(prefix / "share/zsh/site-functions"), self.shell(
            'print -rl -- $fpath'
        ))
        self.assertEqual(self.shell("czsh scan >/dev/null; print $?"), "1")

    def install_generator(self):
        self.env["PATH"] = f"{self.home}/.local/bin:/usr/bin:/bin"
        return self.write(
            ".local/bin/direnv",
            '#!/bin/sh\n[ "$*" = "hook zsh" ] || exit 2\n'
            'echo generated >> "$HOME/generations"\n'
            'printf \'export DIRECTORY_HOOK="ready"\\n\'\n', True,
        )

    def test_directory_hook_is_generated_once_across_shells(self):
        self.install_generator()
        for _ in range(2):
            self.assertEqual(self.shell('print -r -- "$DIRECTORY_HOOK"'), "ready")
        self.assertEqual((self.home / "generations").read_text(), "generated\n")

    def test_directory_hook_refreshes_when_binary_changes(self):
        binary = self.install_generator()
        self.shell("exit")
        binary.write_text(binary.read_text().replace('"ready"', '"updated"'))
        os.utime(binary, (2000000000, 2000000000))
        self.assertEqual(self.shell('print -r -- "$DIRECTORY_HOOK"'), "updated")

    def test_directory_hook_refreshes_with_preserved_package_timestamp(self):
        binary = self.install_generator()
        self.shell("exit")
        binary.write_text(binary.read_text().replace('"ready"', '"updated"'))
        os.utime(binary, (1000000000, 1000000000))
        self.assertEqual(self.shell('print -r -- "$DIRECTORY_HOOK"'), "updated")

    def test_symlinked_personal_override_is_loaded(self):
        target = self.write("personal.zsh", 'export PERSONAL_OVERRIDE=loaded\n')
        (self.home / ".config/czsh/zshrc/linked.zsh").symlink_to(target)
        self.assertEqual(self.shell('print -r -- "$PERSONAL_OVERRIDE"'), "loaded")

    def test_personal_directory_tool_wrapper_is_used(self):
        self.install_generator()
        self.write(".config/czsh/zshrc/tools.zsh",
                   'direnv() { print -r -- \'export DIRECTORY_HOOK="wrapper"\'; }\n')
        self.assertEqual(self.shell('print -r -- "$DIRECTORY_HOOK"'), "wrapper")

    def test_directory_cache_refreshes_when_executable_symlink_changes(self):
        binary = self.install_generator()
        binary.rename(binary.with_name("direnv-old"))
        replacement = self.write(".local/bin/direnv-new",
                                 '#!/bin/sh\necho \'export DIRECTORY_HOOK="new"\'\n', True)
        binary.symlink_to(binary.with_name("direnv-old"))
        self.assertEqual(self.shell('print -r -- "$DIRECTORY_HOOK"'), "ready")
        binary.unlink()
        binary.symlink_to(replacement)
        self.assertEqual(self.shell('print -r -- "$DIRECTORY_HOOK"'), "new")

    def test_atuin_keeps_in_memory_inline_suggestions(self):
        self.env["PATH"] = f"{self.home}/.local/bin:/usr/bin:/bin"
        self.write(".local/bin/atuin", '#!/bin/sh\n'
                   '[ "$*" = "init zsh --disable-up-arrow" ] || exit 2\n'
                   'echo "ZSH_AUTOSUGGEST_STRATEGY=(atuin)"\n', True)
        self.assertEqual(self.shell('print -rl -- $ZSH_AUTOSUGGEST_STRATEGY'), "history")

    def test_prompt_does_not_wait_for_slow_git_in_a_terminal(self):
        self.env["PATH"] = f"{self.home}/.local/bin:/usr/bin:/bin"
        self.write(".local/bin/git", '#!/bin/sh\nsleep 3\n'
                   'printf "# branch.head slow-repo\\n"\n', True)
        started = time.monotonic()
        pid, master = pty.fork()
        if pid == 0:
            os.chdir(self.home)
            os.execvpe("zsh", ["zsh", "-i"], self.env)
        output = b""
        try:
            os.write(master, b"unsetopt checkjobs; print REA$'DY:'; exit\n")
            deadline = started + 10
            while b"READY:" not in output and time.monotonic() < deadline:
                if select.select([master], [], [], 0.1)[0]:
                    output += os.read(master, 65536)
            self.assertIn(b"READY:", output)
            self.assertLess(time.monotonic() - started, 2)
        finally:
            try:
                os.kill(pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            os.waitpid(pid, 0)
            os.close(master)

    def test_cancel_stops_git_descendants(self):
        self.env["PATH"] = f"{self.home}/.local/bin:/usr/bin:/bin"
        self.write(".local/bin/git", '#!/bin/sh\necho $$ > "$HOME/git-pid"\nsleep 30\n', True)
        master, slave = pty.openpty()
        self.addCleanup(os.close, master)
        self.addCleanup(os.close, slave)
        result = subprocess.run(
            ["zsh", "-ic", 'setopt monitor; _czsh_git_request; '
             'while [[ ! -s "$HOME/git-pid" ]]; do sleep 0.01; done; '
             '_czsh_git_cancel; sleep 0.1; '
             'command ps -o stat= -p "$(<"$HOME/git-pid")"; exit 0'], env=self.env, cwd=self.home,
            stdin=slave, capture_output=True, text=True, timeout=10,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(not result.stdout.strip() or result.stdout.strip().startswith("Z"), result.stdout)
        pid = int((self.home / "git-pid").read_text())
        try:
            state = subprocess.run(["ps", "-o", "stat=", "-p", str(pid)],
                                   capture_output=True, text=True).stdout.strip()
            self.assertTrue(not state or state.startswith("Z"), state)
        finally:
            try:
                os.kill(pid, signal.SIGKILL)
            except ProcessLookupError:
                pass

    def test_async_git_result_repaints_prompt_and_preserves_exit_status(self):
        self.env["PATH"] = f"{self.home}/.local/bin:/usr/bin:/bin"
        self.write(".local/bin/git", '#!/bin/sh\nsleep 0.2\n'
                   'printf "# branch.head async-repo\\n"\n', True)
        pid, master = pty.fork()
        if pid == 0:
            os.chdir(self.home)
            os.execvpe("zsh", ["zsh", "-i"], self.env)
        output = b""

        def read_until(marker):
            nonlocal output
            deadline = time.monotonic() + 10
            while time.monotonic() < deadline:
                if select.select([master], [], [], 0.1)[0]:
                    output += os.read(master, 65536)
                    if marker in output:
                        return
            self.fail(f"Missing {marker!r} in terminal output: {output!r}")

        try:
            read_until(b"async-repo")
            output = b""
            os.write(master, b"(exit 7)\n")
            os.write(master, b'print -r -- "RESULT:${RPROMPT}"\n')
            read_until(b"RESULT:%F{")
            self.assertIn("✘ 7".encode(), output)
        finally:
            os.kill(pid, signal.SIGKILL)
            os.waitpid(pid, 0)
            os.close(master)

    def test_failed_generation_is_retried_without_partial_cache(self):
        self.install_generator()
        self.write(".local/bin/direnv", '#!/bin/sh\necho "export BAD_HOOK=1"\nexit 1\n', True)
        self.assertEqual(self.shell('print -r -- "${BAD_HOOK:-clean}"'), "clean")
        self.install_generator()
        self.assertEqual(self.shell('print -r -- "$DIRECTORY_HOOK"'), "ready")

    def test_unwritable_cache_keeps_directory_hook_available(self):
        self.install_generator()
        self.write("cache-file", "")
        self.env["XDG_CACHE_HOME"] = str(self.home / "cache-file")
        self.assertEqual(self.shell('print -r -- "$DIRECTORY_HOOK"'), "ready")


if __name__ == "__main__":
    unittest.main()
