#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
RESET='\033[0m'

# Background colors
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_PURPLE='\033[45m'
BG_CYAN='\033[46m'

# Unicode symbols
CHECKMARK="✅"
CROSS="❌"
WARNING="⚠️"
INFO="ℹ️"
ROCKET="🚀"
GEAR="⚙️"
PACKAGE="📦"
FOLDER="📁"
ARROW="➤"
STAR="⭐"
HOURGLASS="⏳"
ZAPP="⚡"
FIRE="🔥"
SPARKLES="✨"

# Get terminal width for proper formatting
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)

# Print a separator line
print_separator() {
	local char="${1:-─}"
	local color="${2:-$GRAY}"
	printf "${color}%*s${RESET}\n" "$TERM_WIDTH" | tr ' ' "$char"
}

# Print a fancy header
print_header() {
	local text="$1"
	local color="${2:-$CYAN}"
	local bg_color="${3:-}"

	print_separator "═" "$color"
	printf "${bg_color}${color}${BOLD}%*s${RESET}\n" $(((${#text} + $TERM_WIDTH) / 2)) "$text"
	print_separator "═" "$color"
}

# Print a section header
print_section() {
	local text="$1"
	local icon="${2:-$GEAR}"
	local color="${3:-$PURPLE}"

	echo
	printf "${color}${BOLD}$icon $text${RESET}\n"
	print_separator "─" "$color"
}

# Enhanced logging functions with icons and better formatting
logSuccess() {
	local message="$1"
	printf "${GREEN}${BOLD}$CHECKMARK $message${RESET}\n"
}

logError() {
	local message="$1"
	printf "${RED}${BOLD}$CROSS ERROR: $message${RESET}\n"
}

logWarning() {
	local message="$1"
	printf "${YELLOW}${BOLD}$WARNING $message${RESET}\n"
}

logInfo() {
	local message="$1"
	printf "${CYAN}$INFO $message${RESET}\n"
}

logProgress() {
	local message="$1"
	printf "${BLUE}${BOLD}$HOURGLASS $message${RESET}\n"
}

logInstalling() {
	local package="$1"
	printf "${PURPLE}${BOLD}$PACKAGE Installing $package...${RESET}\n"
}

logInstalled() {
	local package="$1"
	printf "${GREEN}${BOLD}$CHECKMARK $package installed successfully${RESET}\n"
}

logAlreadyInstalled() {
	local package="$1"
	printf "${GREEN}$CHECKMARK $package is already installed${RESET}\n"
}

logUpdating() {
	local package="$1"
	printf "${BLUE}$ZAPP Updating $package...${RESET}\n"
}

logUpdated() {
	local package="$1"
	printf "${GREEN}$CHECKMARK $package updated successfully${RESET}\n"
}

logConfiguring() {
	local component="$1"
	printf "${PURPLE}$GEAR Configuring $component...${RESET}\n"
}

logConfigured() {
	local component="$1"
	printf "${GREEN}$CHECKMARK $component configured successfully${RESET}\n"
}

logStep() {
	local step_num="$1"
	local total_steps="$2"
	local description="$3"
	printf "${CYAN}${BOLD}[$step_num/$total_steps] $ARROW $description${RESET}\n"
}

logCommand() {
	local command="$1"
	printf "${GRAY}${DIM}$ $command${RESET}\n"
}

logTip() {
	local tip="$1"
	printf "${YELLOW}${BOLD}💡 TIP: $tip${RESET}\n"
}

logNote() {
	local note="$1"
	printf "${BLUE}📝 NOTE: $note${RESET}\n"
}

# Legacy function for backward compatibility
echoIULRed() {
	echo -e "\\033[3;4;31m$*\\033[m"
}

# Progress bar function
show_progress_bar() {
	local current=$1
	local total=$2
	local width=50
	local percentage=$((current * 100 / total))
	local completed=$((current * width / total))
	local remaining=$((width - completed))

	printf "\r${CYAN}["
	printf "%*s" $completed | tr ' ' '█'
	printf "%*s" $remaining | tr ' ' '░'
	printf "] ${WHITE}%d%% ${CYAN}(${WHITE}%d${CYAN}/${WHITE}%d${CYAN})${RESET}" $percentage $current $total
}

# Animated spinner for long operations
show_spinner() {
	local pid=$1
	local message="${2:-Processing}"
	local spin_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
	local i=0

	while kill -0 $pid 2>/dev/null; do
		local char=${spin_chars:$i:1}
		printf "\r${YELLOW}${char} ${WHITE}%s...${RESET}" "$message"
		i=$(((i + 1) % ${#spin_chars}))
		sleep 0.1
	done
	printf "\r"
}

# Enhanced step logging with progress indication
logStepProgress() {
	local current=$1
	local total=$2
	local step_name=$3
	local sub_message=${4:-""}

	printf "${BLUE}[${WHITE}%d${BLUE}/${WHITE}%d${BLUE}] ${BLUE}➤ ${WHITE}%s${RESET}" "$current" "$total" "$step_name"
	if [[ -n "$sub_message" ]]; then
		printf " ${DIM}${GRAY}%s${RESET}" "$sub_message"
	fi
	echo
}

# Enhanced installation summary
print_installation_summary() {
	local start_time=$1
	local end_time=$2
	local duration=$((end_time - start_time))
	local minutes=$((duration / 60))
	local seconds=$((duration % 60))

	echo
	print_separator "═" "$GREEN"
	printf "${GREEN}${BOLD}🎉 Installation Summary 🎉${RESET}\n"
	print_separator "═" "$GREEN"

	printf "${WHITE}⏱️  Total time: ${GREEN}%dm %ds${RESET}\n" $minutes $seconds
	printf "${WHITE}📂 Config location: ${CYAN}%s${RESET}\n" "$HOME/.config/czsh"
	printf "${WHITE}🔧 Shell config: ${CYAN}%s${RESET}\n" "$HOME/.zshrc"

	echo
	printf "${YELLOW}${BOLD}Next Steps:${RESET}\n"
	printf "${WHITE}1.${RESET} ${GRAY}Exit this terminal${RESET}\n"
	printf "${WHITE}2.${RESET} ${GRAY}Start a new terminal session${RESET}\n"
	printf "${WHITE}3.${RESET} ${GRAY}Run: ${BOLD}chsh -s $(which zsh)${RESET}${GRAY} (to set zsh as default)${RESET}\n"
	printf "${WHITE}4.${RESET} ${GRAY}Run: ${BOLD}build-fzf-tab-module${RESET}${GRAY} (in new zsh session)${RESET}\n"

	print_separator "═" "$GREEN"
}

# Enhanced error handling with suggestions
logErrorWithSuggestion() {
	local error_msg=$1
	local suggestion=$2

	printf "${RED}${BOLD}❌ ERROR: ${WHITE}%s${RESET}\n" "$error_msg"
	if [[ -n "$suggestion" ]]; then
		printf "${YELLOW}💡 Suggestion: ${WHITE}%s${RESET}\n" "$suggestion"
	fi
}
