#!/bin/bash

supports_color() {
	[[ -t 1 ]] || return 1
	[[ -z "${NO_COLOR:-}" ]] || return 1
	[[ "${TERM:-}" != "dumb" ]] || return 1
	return 0
}

initialize_colors() {
	if supports_color; then
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
		BG_RED='\033[41m'
		BG_GREEN='\033[42m'
		BG_YELLOW='\033[43m'
		BG_BLUE='\033[44m'
		BG_PURPLE='\033[45m'
		BG_CYAN='\033[46m'
	else
		RED=''
		GREEN=''
		YELLOW=''
		BLUE=''
		PURPLE=''
		CYAN=''
		WHITE=''
		GRAY=''
		BOLD=''
		DIM=''
		UNDERLINE=''
		BLINK=''
		RESET=''
		BG_RED=''
		BG_GREEN=''
		BG_YELLOW=''
		BG_BLUE=''
		BG_PURPLE=''
		BG_CYAN=''
	fi
}

initialize_colors

# ASCII status labels for portable output.
CHECKMARK='[OK]'
CROSS='[ERR]'
WARNING='[WARN]'
INFO='[INFO]'
ROCKET='[RUN]'
GEAR='[SYS]'
PACKAGE='[PKG]'
FOLDER='[DIR]'
ARROW='->'
STAR='[ZSH]'
HOURGLASS='[WAIT]'
ZAPP='[UPD]'
FIRE='[APP]'
SPARKLES='[UI]'

DEFAULT_TERM_WIDTH=80
MIN_TERM_WIDTH=60
MAX_TERM_WIDTH=100

get_terminal_width() {
	local width="${COLUMNS:-}"

	if ! [[ "$width" =~ ^[0-9]+$ ]] || (( width <= 0 )); then
		if command -v tput >/dev/null 2>&1 && [[ "${TERM:-}" != "dumb" ]]; then
			width="$(tput cols 2>/dev/null)"
		fi
	fi

	if ! [[ "$width" =~ ^[0-9]+$ ]] || (( width <= 0 )); then
		width=$DEFAULT_TERM_WIDTH
	fi

	if (( width < MIN_TERM_WIDTH )); then
		width=$MIN_TERM_WIDTH
	elif (( width > MAX_TERM_WIDTH )); then
		width=$MAX_TERM_WIDTH
	fi

	printf '%s\n' "$width"
}

repeat_char() {
	local char="${1:--}"
	local count="${2:-0}"
	local padding=""

	if (( count <= 0 )); then
		return 0
	fi

	printf -v padding '%*s' "$count" ''
	printf '%s' "${padding// /$char}"
}

center_text() {
	local text="$1"
	local width="$2"
	local text_length=${#text}
	local left_padding=0
	local right_padding=0

	if (( text_length >= width )); then
		printf '%s' "$text"
		return 0
	fi

	left_padding=$(((width - text_length) / 2))
	right_padding=$((width - text_length - left_padding))

	printf '%*s%s%*s' "$left_padding" '' "$text" "$right_padding" ''
}

print_box() {
	local color="${1:-$CYAN}"
	shift
	local -a lines=("$@")
	local width
	local inner_width
	local max_length=0
	local line
	local border

	width=$(get_terminal_width)
	inner_width=$((width - 4))

	for line in "${lines[@]}"; do
		if (( ${#line} > max_length )); then
			max_length=${#line}
		fi
	done

	if (( max_length > inner_width )); then
		inner_width=$max_length
	fi

	border="+$(repeat_char '-' "$((inner_width + 2))")+"
	printf '%b%s%b\n' "${color}${BOLD}" "$border" "$RESET"
	for line in "${lines[@]}"; do
		printf '%b|%b %-*s %b|%b\n' "${color}${BOLD}" "$RESET" "$inner_width" "$line" "${color}${BOLD}" "$RESET"
	done
	printf '%b%s%b\n' "${color}${BOLD}" "$border" "$RESET"
}

print_separator() {
	local char="${1:--}"
	local color="${2:-$GRAY}"
	local width

	width=$(get_terminal_width)
	printf '%b%s%b\n' "$color" "$(repeat_char "$char" "$width")" "$RESET"
}

print_header() {
	local text="$1"
	local color="${2:-$CYAN}"
	local bg_color="${3:-}"
	local frame_style="${bg_color}${color}"
	local width
	local inner_width

	width=$(get_terminal_width)
	inner_width=$((width - 4))
	if (( ${#text} > inner_width )); then
		inner_width=${#text}
	fi

	print_box "$frame_style" "$(center_text "$text" "$inner_width")"
}

print_section() {
	local text="$1"
	local label="${2:-$GEAR}"
	local color="${3:-$PURPLE}"
	local width
	local banner
	local trailing_width

	width=$(get_terminal_width)
	banner="$label $text "
	trailing_width=$((width - ${#banner}))
	if (( trailing_width < 8 )); then
		trailing_width=8
	fi

	echo
	printf '%b%s%s%b\n' "${color}${BOLD}" "$banner" "$(repeat_char '-' "$trailing_width")" "$RESET"
}

log_with_prefix() {
	local color="$1"
	local prefix="$2"
	local message="$3"
	local style="${4:-}"

	printf '%b%-6s%b %s\n' "${color}${style}" "$prefix" "$RESET" "$message"
}

logSuccess() {
	local message="$1"
	log_with_prefix "$GREEN" "$CHECKMARK" "$message" "$BOLD"
}

logError() {
	local message="$1"
	log_with_prefix "$RED" "$CROSS" "$message" "$BOLD"
}

logWarning() {
	local message="$1"
	log_with_prefix "$YELLOW" "$WARNING" "$message" "$BOLD"
}

logInfo() {
	local message="$1"
	log_with_prefix "$CYAN" "$INFO" "$message"
}

logProgress() {
	local message="$1"
	log_with_prefix "$BLUE" "$HOURGLASS" "$message" "$BOLD"
}

logInstalling() {
	local package="$1"
	log_with_prefix "$PURPLE" "$PACKAGE" "Installing $package..." "$BOLD"
}

logInstalled() {
	local package="$1"
	log_with_prefix "$GREEN" "$CHECKMARK" "$package installed successfully" "$BOLD"
}

logAlreadyInstalled() {
	local package="$1"
	log_with_prefix "$GREEN" "$CHECKMARK" "$package is already installed"
}

logUpdating() {
	local package="$1"
	log_with_prefix "$BLUE" "$ZAPP" "Updating $package..."
}

logUpdated() {
	local package="$1"
	log_with_prefix "$GREEN" "$CHECKMARK" "$package updated successfully"
}

logConfiguring() {
	local component="$1"
	log_with_prefix "$PURPLE" "$GEAR" "Configuring $component..."
}

logConfigured() {
	local component="$1"
	log_with_prefix "$GREEN" "$CHECKMARK" "$component configured successfully"
}

logStep() {
	local step_num="$1"
	local total_steps="$2"
	local description="$3"

	printf '%b[%d/%d]%b %s %s\n' "${CYAN}${BOLD}" "$step_num" "$total_steps" "$RESET" "$ARROW" "$description"
}

logCommand() {
	local command="$1"
	printf '%b$ %s%b\n' "${GRAY}${DIM}" "$command" "$RESET"
}

logTip() {
	local tip="$1"
	log_with_prefix "$YELLOW" '[TIP]' "$tip" "$BOLD"
}

logNote() {
	local note="$1"
	log_with_prefix "$BLUE" '[NOTE]' "$note"
}

# Legacy function for backward compatibility
echoIULRed() {
	printf '%b%s%b\n' "${RED}${UNDERLINE}" "$*" "$RESET"
}

show_progress_bar() {
	local current=$1
	local total=$2
	local width=40
	local percentage=0
	local completed=0
	local remaining=0

	if (( total <= 0 )); then
		total=1
	fi

	percentage=$((current * 100 / total))
	completed=$((current * width / total))
	remaining=$((width - completed))

	printf '\r%b[%s%s] %3d%% (%d/%d)%b' "$CYAN" "$(repeat_char '#' "$completed")" "$(repeat_char '.' "$remaining")" "$percentage" "$current" "$total" "$RESET"
}

show_spinner() {
	local pid=$1
	local message="${2:-Processing}"
	local -a spin_chars=('|' '/' '-' '\\')
	local i=0

	while kill -0 "$pid" 2>/dev/null; do
		printf '\r%b%s%b %s...' "$YELLOW" "${spin_chars[$i]}" "$RESET" "$message"
		i=$(((i + 1) % ${#spin_chars[@]}))
		sleep 0.1
	done
	printf '\r'
}

logStepProgress() {
	local current=$1
	local total=$2
	local step_name=$3
	local sub_message=${4:-""}

	printf '%b[%d/%d]%b %s %s' "${BLUE}${BOLD}" "$current" "$total" "$RESET" "$ARROW" "$step_name"
	if [[ -n "$sub_message" ]]; then
		printf ' %b%s%b' "${GRAY}${DIM}" "$sub_message" "$RESET"
	fi
	echo
}

print_installation_summary() {
	local start_time=$1
	local end_time=$2
	local duration=$((end_time - start_time))
	local minutes=$((duration / 60))
	local seconds=$((duration % 60))
	local summary_width
	local zsh_binary

	zsh_binary="$(command -v zsh 2>/dev/null)"
	if [[ -z "$zsh_binary" ]]; then
		zsh_binary='/usr/bin/zsh'
	fi

	summary_width=$(( $(get_terminal_width) - 4 ))

	echo
	print_box "$GREEN" \
		"$(center_text 'INSTALLATION SUMMARY' "$summary_width")" \
		'' \
		"Total time      : ${minutes}m ${seconds}s" \
		"Config location : $HOME/.config/czsh" \
		"Shell config    : $HOME/.zshrc" \
		'' \
		'Next steps:' \
		'1. Exit this terminal' \
		'2. Start a new terminal session' \
		"3. Run: chsh -s $zsh_binary" \
		'4. Run: build-fzf-tab-module'
}

logErrorWithSuggestion() {
	local error_msg=$1
	local suggestion=$2

	logError "$error_msg"
	if [[ -n "$suggestion" ]]; then
		log_with_prefix "$YELLOW" '[HINT]' "$suggestion"
	fi
}
