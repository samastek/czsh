#!/bin/bash

install_feature_core() {
	backup_existing_zshrc_config

	print_section "Directory Setup" "$FOLDER" "$CYAN"
	logInfo "The setup will be installed in $CZSH_HOME"
	logNote "Place your personal zshrc override files under $CZSH_USER_ZSHRC_DIR"

	ensure_directories \
		"$CZSH_HOME" \
		"$CZSH_USER_ZSHRC_DIR" \
		"$CZSH_BIN_DIR" \
		"$CZSH_CACHE_DIR" \
		"$CZSH_RUNTIME_FEATURES_TARGET_DIR" \
		"$CZSH_POST_FEATURES_TARGET_DIR" \
		"$CZSH_FONT_DIR"

	logSuccess "Created configuration directories"
	echo

	configure_ohmyzsh
	copy_base_configuration_files
}

register_install_feature install_feature_core