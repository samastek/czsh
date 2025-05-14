# Project Setup

This project sets up a customized Zsh environment with various plugins and tools to enhance your terminal experience.

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

- Clone and set up various Zsh plugins.
- Install fzf for fuzzy finding.
- Install powerlevel10k for a beautiful Zsh prompt.
- Install lazydocker for managing Docker containers.
- Install marker for command bookmarking.
- Install todo.sh for managing todo lists.

## Configuration

### Zsh Plugins
The following Zsh plugins are configured:

- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-completions
- zsh-history-substring-search
- fzf-tab
- zsh-codex

### Custom Zsh Configuration
Place your personal Zsh configuration files under:

## OpenAI API Key
To configure the OpenAI API key for zsh-codex, the script will prompt you to enter your API key. This key will be stored in:

## Usage
After installation, start a new Zsh session to apply the changes. Make sure to change Zsh to the default shell by running:

```
chsh -s $(which zsh)
```

In a new Zsh session, manually run:

```
source ~/.zshrc
```

## License
This project is licensed under the MIT License.

## Contributing
Feel free to open issues or submit pull requests for improvements.

## Contact
For any questions or suggestions, please contact the project maintainer.

This README provides an overview of the project setup and usage. For more detailed information, refer to the comments and documentation within the scripts. 
