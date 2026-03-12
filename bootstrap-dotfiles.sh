#!/bin/bash
################################################################################
# Automated Dotfiles and Environment Bootstrapping (Professional Grade)
#
# - Strict mode (set -euo pipefail)
# - getopts for flag parsing
# - log() function with timestamp, console, and /var/log output
# Usage: ./bootstrap-dotfiles.sh [-d DOTFILES_DIR] [-v]
################################################################################

set -euo pipefail

LOG_FILE="/var/log/bootstrap-dotfiles.log"
VERBOSE=0
DOTFILES_DIR="$HOME/dotfiles"
TOOLS=(git tmux curl wget zsh vim)
CONDA_INSTALLER="Miniconda3-latest-Linux-x86_64.sh"
CONDA_URL="https://repo.anaconda.com/miniconda/$CONDA_INSTALLER"

log() {
    local msg="$1"
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$ts] $msg"
    echo "[$ts] $msg" >> "$LOG_FILE"
}

usage() {
    cat <<EOF
Usage: $0 [-d DOTFILES_DIR] [-v]
  -d DIR   Dotfiles directory (default: $HOME/dotfiles)
  -v       Verbose output
  --help   Show this help
EOF
}

while getopts ":d:v-:" opt; do
    case $opt in
        d) DOTFILES_DIR="$OPTARG" ;;
        v) VERBOSE=1 ;;
        -)
            case $OPTARG in
                help) usage; exit 0 ;;
                *) echo "Unknown option --$OPTARG"; usage; exit 1 ;;
            esac ;;
        *) echo "Unknown flag: -$OPTARG"; usage; exit 1 ;;
    esac
done

log "Using dotfiles directory: $DOTFILES_DIR"

install_tools() {
    log "Installing CLI tools: ${TOOLS[*]}"
    if command -v apt &>/dev/null; then
        sudo apt-get update
        sudo apt-get install -y "${TOOLS[@]}"
    elif command -v yum &>/dev/null; then
        sudo yum install -y "${TOOLS[@]}"
    elif command -v pacman &>/dev/null; then
        sudo pacman -Syu --noconfirm "${TOOLS[@]}"
    else
        log "Unsupported package manager. Install tools manually."
    fi
}

install_conda() {
    if ! command -v conda &>/dev/null; then
        log "Installing Miniconda..."
        wget "$CONDA_URL" -O "/tmp/$CONDA_INSTALLER"
        bash "/tmp/$CONDA_INSTALLER" -b -p "$HOME/miniconda"
        rm "/tmp/$CONDA_INSTALLER"
        "$HOME/miniconda/bin/conda" init
    else
        log "Conda already installed."
    fi
}

symlink_dotfiles() {
    log "Symlinking dotfiles from $DOTFILES_DIR"
    for file in "$DOTFILES_DIR"/.*; do
        [[ "$file" =~ /\.\.?$ ]] && continue
        base="$(basename "$file")"
        target="$HOME/$base"
        if [[ -e "$target" && ! -L "$target" ]]; then
            log "Backing up existing $target to $target.bak"
            mv "$target" "$target.bak"
        fi
        ln -sf "$file" "$target"
        log "Linked $file -> $target"
    done
}

setup_ssh() {
    if [[ ! -f "$HOME/.ssh/id_rsa" && ! -f "$HOME/.ssh/id_ed25519" ]]; then
        log "Generating new SSH key..."
        mkdir -p "$HOME/.ssh"
        ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -N "" -f "$HOME/.ssh/id_ed25519"
        log "SSH key generated at $HOME/.ssh/id_ed25519"
    else
        log "SSH key already exists."
    fi
}

main() {
    install_tools
    install_conda
    symlink_dotfiles
    setup_ssh
    log "Bootstrap complete!"
}

main "$@"
