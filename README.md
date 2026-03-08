# CZsh - Complete Zsh Configuration

A comprehensive Zsh setup with a modular installer and runtime feature system. Install-time modules live under the repository's features directory, and runtime modules are installed into ~/.config/czsh/features so new functionality can be added as isolated feature scripts.

## 🚀 Features

- **Oh My Zsh** with modular configuration loading
- **Powerlevel10k** theme with beautiful prompts
- **Advanced plugins** for enhanced productivity
- **FZF integration** for fuzzy finding
- **AI-powered command completion** with zsh_codex
- **Gemini CLI integration** for AI assistance
- **Modern tools** like lazydocker, bat, and more
- **Nerd Fonts** for beautiful icons
- **Smart aliases** and custom functions
- **Platform-aware installs** for macOS and Linux

## Architecture

The project is organized around feature scripts:

- features/install/*.sh: install-time modules sourced by install.sh in filename order.
- features/runtime/*.zsh: shell configuration sourced before Oh My Zsh during shell startup.
- features/post/*.zsh: shell configuration sourced after Oh My Zsh for features that depend on plugin initialization.
- features/lib/*.sh: shared helpers for platform detection, path setup, and installer utilities.

This keeps install behavior, runtime behavior, and platform-specific branching separate.

## 📦 What's Included

### Core Components
- **Oh My Zsh**: Feature-rich framework for Zsh
- **Powerlevel10k**: Fast and customizable theme
- **FZF**: Command-line fuzzy finder
- **Lazydocker**: Terminal UI for Docker management

### Plugins
- `zsh-completions` - Additional completion definitions
- `zsh-autosuggestions` - Fish-like autosuggestions
- `zsh-syntax-highlighting` - Syntax highlighting for commands
- `history-substring-search` - Better history search
- `fzf-tab` - Replace tab completion with FZF
- `forgit` - Interactive git commands using FZF
- `zsh_codex` - AI-powered command completion (optional)

### Tools & Utilities
- **bat** - Better cat with syntax highlighting
- **Gemini CLI** - AI-powered coding assistant and workflow tool
- **Nerd Fonts** - Beautiful icon fonts
- **Custom aliases** and functions
- **Enhanced history** configuration

## 🛠️ Prerequisites

The installer will check for these packages and install them if missing:
- `zsh` - The Z shell
- `git` - Version control
- `wget` - File downloader
- `bat` - Better cat command
- `curl` - URL transfer tool
- `python3-pip` - Python package manager
- `fontconfig` - Font configuration

**Node.js** is automatically installed via nvm (Node Version Manager) if not present, ensuring you have the latest stable version for Gemini CLI.

## 📥 Installation

### Quick Install
```bash
git clone https://github.com/yourusername/czsh.git
cd czsh
chmod +x install.sh
./install.sh
```

### Installation Options

The installer supports several flags for customization:

```bash
# Basic installation
./install.sh

# Copy existing bash/zsh history
./install.sh --cp-hist

# Interactive mode (asks questions during install)
./install.sh --interactive

# Include AI-powered command completion
./install.sh --codex

# Include Gemini CLI for AI assistance
./install.sh --gemini

# Include Claude CLI for AI assistance
./install.sh --claude

# Enable vim mode for command line editing
./install.sh --vim-mode

# Combine multiple options
./install.sh --cp-hist --codex --gemini --vim-mode
```

#### Flag Details
- `--cp-hist` or `-c`: Copies your existing shell history to the new Zsh configuration
- `--interactive` or `-n`: Runs in interactive mode, asking for user input during installation
- `--codex` or `-x`: Installs and configures zsh_codex for AI-powered command completion
- `--gemini` or `-g`: Installs and configures Gemini CLI for AI-powered coding assistance
- `--claude` or `-cl`: Installs and configures Claude CLI for AI-powered development assistance
- `--vim-mode` or `-v`: Enables vim keybindings and navigation in the command line

## ⚙️ Configuration

### Runtime Feature Loading

During installation, the runtime feature scripts are copied into:

- ~/.config/czsh/features/runtime
- ~/.config/czsh/features/post

At shell startup:

1. ~/.config/czsh/czshrc.zsh sources all runtime features.
2. ~/.config/czsh/zshrc/* user overrides are sourced.
3. Oh My Zsh is loaded.
4. Post-runtime features are sourced.

To add a new runtime capability, add a new .zsh feature file under features/runtime or features/post and re-run the installer.

To add a new installer capability, add a new script under features/install and register it with register_install_feature.

### AI Command Completion (Optional)

If you use the `--codex` flag, you'll need to provide an API key for AI-powered command completion. The configuration supports:

- **Groq API** (default): Fast and free inference
- **OpenAI API**: Official OpenAI models

Configuration files:
- `~/.config/zsh_codex.ini` - Main configuration
- `~/.config/openaiapirc` - Alternative OpenAI configuration

### Gemini CLI Integration

The setup includes Google's Gemini CLI for AI-powered coding assistance when using the `--gemini` flag:

#### Setup
1. Install with Gemini CLI: `./install.sh --gemini`
2. During installation, choose your authentication method:
   - **API Key**: Enter your key from https://aistudio.google.com/apikey
   - **OAuth**: Authenticate later with `gemini auth`
   - **Skip**: Configure manually later

#### Built-in Aliases & Functions
```bash
# Quick access
g                    # Start Gemini CLI
gai                  # Alternative alias for Gemini

# Specialized functions
gask "your question" # Ask Gemini a quick question
greview             # Review git changes with AI
gcommit             # Generate commit messages
gexplain "error"    # Explain error messages
gdoc filename       # Generate documentation
ganalyze            # Analyze project structure
```

#### Usage Examples
```bash
# Get code help
gask "How to implement a binary search in Python?"

# Review your changes
git add .
greview

# Generate a commit message
git add .
gcommit

# Explain an error
gexplain "segmentation fault core dumped"

# Document your code
gdoc src/main.py

# Analyze project
ganalyze ./my-project
```

### Vim Mode (Optional)

When using the `--vim-mode` flag, the shell enables vim-style command line editing with enhanced features:

#### Features
- **Modal editing**: Switch between insert and normal modes with ESC
- **Vi navigation**: Use `h`, `j`, `k`, `l` for cursor movement in normal mode  
- **Visual cursor indicators**: Cursor shape changes to indicate current mode
  - Beam cursor (|) for insert mode
  - Block cursor (█) for normal mode
- **Enhanced history navigation**: Use `j`/`k` in normal mode for history search
- **Preserved shortcuts**: Common shortcuts like Ctrl+R, Ctrl+A, Ctrl+E still work
- **Fast mode switching**: Reduced timeout for quicker ESC response

#### Key Bindings
```bash
# Mode switching
ESC              # Enter normal mode
i, a, I, A       # Enter insert mode (standard vi keys)

# Navigation (normal mode)
h, j, k, l       # Move cursor left, down, up, right
w, b             # Move by words
0, $             # Beginning/end of line

# History (normal mode)  
j, k             # Navigate through command history
/                # Search history

# Editing (normal mode)
x                # Delete character
dd               # Delete line
yy               # Yank (copy) line
p                # Paste

# Always available
Ctrl+R           # Reverse history search
Ctrl+A           # Beginning of line
Ctrl+E           # End of line
Ctrl+U           # Clear line
```

#### Usage Tips
- Press ESC to enter normal mode for vi-style navigation
- Use Ctrl+R for fuzzy history search (works in both modes)
- The cursor shape will help you identify which mode you're in
- All standard zsh features still work alongside vim mode

### Theme Customization

The Powerlevel10k theme is pre-configured with:
- Left prompt: context, directory, git status
- Right prompt: status, execution time, background jobs, RAM, load
- Nerd font icons for beautiful display
- Optimized colors and layout

### Custom Aliases & Functions

The configuration includes useful aliases:
```bash
# System
alias l="ls --hyperlink=auto -lAhrtF"  # Enhanced ls
alias e="exit"                         # Quick exit
alias myip="wget -qO- https://wtfismyip.com/text"  # Show external IP

# AI Assistance
alias g="gemini"                       # Quick Gemini CLI access
alias gai="gemini"                     # Alternative Gemini alias

# Git
alias git-update-all='find . -type d -name .git -execdir git pull --rebase --autostash \;'

# Process management
alias kp='ps -ef | fzf --multi | awk '\''{print $2}'\'' | xargs sudo kill -9'
```

Custom functions:
- `cheat()` - Access cheat.sh for command help
- `speedtest()` - Run internet speed test
- `s()` - Search files with ripgrep and FZF
- `f()` - Find and preview files with FZF
- `gask()` - Ask Gemini AI quick questions
- `greview()` - AI-powered git diff review
- `gcommit()` - Generate commit messages with AI
- `gexplain()` - Explain error messages
- `gdoc()` - Generate code documentation
- `ganalyze()` - Analyze project structure

## 🎨 Font Setup

The installer automatically downloads and installs Nerd Fonts:
- Hack Nerd Font
- Roboto Mono Nerd Font  
- DejaVu Sans Mono Nerd Font

Configure your terminal to use one of these fonts for the best experience with icons and symbols.

## 📁 Directory Structure

After installation, your configuration will be organized as:

```
~/.config/czsh/
├── oh-my-zsh/           # Oh My Zsh framework
├── fzf/                 # FZF fuzzy finder
├── lazydocker/          # Docker TUI
├── gemini/              # Gemini CLI configuration
│   └── config.sh        # Gemini API key configuration
└── bin/                 # Additional binaries

~/.zshrc                 # Main Zsh configuration (sourced from czsh/)
~/.config/zsh_codex.ini  # AI completion config (if enabled)
```

## 🔧 Customization

### Adding More Plugins

To add additional Oh My Zsh plugins, edit the `plugins` array in `czshrc.zsh`:

```bash
plugins=(
    # ... existing plugins ...
    your-new-plugin
)
```

### Modifying the Theme

The Powerlevel10k configuration can be customized by running:
```bash
p10k configure
```

Or manually edit the theme settings in `czshrc.zsh`.

### Custom Functions

Add your own functions to `czshrc.zsh` or create separate files in `~/.config/czsh/`.

## 🚨 Troubleshooting

### Common Issues

1. **Fonts not displaying correctly**: Make sure your terminal uses a Nerd Font
2. **Slow startup**: Some plugins may slow down shell startup; disable unused ones
3. **Git integration issues**: Ensure git is properly configured with your credentials
4. **AI completion not working**: Check your API key configuration in `~/.config/zsh_codex.ini`

### Backup Recovery

The installer automatically backs up your existing `.zshrc` to `.zshrc-backup-YYYY-MM-DD`.

To restore:
```bash
mv ~/.zshrc-backup-YYYY-MM-DD ~/.zshrc
```

### Reset Installation

To completely reset and reinstall:
```bash
rm -rf ~/.config/czsh
rm ~/.zshrc
# Run installer again
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the installation process
5. Submit a pull request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🙏 Acknowledgments

- [Oh My Zsh](https://ohmyz.sh/) - Framework for Zsh
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Theme
- [FZF](https://github.com/junegunn/fzf) - Fuzzy finder
- [Zsh Users](https://github.com/zsh-users) - Plugin collection
- All plugin authors and contributors

## 📧 Support

If you encounter issues or have questions:
1. Check the troubleshooting section above
2. Search existing issues in the repository
3. Create a new issue with detailed information about your problem

---

**Happy coding! 🎉**
