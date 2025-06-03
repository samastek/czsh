# CZSH - Standalone Zsh Configuration

This project sets up a customized Zsh environment with various plugins and tools to enhance your terminal experience. **This configuration does NOT require Oh My Zsh** - all plugins are installed and managed directly for better performance and reduced overhead.

## Features

- 🚀 **No Oh My Zsh dependency** - Lightweight and fast
- 🎨 **Powerlevel10k theme** - Beautiful and highly customizable prompt
- 🔍 **Smart plugin management** - Direct plugin loading without framework overhead
- 📦 **Essential plugins included** - Auto-suggestions, syntax highlighting, completions, and more
- 🛠️ **Modern tools integration** - fzf, lazydocker, marker, todo.sh, Neovim with NvChad

## Supported Operating Systems

- **Linux**: Ubuntu, Debian, Arch, Fedora, CentOS, and other major distributions
- **macOS**: Intel and Apple Silicon Macs with automatic Homebrew installation

## Prerequisites

### Linux
- Git
- Python3
- wget or curl
- fontconfig (for font management)

### macOS  
- Git (usually pre-installed or via Xcode Command Line Tools)
- Python3 (usually pre-installed or via Homebrew)
- wget or curl (curl is pre-installed, wget will be installed via Homebrew if needed)
- Homebrew (will be automatically installed if not present)

## Installation

To install the project, run the `install.sh` script:

```sh
./install.sh
```

### Command Line Options

- `--cp-hist` or `-c`: Copy bash history to zsh history
- `--interactive` or `-n`: Run in interactive mode (prompts for shell change)
- `--codex` or `-x`: Enable zsh-codex with OpenAI integration

Example:
```sh
./install.sh --cp-hist --codex
```
This script will:

- Install and configure zsh plugins directly (no Oh My Zsh needed)
- Install fzf for fuzzy finding
- Install powerlevel10k theme (standalone version)
- Install lazydocker for managing Docker containers
- Install marker for command bookmarking
- Install todo.sh for managing todo lists
- Install Neovim with NvChad configuration

## Configuration

### Zsh Plugins
The following Zsh plugins are configured and loaded directly:

- **zsh-autosuggestions** - Fish-like autosuggestions
- **zsh-syntax-highlighting** - Real-time syntax highlighting
- **zsh-completions** - Additional completion definitions
- **zsh-history-substring-search** - Search history with arrow keys
- **fzf-tab** - Fuzzy completion with fzf
- **forgit** - Interactive git commands
- **z** - Smart directory jumping
- **zsh-codex** - AI-powered command completion (optional)

### Built-in Functionality
The configuration includes replacements for common Oh My Zsh plugins:

- **Web search** - Search engines directly from terminal
- **Extract** - Universal archive extraction function
- **Docker aliases** - Common docker command shortcuts
- **Git aliases** - Useful git shortcuts and functions

### Custom Zsh Configuration
Place your personal Zsh configuration files under:
```
~/.config/czsh/zshrc/
```

All files in this directory will be automatically sourced.

## Plugin Management

The configuration uses a lightweight plugin management system that:

- Loads plugins directly without framework overhead
- Automatically handles different plugin file naming conventions
- Provides better performance than Oh My Zsh
- Maintains compatibility with most zsh plugins

## OpenAI API Key
To configure the OpenAI API key for zsh-codex, the script will prompt you to enter your API key. This key will be stored in:
```
~/.config/zsh_codex.ini
```

## Usage
After installation, start a new Zsh session to apply the changes. Make sure to change Zsh to the default shell by running:

```
chsh -s $(which zsh)
```

In a new Zsh session, manually run:

```
source ~/.zshrc
```

## Migration from Oh My Zsh

If you're migrating from Oh My Zsh, this configuration provides:

- **Better performance** - No framework overhead
- **Same functionality** - All popular plugins work the same way
- **Easier customization** - Direct plugin management
- **Reduced complexity** - No need to understand Oh My Zsh internals

Your existing plugin configurations should work with minimal changes.

## License
This project is licensed under the MIT License.

## Contributing
Feel free to open issues or submit pull requests for improvements.

## Contact
For any questions or suggestions, please contact the project maintainer.

This README provides an overview of the project setup and usage. For more detailed information, refer to the comments and documentation within the scripts. 
