#!/bin/bash

NERD_FONTS_RELEASE_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v$NERD_FONTS_VERSION"

extract_font_from_zip() {
	local archive_path="$1"
	local filename="$2"
	local destination_path="$3"

	python3 - "$archive_path" "$filename" "$destination_path" <<'PY'
import shutil
import sys
import zipfile
from pathlib import Path

archive_path, filename, destination_path = sys.argv[1:]

with zipfile.ZipFile(archive_path) as archive:
    matches = [
        member
        for member in archive.infolist()
        if not member.is_dir() and Path(member.filename).name == filename
    ]
    if len(matches) != 1:
        raise SystemExit(f"expected one {filename!r} in the archive, found {len(matches)}")

    with archive.open(matches[0]) as source, open(destination_path, "wb") as destination:
        shutil.copyfileobj(source, destination)
PY
}

install_nerd_font() {
	local family="$1"
	local filename="$2"
	local target="$CZSH_FONT_DIR/$filename"
	local temp_dir=""
	local archive_path=""
	local extracted_path=""
	local staged_path="$CZSH_FONT_DIR/.${filename}.tmp.$$"
	local download_url="$NERD_FONTS_RELEASE_BASE_URL/$family.zip"

	if [[ -f "$target" && "$UPGRADE_TOOLS" != true ]]; then
		logAlreadyInstalled "$filename"
		return 0
	fi

	logInstalling "$filename"
	temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/czsh-font.XXXXXX")" || {
		logWarning "Failed to create a temporary directory for $filename"
		return 1
	}
	archive_path="$temp_dir/$family.zip"
	extracted_path="$temp_dir/$filename"

	if ! curl --fail --location --retry 3 --connect-timeout 15 \
		--silent --show-error "$download_url" --output "$archive_path"; then
		logWarning "Failed to download $filename from the Nerd Fonts release"
		rm -rf "$temp_dir"
		return 1
	fi

	if ! extract_font_from_zip "$archive_path" "$filename" "$extracted_path"; then
		logWarning "Downloaded archive did not contain $filename"
		rm -rf "$temp_dir"
		return 1
	fi

	if ! install -m 0644 "$extracted_path" "$staged_path" || ! mv -f "$staged_path" "$target"; then
		logWarning "Failed to install $filename into $CZSH_FONT_DIR"
		rm -f "$staged_path"
		rm -rf "$temp_dir"
		return 1
	fi

	rm -rf "$temp_dir"
	logInstalled "$filename"
}

install_feature_fonts() {
	local failed=0

	print_section "Nerd Fonts Installation" "$SPARKLES" "$PURPLE"
	logProgress "Installing fonts into $CZSH_FONT_DIR"

	install_nerd_font "Hack" "HackNerdFont-Regular.ttf" || failed=1
	install_nerd_font "RobotoMono" "RobotoMonoNerdFont-Regular.ttf" || failed=1
	install_nerd_font "DejaVuSansMono" "DejaVuSansMNerdFont-Regular.ttf" || failed=1

	if command -v fc-cache >/dev/null 2>&1; then
		logProgress "Refreshing font cache..."
		if fc-cache -f "$CZSH_FONT_DIR" >/dev/null 2>&1; then
			logSuccess "Font cache updated successfully"
		else
			logWarning "Failed to refresh font cache"
			failed=1
		fi
	fi

	if (( failed )); then
		logWarning "One or more Nerd Fonts could not be installed"
	fi
	echo
}

register_install_feature install_feature_fonts
