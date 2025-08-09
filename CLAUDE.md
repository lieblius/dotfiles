# Dotfiles Management Setup

## Overview

This repository manages my personal macOS configuration using GNU Stow for symlink-based dotfiles management. The setup is designed to separate universal configurations (suitable for syncing) from work-specific/sensitive configurations (kept local only).

## Repository Structure

- `main` branch: Universal configuration that works on any system
- `macos` branch: macOS-specific configuration + work-specific customizations
- `arch` branch: Arch Linux configuration (reference implementation)

## Stow Package Organization

Each application/tool gets its own "package" directory that mirrors the target filesystem structure:

- `zsh/` → Contains `.zshrc` that stows to `~/.zshrc`
- `wezterm/` → Contains `.wezterm.lua` that stows to `~/.wezterm.lua`
- `config/` → (Planned) Contains files that stow to `~/.config/`
- `git/` → (Planned) Contains sanitized `.gitconfig`

## Configuration Philosophy

**Include in dotfiles:**
- Universal configurations that enhance workflow
- Non-sensitive application settings
- Portable configurations that work across environments

**Keep local only:**
- Work credentials, API keys, sensitive paths
- Machine-specific configurations
- Generated/cache files

## Current Setup Status

### Completed
- ✅ Cleaned up and reorganized `.zshrc` with logical sections
- ✅ Consolidated `.zshenv` into `.zshrc` (removed `.zshenv`)
- ✅ Set up `zsh/` stow package with symlinked `.zshrc`
- ✅ Set up `wezterm/` stow package with reorganized config
- ✅ Optimized wezterm config structure (same functionality, better organization)

### Configuration Details
- **zshrc structure:** Oh-My-Zsh setup, Environment Variables, PATH Configuration, Prompt Setup, Categorized Aliases, Grouped Functions, FZF Configuration, Tool Initialization
- **Secrets handling:** `.zshsecrets` sourced early in zshrc for work-specific env vars
- **wezterm structure:** Core Configuration, Visual Configuration, Categorized Keybindings, Key Tables, Event Handlers

## Current Process: Building the Dotfiles System

**Phase 1: Foundation (In Progress)**
We're systematically going through my existing configurations, analyzing and optimizing their structure, then converting them into stow packages. Each config file is being:

1. **Analyzed** for organization and optimization opportunities
2. **Restructured** with logical sections and clear categorization
3. **Cleaned** of redundant comments and improved for maintainability  
4. **Converted** to a stow package with proper directory structure
5. **Tested** to ensure symlinks work and functionality is preserved

**Next Steps:**
- Add `aerospace.toml` to a `config/` package
- Add sanitized `.gitconfig` to a `git/` package  
- Add `nvim` configuration if desired
- Create installation documentation/script

**End Goal:**
A clean, organized, version-controlled dotfiles system where I can quickly set up my development environment on any new machine with a simple `git clone` and `stow` commands, while keeping sensitive work configurations separate and secure.