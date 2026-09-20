#!/bin/bash

install_feature_prerequisites() {
	print_section "Prerequisites Check" "$CHECKMARK" "$YELLOW"
	logProgress "Detecting missing packages..."
	load_prerequisite_specs
	detect_missing_packages

	if [[ "$CZSH_PACKAGE_MANAGER" == "brew" && ${#MISSING_PACKAGES[@]} -gt 0 ]]; then
		logProgress "Installing packages from packages/Brewfile..."
		if HOMEBREW_BUNDLE_NO_UPGRADE=1 brew bundle \
			--file "$SCRIPT_DIR/packages/Brewfile" --no-lock; then
			logSuccess "Homebrew bundle is satisfied"
		else
			logWarning "Homebrew bundle reported a failure; falling back to missing packages only"
		fi

		# Bundle can fail because of unrelated stale dependency metadata. Recheck
		# commands and let the normal package loop install only what is still absent.
		detect_missing_packages
	fi

	if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
		logWarning "Missing packages found: ${MISSING_PACKAGES[*]}"
	else
		logSuccess "All prerequisites are satisfied!"
	fi
	echo

	install_missing_packages
}

register_install_feature install_feature_prerequisites
