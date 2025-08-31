# Dotfiles Management Setup

## Overview

This repository manages my personal macOS configuration using GNU Stow for symlink-based dotfiles management. The setup is designed to separate universal configurations (suitable for syncing) from work-specific/sensitive configurations (kept local only). If you are reading this it is because you are either currently sitting in the dotfiles repository at ~/dotfiles/, or in the home directory itself (in this case, this file would be symlinked there). Start by identifying where you are. The branch you are on will also help you identify which os you are on.

## Repository Structure

- `main` branch: Universal configuration that works on any system
- `macos` branch: macOS-specific configuration + work-specific customizations
- `arch` branch: Arch Linux configuration (reference implementation)

## Stow Package Organization

Each application/tool gets its own "package" directory that mirrors the target filesystem structure:

- `zsh/` → Contains `.zshrc` that stows to `~/.zshrc`
- `wezterm/` → Contains `.wezterm.lua` that stows to `~/.wezterm.lua`
- `config/` → Contains subdirs that stow to `~/.config/` (use: `stow --target=$HOME/.config config`)
- `git/` → (Planned) Contains sanitized `.gitconfig`

**Important:** For the `config/` package, always use `stow --target=$HOME/.config config` to ensure symlinks are created in `~/.config/` not in `~`

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

## Recurring Maintenance Tasks

### Config File Organization
When asked to "check" a config file (e.g., "check the zshrc", "check my wezterm config") without additional context, this is a recurring maintenance request. The standard workflow is:

1. **Check git diff** to identify recent additions made hastily
   ```bash
   git diff <path/to/config/file>
   ```

2. **Read the original file structure** to understand the existing organization patterns before changes
   ```bash
   git show HEAD:<path/to/config/file>
   ```
   Or if changes are staged:
   ```bash
   git show :<path/to/config/file>
   ```

3. **Analyze the file's organization** by identifying:
   - Section headers and their naming conventions
   - Grouping patterns (by functionality, alphabetical, etc.)
   - Comment styles and documentation patterns
   - Indentation and formatting conventions

4. **Reorganize additions** to match the file's existing structure:
   - Move items to their semantically appropriate sections
   - Maintain consistent ordering within sections
   - Follow existing naming and formatting conventions

5. **Optimize** any redundant or inefficient patterns while preserving functionality

This is an ongoing process as configurations are frequently updated during daily work without careful consideration of organization. The goal is to maintain clean, well-organized config files that follow their own established patterns.
