#!/usr/bin/env bash

set -e

# Set dotfiles source directory
DOTFILES_DIR="$HOME/.dotfiles"

# Set NEWT_COLORS
export NEWT_COLORS='
    root=white,black
    border=white,black
    window=white,black
    shadow=black,black
    title=white,black
    textbox=white,black
    button=black,blue
    entry=black,white
    checkbox=white,black
    radiolist=white,black
    listbox=white,black
'

# Key maps to "source::target" pairs (can be multiple per key)
declare -A FILE_MAP
FILE_MAP["zsh"]=".zshenv::$HOME/.zshenv .config/zsh::$HOME/.config/zsh"
FILE_MAP["nvim"]=".config/nvim::$HOME/.config/nvim"
FILE_MAP["git"]=".config/git::$HOME/.config/git"
FILE_MAP["tmux"]=".config/tmux::$HOME/.config/tmux"
FILE_MAP["yazi"]=".config/yazi::$HOME/.config/yazi"
FILE_MAP["ghostty"]=".config/ghostty::$HOME/.config/ghostty"
FILE_MAP["zed"]=".config/zed::$HOME/.config/zed"
FILE_MAP["vim"]=".vim::$HOME/.vim"
FILE_MAP["vscode"]="vscode::$HOME/.config/Code/User"

# Build options for whiptail
OPTIONS=()
for key in "${!FILE_MAP[@]}"; do
  OPTIONS+=("$key" "" OFF)
done

# Show whiptail checklist
SELECTED=$(whiptail --title "Dotfiles Installer" --checklist \
"Select which dotfiles to install:" 20 75 10 \
"${OPTIONS[@]}" 3>&1 1>&2 2>&3)

# Exit if cancelled
if [ $? -ne 0 ]; then
  echo "Installation cancelled."
  exit 1
fi

# Clean selection
SELECTED=($(echo "$SELECTED" | tr -d '"'))

# Process each selected item
for key in "${SELECTED[@]}"; do
  echo -e "\n Installing $key..."

  IFS=' ' read -ra MAPPINGS <<< "${FILE_MAP[$key]}"
  for map in "${MAPPINGS[@]}"; do
    IFS='::' read -r src_name dest <<< "$map"

    # Remove leading/trailing spaces or colons from source and destination
    src="${DOTFILES_DIR}/${src_name//[: ]/}"
    dest="${dest//[: ]/}"

    # Check if source exists
    if [ ! -e "$src" ]; then
      echo "Source not found: $src"
      continue
    fi

    # Backup if dest exists and is not symlink
    if [ -e "$dest" ]; then
      if [ -L "$dest" ]; then
        # If it's a symlink, remove the symlink
        rm "$dest"
        echo "Removed existing symlink: $dest"
      elif [ -d "$dest" ]; then
        # If it's a directory, move it to a backup folder
        mv "$dest" "${dest}.bak"
        echo "Backed up directory $dest → ${dest}.bak"
      else
        # If it's a file, just back it up
        mv "$dest" "${dest}.bak"
        echo "Backed up file $dest → ${dest}.bak"
      fi
    fi

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"

    # Create symlink
    ln -s "$src" "$dest" && echo "Linked $src → $dest"
  done
done

echo -e "\n Dotfiles installation complete."
