#!/usr/bin/env python3

from pathlib import Path
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parent.parent


class ToolEnvironmentTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="czsh-tools-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / "home with spaces"
        self.home.mkdir()
        self.env = {
            "HOME": str(self.home),
            "ZDOTDIR": str(self.home),
            "PATH": "/usr/bin:/bin",
            "TERM": "dumb",
            "USER": "czsh-test",
            "LOGNAME": "czsh-test",
            "TMPDIR": self.temp.name,
            "NO_COLOR": "1",
        }
        self.env["BREW_LOCATION"] = str(self.write(
            "test brew/bin/brew",
            '#!/bin/sh\n[ "$*" = shellenv ] || exit 2\n'
            'printf \'export HOMEBREW_PREFIX="%s/test brew"\\n\' "$HOME"\n',
            True,
        ))

    def run_command(self, args):
        result = subprocess.run(
            args, env=self.env, cwd=self.home, text=True,
            capture_output=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout.strip()

    def prepare_runtime(self):
        self.run_command([
            "bash", str(REPO_ROOT / "scripts/prepare-smoke-home.sh"),
            str(self.home),
        ])

    def write(self, name, contents, executable=False):
        target = self.home / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(contents)
        if executable:
            target.chmod(0o755)
        return target

    def install_base(self):
        self.run_command([
            "bash", "-c",
            'SCRIPT_DIR="$1"\n'
            'source "$SCRIPT_DIR/utils.sh"\n'
            'source "$SCRIPT_DIR/features/lib/common.sh"\n'
            'configure_install_paths\n'
            'backup_existing_zshrc_config\n'
            'copy_base_configuration_files\n',
            "test-installer", str(REPO_ROOT),
        ])

    def test_upgrade_preserves_installer_additions_and_loader_symlink(self):
        self.prepare_runtime()
        zshrc = self.home / ".zshrc"
        contents = zshrc.read_text() + '\nexport THIRD_PARTY_SETTING="keep me"\n'
        target = self.write("dotfiles/zshrc", contents)
        zshrc.unlink()
        zshrc.symlink_to(target)

        self.install_base()
        self.install_base()

        self.assertTrue(zshrc.is_symlink())
        self.assertEqual(zshrc.read_text(), contents)
        self.assertFalse(list(self.home.glob(".zshrc-backup-*")))
        self.assertEqual(self.run_command([
            "zsh", "-ic", 'print -r -- "$THIRD_PARTY_SETTING"',
        ]), "keep me")

    def test_first_install_backs_up_unmanaged_configuration(self):
        contents = 'export ORIGINAL_SETTING="original"\n'
        self.write(".zshrc", contents)

        self.install_base()

        backups = list(self.home.glob(".zshrc-backup-*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), contents)

    def test_new_shell_initializes_nvm_without_manual_zshrc_settings(self):
        self.prepare_runtime()
        self.write(
            ".nvm/nvm.sh",
            'export NVM_DIR="$HOME/.nvm"\n'
            'path=("$NVM_DIR/versions/node/test/bin" $path)\n'
            'nvm() { return 0; }\n',
        )
        node = self.write(
            ".nvm/versions/node/test/bin/node",
            "#!/bin/sh\nprintf 'detected-node\\n'\n", executable=True,
        )

        self.assertEqual(self.run_command([
            "zsh", "-ic", "whence -p node",
        ]), str(node))

    def test_nvm_in_xdg_config_home_is_detected(self):
        self.prepare_runtime()
        self.env["XDG_CONFIG_HOME"] = str(self.home / "xdg config")
        self.write(
            "xdg config/nvm/nvm.sh",
            'path=("$NVM_DIR/versions/node/test/bin" $path)\n'
            'nvm() { return 0; }\n',
        )
        node = self.write(
            "xdg config/nvm/versions/node/test/bin/node", "#!/bin/sh\nexit 0\n", True,
        )
        self.assertEqual(self.run_command([
            "zsh", "-ic", "whence -p node",
        ]), str(node))

    def inherit_nvm(self):
        self.prepare_runtime()
        self.env["NVM_DIR"] = str(self.home / ".nvm")
        self.env["NVM_BIN"] = str(self.home / ".nvm/versions/node/test/bin")
        self.env["PATH"] = self.env["NVM_BIN"] + ":/usr/bin:/bin"
        self.write(
            ".nvm/nvm.sh",
            '(( NVM_LOAD_COUNT += 1 ))\n'
            'print -r -- "$*" >> "$HOME/nvm-loads"\n'
            'nvm() { print -r -- "nvm:$#:$*"; return 7; }\n',
        )
        self.write(
            ".nvm/versions/node/test/bin/npm",
            '#!/bin/sh\n[ "$*" = "config get prefix" ] || exit 2\n'
            'printf "%s/.nvm/versions/node/test\\n" "$HOME"\n', True,
        )
        return self.write(
            ".nvm/versions/node/test/bin/node",
            "#!/bin/sh\nprintf 'inherited-node\\n'\n", True,
        )

    def test_inherited_node_is_available_without_loading_nvm(self):
        node = self.inherit_nvm()
        self.assertEqual(self.run_command([
            "zsh", "-ic", 'whence -p node; node',
        ]), str(node) + "\ninherited-node")
        self.assertFalse((self.home / "nvm-loads").exists())

    def test_fresh_shell_selects_latest_matching_default_without_loading_nvm(self):
        self.inherit_nvm()
        del self.env["NVM_BIN"]
        self.env["PATH"] = "/usr/bin:/bin"
        self.write(".nvm/alias/default", "22\n")
        for version in ("v2.9.0", "v22.9.0", "v22.19.0", "v22.20.0", "v24.1.0"):
            self.write(
                f".nvm/versions/node/{version}/bin/node",
                f"#!/bin/sh\nprintf '{version}\\n'\n", True,
            )
        self.install_base()
        self.assertEqual(self.run_command([
            "zsh", "-ic", 'node; print -rl -- "$NVM_BIN" "$NVM_INC"',
        ]), f"v22.20.0\n{self.home}/.nvm/versions/node/v22.20.0/bin\n"
            f"{self.home}/.nvm/versions/node/v22.20.0/include/node")
        self.assertFalse((self.home / "nvm-loads").exists())

    def test_fresh_shell_resolves_nvm_default_alias_chains(self):
        for default in ("work", "lts/*", "node", "v22.10.0", "22.10", "2"):
            with self.subTest(default=default):
                self.inherit_nvm()
                del self.env["NVM_BIN"]
                self.env["PATH"] = "/usr/bin:/bin"
                self.write(".nvm/alias/default", default + "\n")
                self.write(".nvm/alias/work", "lts/*\n")
                self.write(".nvm/alias/lts/*", "lts/jod\n")
                self.write(".nvm/alias/lts/jod", "v22.10.0\n")
                for version in ("v2.9.0", "v22.9.0", "v22.10.0"):
                    self.write(
                        f".nvm/versions/node/{version}/bin/node",
                        f"#!/bin/sh\nprintf '{version}\\n'\n", True,
                    )
                wanted = "v2.9.0" if default == "2" else "v22.10.0"
                self.assertEqual(self.run_command(["zsh", "-ic", "node"]), wanted)
                self.assertFalse((self.home / "nvm-loads").exists())

    def test_unresolved_nvm_default_falls_back_to_normal_initialization(self):
        for aliases in ({"default": "missing"}, {"default": "loop", "loop": "default"}):
            with self.subTest(aliases=aliases):
                self.inherit_nvm()
                del self.env["NVM_BIN"]
                self.env["PATH"] = "/usr/bin:/bin"
                for name, value in aliases.items():
                    self.write(f".nvm/alias/{name}", value + "\n")
                self.run_command(["zsh", "-ic", "exit 0"])
                self.assertEqual((self.home / "nvm-loads").read_text(), "\n")
                (self.home / "nvm-loads").unlink()

    def test_deferred_nvm_loads_once_and_preserves_arguments_and_status(self):
        self.inherit_nvm()
        self.assertEqual(self.run_command([
            "zsh", "-ic",
            'nvm use "version with spaces"; print -r -- $?\n'
            'nvm current; print -r -- "$?:$NVM_LOAD_COUNT"',
        ]), "nvm:2:use version with spaces\n7\nnvm:1:current\n7:1")
        self.assertEqual((self.home / "nvm-loads").read_text(), "--no-use\n")

    def test_scan_initializes_deferred_nvm_and_repairs_node_path(self):
        node = self.inherit_nvm()
        self.assertEqual(self.run_command([
            "zsh", "-ic",
            'path=(/usr/bin /bin)\n'
            'czsh scan >/dev/null && czsh scan >/dev/null || exit\n'
            'print -r -- "$NVM_LOAD_COUNT"; whence -p node',
        ]), "1\n" + str(node))

    def test_stale_inherited_node_environment_initializes_nvm(self):
        self.inherit_nvm()
        self.env["NVM_BIN"] = str(self.home / ".nvm/versions/node/missing/bin")
        self.env["PATH"] = self.env["NVM_BIN"] + ":/usr/bin:/bin"
        self.run_command(["zsh", "-ic", "exit 0"])
        self.assertEqual((self.home / "nvm-loads").read_text(), "\n")

    def test_deferred_nvm_reports_initialization_failure(self):
        self.inherit_nvm()
        self.write(".nvm/nvm.sh", "return 9\n")
        self.assertEqual(self.run_command([
            "zsh", "-ic", 'nvm current; print -r -- $? ',
        ]), "9")

    def test_scan_repairs_current_shell_without_loading_nvm_twice(self):
        self.prepare_runtime()
        self.write(
            ".nvm/nvm.sh",
            '(( NVM_LOAD_COUNT += 1 ))\n'
            'export NVM_BIN="$HOME/.nvm/versions/node/test/bin"\n'
            'path=("$NVM_BIN" $path)\n'
            'nvm() { return 0; }\n',
        )
        node = self.write(
            ".nvm/versions/node/test/bin/node", "#!/bin/sh\nexit 0\n", True,
        )
        self.write(
            ".nvm/versions/node/test/bin/npm",
            '#!/bin/sh\n[ "$*" = "config get prefix" ] || exit 2\n'
            'printf "%s/.nvm/versions/node/test\\n" "$HOME"\n', True,
        )
        self.assertEqual(self.run_command([
            "zsh", "-ic",
            'path=(/usr/bin /bin)\n'
            'czsh scan >/dev/null && czsh scan >/dev/null || exit\n'
            'print -r -- "$NVM_LOAD_COUNT"\n'
            'whence -p node\n',
        ]), "1\n" + str(node))

    def test_homebrew_is_found_outside_path(self):
        self.prepare_runtime()
        del self.env["BREW_LOCATION"]
        self.write(
            ".linuxbrew/bin/brew",
            '#!/bin/sh\n[ "$*" = shellenv ] || exit 2\n'
            'printf \'export HOMEBREW_PREFIX="%s/.linuxbrew"\\n\' "$HOME"\n'
            'printf \'export PATH="%s/.linuxbrew/bin:$PATH"\\n\' "$HOME"\n',
            True,
        )
        self.assertEqual(self.run_command([
            "zsh", "-ic", 'print -r -- "$HOMEBREW_PREFIX"; whence -p brew',
        ]), f"{self.home}/.linuxbrew\n{self.home}/.linuxbrew/bin/brew")

    def test_custom_homebrew_location_in_personal_config(self):
        self.prepare_runtime()
        brew = self.write(
            "custom brew/bin/brew",
            '#!/bin/sh\n[ "$*" = shellenv ] || exit 2\n'
            'printf \'export HOMEBREW_PREFIX="%s/custom brew"\\n\' "$HOME"\n'
            'printf \'export PATH="%s/custom brew/bin:$PATH"\\n\' "$HOME"\n',
            True,
        )
        self.write(
            ".config/czsh/zshrc/local.zsh",
            'export BREW_LOCATION="$HOME/custom brew/bin/brew"\n',
        )
        self.assertEqual(self.run_command([
            "zsh", "-ic", "whence -p brew",
        ]), str(brew))

    def test_npmrc_prefix_restores_global_binaries_without_running_npm(self):
        self.prepare_runtime()
        self.write(".npmrc", 'prefix=${HOME}/npm tools\n')
        tool = self.write("npm tools/bin/global-tool", "#!/bin/sh\nexit 0\n", True)
        self.write(
            ".local/bin/npm",
            '#!/bin/sh\nprintf called > "$HOME/npm-was-run"\nexit 1\n',
            True,
        )
        self.assertEqual(self.run_command([
            "zsh", "-ic", "whence -p global-tool",
        ]), str(tool))
        self.assertFalse((self.home / "npm-was-run").exists())

    def test_scan_caches_npm_global_prefix_for_new_shells(self):
        self.prepare_runtime()
        self.write(
            ".local/bin/npm",
            '#!/bin/sh\n[ "$*" = "config get prefix" ] || exit 2\n'
            'printf "%s/npm custom\\n" "$HOME"\n', True,
        )
        tool = self.write("npm custom/bin/global-tool", "#!/bin/sh\nexit 0\n", True)
        self.assertEqual(self.run_command([
            "zsh", "-ic", 'czsh scan >/dev/null && whence -p global-tool',
        ]), str(tool))
        self.assertEqual(self.run_command([
            "zsh", "-ic", "whence -p global-tool",
        ]), str(tool))

    def test_scan_cache_handles_npmrc_formats_not_parsed_at_startup(self):
        self.prepare_runtime()
        self.write(".npmrc", 'prefix=${CUSTOM_NPM_HOME}/tools\n')
        self.write(
            ".local/bin/npm",
            '#!/bin/sh\n[ "$*" = "config get prefix" ] || exit 2\n'
            'printf "%s/npm expanded\\n" "$HOME"\n', True,
        )
        tool = self.write("npm expanded/bin/global-tool", "#!/bin/sh\nexit 0\n", True)
        self.run_command(["zsh", "-ic", "czsh scan"])
        self.assertEqual(self.run_command([
            "zsh", "-ic", "whence -p global-tool",
        ]), str(tool))

    def test_scan_cache_handles_npmrc_inline_comments_and_escapes(self):
        self.prepare_runtime()
        self.write(
            ".local/bin/npm",
            '#!/bin/sh\n[ "$*" = "config get prefix" ] || exit 2\n'
            'printf "%s/npm parsed\\n" "$HOME"\n', True,
        )
        tool = self.write("npm parsed/bin/global-tool", "#!/bin/sh\nexit 0\n", True)
        for prefix in (
            '${HOME}/npm parsed ; custom globals',
            '${HOME}/npm\\#parsed',
        ):
            with self.subTest(prefix=prefix):
                self.write(".npmrc", f"prefix={prefix}\n")
                self.run_command(["zsh", "-ic", "czsh scan"])
                self.assertEqual(self.run_command([
                    "zsh", "-ic", "whence -p global-tool",
                ]), str(tool))

    def test_common_user_tool_directories_are_detected(self):
        self.prepare_runtime()
        for directory, tool in (
            (".local/share/pnpm", "pnpm"),
            (".cargo/bin", "cargo"),
            (".bun/bin", "bun"),
        ):
            target = self.write(f"{directory}/{tool}", "#!/bin/sh\nexit 0\n", True)
            self.assertEqual(self.run_command([
                "zsh", "-ic", f"whence -p {tool}",
            ]), str(target))

    def install_fnm(self):
        fnm = self.write(
            ".local/share/fnm/fnm",
            '#!/bin/sh\n[ "$*" = "env --use-on-cd --shell zsh" ] || exit 2\n'
            'printf called\\n >> "$HOME/fnm-env-calls"\n'
            'printf \'export FNM_MULTISHELL_PATH="%s/fnm active"\\n\' "$HOME"\n'
            'printf \'export PATH="%s/fnm active/bin:$PATH"\\n\' "$HOME"\n'
            'printf \'_fnm_autoload_hook() { return 0; }\\n\'\n'
            'printf \'autoload -U add-zsh-hook\\nadd-zsh-hook chpwd _fnm_autoload_hook\\n\'\n',
            True,
        )
        node = self.write("fnm active/bin/node", "#!/bin/sh\nexit 0\n", True)
        self.write(
            "fnm active/bin/npm",
            '#!/bin/sh\n[ "$*" = "config get prefix" ] || exit 2\n'
            'printf "%s/fnm active\\n" "$HOME"\n', True,
        )
        return fnm, node

    def test_fnm_environment_is_initialized_once(self):
        self.prepare_runtime()
        _, node = self.install_fnm()
        self.assertEqual(self.run_command([
            "zsh", "-ic", 'czsh scan >/dev/null && czsh scan >/dev/null && whence -p node',
        ]), str(node))
        self.assertEqual((self.home / "fnm-env-calls").read_text().count("called"), 1)

    def test_scan_restores_fnm_binary_and_node_after_path_changes(self):
        self.prepare_runtime()
        fnm, node = self.install_fnm()
        self.assertEqual(self.run_command([
            "zsh", "-ic",
            'path=(/usr/bin /bin)\nczsh scan >/dev/null || exit\n'
            'whence -p fnm\nwhence -p node\n',
        ]), f"{fnm}\n{node}")

    def test_child_shell_initializes_fnm_hooks_despite_inherited_environment(self):
        self.prepare_runtime()
        self.install_fnm()
        self.env["FNM_MULTISHELL_PATH"] = str(self.home / "fnm active")
        self.assertEqual(self.run_command([
            "zsh", "-ic",
            '(( $+functions[_fnm_autoload_hook] )) && print ready || print missing',
        ]), "ready")

    def test_scan_restores_homebrew_sbin(self):
        self.prepare_runtime()
        self.env["BREW_LOCATION"] = str(self.write(
            ".linuxbrew/bin/brew",
            '#!/bin/sh\n[ "$*" = shellenv ] || exit 2\n'
            'printf \'export HOMEBREW_PREFIX="%s/.linuxbrew"\\n\' "$HOME"\n'
            'printf \'export PATH="%s/.linuxbrew/bin:%s/.linuxbrew/sbin:$PATH"\\n\' "$HOME" "$HOME"\n',
            True,
        ))
        tool = self.write(".linuxbrew/sbin/brew-sbin-tool", "#!/bin/sh\nexit 0\n", True)
        self.assertEqual(self.run_command([
            "zsh", "-ic",
            'path=("$HOME/.linuxbrew/bin" /usr/bin /bin)\n'
            'czsh scan >/dev/null && whence -p brew-sbin-tool',
        ]), str(tool))

    def test_volta_takes_precedence_over_inactive_nvm(self):
        self.prepare_runtime()
        self.write(".volta/bin/volta", "#!/bin/sh\nexit 0\n", True)
        node = self.write(".volta/bin/node", "#!/bin/sh\nexit 0\n", True)
        self.write(".nvm/nvm.sh", 'print bad-nvm-activation > "$HOME/nvm-was-run"\n')
        self.assertEqual(self.run_command([
            "zsh", "-ic", "whence -p node",
        ]), str(node))
        self.assertFalse((self.home / "nvm-was-run").exists())

    def test_standalone_scan_reports_detected_tools(self):
        self.prepare_runtime()
        self.write(".bun/bin/bun", "#!/bin/sh\nexit 0\n", True)
        output = self.run_command(["bash", str(REPO_ROOT / "bin/czsh"), "scan"])
        self.assertIn(str(self.home / ".bun/bin"), output)
        self.assertEqual((self.home / ".zshrc").read_text(), (REPO_ROOT / ".zshrc").read_text())

    def test_standalone_scan_finds_npm_in_user_bin(self):
        self.prepare_runtime()
        self.write(
            ".local/bin/npm",
            '#!/bin/sh\n[ "$*" = "config get prefix" ] || exit 2\n'
            'printf "%s/npm standalone\\n" "$HOME"\n', True,
        )
        tool = self.write("npm standalone/bin/global-tool", "#!/bin/sh\nexit 0\n", True)
        self.run_command(["bash", str(REPO_ROOT / "bin/czsh"), "scan"])
        self.assertEqual(self.run_command([
            "zsh", "-ic", "whence -p global-tool",
        ]), str(tool))

    def test_scan_reports_initialization_errors(self):
        self.prepare_runtime()
        self.env["BREW_LOCATION"] = str(self.write(
            "broken brew/bin/brew", "#!/bin/sh\nexit 1\n", True,
        ))
        result = subprocess.run(
            ["zsh", "-ic", "czsh scan"], env=self.env, cwd=self.home,
            text=True, capture_output=True, timeout=30,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Homebrew initialization failed", result.stderr)

    def test_npmrc_whitespace_quotes_and_last_prefix_wins(self):
        self.prepare_runtime()
        self.write(".npmrc", 'prefix=/unused\n  prefix = "${HOME}/npm tools"  \n')
        tool = self.write("npm tools/bin/global-tool", "#!/bin/sh\nexit 0\n", True)
        self.assertEqual(self.run_command([
            "zsh", "-ic", "whence -p global-tool",
        ]), str(tool))

    def test_npmrc_is_never_evaluated_as_shell_code(self):
        self.prepare_runtime()
        self.write(".npmrc", 'prefix=$(touch "$HOME/should-not-exist")\n')
        self.run_command(["zsh", "-ic", "exit 0"])
        self.assertFalse((self.home / "should-not-exist").exists())

    def test_explicit_tool_homes_and_npm_prefix(self):
        self.prepare_runtime()
        for variable, directory in (
            ("CARGO_HOME", "rust tools"), ("BUN_INSTALL", "bun tools"),
            ("PNPM_HOME", "pnpm tools"), ("NPM_CONFIG_PREFIX", "npm tools"),
        ):
            self.env[variable] = str(self.home / directory)
        for directory, tool in (
            ("rust tools/bin", "cargo"), ("bun tools/bin", "bun"),
            ("pnpm tools", "pnpm"), ("npm tools/bin", "global-tool"),
        ):
            target = self.write(f"{directory}/{tool}", "#!/bin/sh\nexit 0\n", True)
            self.assertEqual(self.run_command([
                "zsh", "-ic", f"whence -p {tool}",
            ]), str(target))

    def test_nonabsolute_npm_environment_prefix_is_repaired(self):
        self.prepare_runtime()
        self.write(
            ".local/bin/npm",
            '#!/bin/sh\n[ "$*" = "config get prefix" ] || exit 2\n'
            'printf "%s/npm tools\\n" "$HOME"\n', True,
        )
        tool = self.write("npm tools/bin/global-tool", "#!/bin/sh\nexit 0\n", True)
        for prefix in ("~/npm tools", "npm tools"):
            with self.subTest(prefix=prefix):
                self.env["NPM_CONFIG_PREFIX"] = prefix
                self.run_command(["zsh", "-ic", "czsh scan"])
                self.assertEqual(self.run_command([
                    "zsh", "-ic", "whence -p global-tool",
                ]), str(tool))

    def test_auto_detection_can_be_disabled(self):
        self.prepare_runtime()
        self.env["CZSH_AUTO_DETECT_TOOLS"] = "false"
        self.write(".bun/bin/bun", "#!/bin/sh\nexit 0\n", True)
        self.assertEqual(self.run_command([
            "zsh", "-ic", '(( $+commands[bun] )) && print detected || print disabled',
        ]), "disabled")

    def test_help_and_unknown_scan_arguments_have_no_side_effects(self):
        self.prepare_runtime()
        self.assertEqual(self.run_command([
            "zsh", "-ic", "czsh scan --help",
        ]), "Usage: czsh scan")
        result = subprocess.run(
            ["zsh", "-ic", "czsh scan --unknown"], env=self.env,
            cwd=self.home, text=True, capture_output=True, timeout=30,
        )
        self.assertEqual(result.returncode, 2)
        self.assertFalse((self.home / ".config/czsh/state/npm-prefix").exists())


if __name__ == "__main__":
    unittest.main()
