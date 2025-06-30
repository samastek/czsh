# CZsh - Complete Zsh Configuration

A comprehensive and feature-rich Zsh configuration setup that transforms your terminal experience with modern tools, beautiful themes, and powerful plugins.

## 🚀 Features

- **Oh My Zsh** with custom configuration
- **Powerlevel10k** theme with beautiful prompts
- **Advanced plugins** for enhanced productivity
- **FZF integration** for fuzzy finding
- **AI-powered command completion** with zsh_codex
- **Modern tools** like lazydocker, bat, and more
- **Nerd Fonts** for beautiful icons
- **Smart aliases** and custom functions

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

## 📥 Installation

### Quick Install (Recommended)
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

# Combine multiple options
./install.sh --cp-hist --codex
```

#### Flag Details
- `--cp-hist` or `-c`: Copies your existing shell history to the new Zsh configuration
- `--interactive` or `-n`: Runs in interactive mode, asking for user input during installation
- `--codex` or `-x`: Installs and configures zsh_codex for AI-powered command completion

## ⚙️ Configuration

### AI Command Completion (Optional)

If you use the `--codex` flag, you'll need to provide an API key for AI-powered command completion. The configuration supports:

- **Groq API** (default): Fast and free inference
- **OpenAI API**: Official OpenAI models

Configuration files:
- `~/.config/zsh_codex.ini` - Main configuration
- `~/.config/openaiapirc` - Alternative OpenAI configuration

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
