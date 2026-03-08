#!/bin/bash

install_feature_prerequisites() {
	print_section "Prerequisites Check" "$CHECKMARK" "$YELLOW"
	logProgress "Detecting missing packages..."
	detect_missing_packages

	if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
		logWarning "Missing packages found: ${MISSING_PACKAGES[*]}"
	else
		logSuccess "All prerequisites are satisfied!"
	fi
	echo

	install_missing_packages
}

register_install_feature install_feature_prerequisites