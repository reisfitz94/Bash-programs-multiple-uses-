# Automated Dotfiles and Environment Bootstrapping

## Overview
A professional Bash script to bootstrap your dotfiles and developer environment. Installs essential CLI tools, clones dotfiles, and configures your shell and editor.

---

## Prerequisites
- Bash 5+
- git
- tmux, curl, wget, zsh, vim
- (Optional) Miniconda for Python environments

---

## Usage
```bash
./bootstrap-dotfiles.sh [-d DOTFILES_DIR] [-v]
```
- `-d DIR`: Dotfiles directory (default: $HOME/dotfiles)
- `-v`: Verbose output
- `--help`: Show usage

---

## Features
- Installs and configures essential CLI tools
- Clones dotfiles from specified directory
- Sets up Miniconda if desired
- Timestamped logging to /var/log/bootstrap-dotfiles.log

---

## Troubleshooting
- Check /var/log/bootstrap-dotfiles.log for errors
- Ensure all dependencies are installed
- Run with sudo if required for system-wide changes
