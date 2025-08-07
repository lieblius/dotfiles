# Agent Configuration for Kyle's Arch Linux Setup

## System Overview
- **OS**: Arch Linux with Omarchy (Hyprland-based desktop environment)
- **Shell**: zsh with Omarchy bash integration
- **Terminal**: WezTerm (primary), Alacritty (backup, Omarchy-managed)
- **Dotfiles**: Managed with GNU Stow, stored at `~/dotfiles/`
- **Repository**: https://github.com/lieblius/dotfiles (public)

## Dotfiles Architecture

### Branch Structure
- **`main`**: Clean foundation with just "initial commit"
- **`arch`**: Arch Linux/Omarchy-specific dotfiles (current system)
- **`macos`**: macOS dotfiles (preserved from previous setup)

### Stow Packages
```
~/dotfiles/
├── config/        # .config files (flat structure)
│   ├── hypr/      # Hyprland window manager config
│   ├── opencode/  # OpenCode configuration
│   └── wezterm/   # WezTerm terminal config
├── git/           # Git configuration (.gitconfig)
├── prompts/       # Development prompts and documentation
└── zsh/           # Zsh shell configuration
```

### File Management Philosophy
- **Omarchy-managed**: `.bashrc`, alacritty config (hands-off, let Omarchy update)
- **Personal dotfiles**: `.zshrc`, `.gitconfig`, hyprland configs, wezterm config (managed via stow)
- **Clean separation**: No conflicts with Omarchy updates

## Key Configurations

### Shell Setup
- **Primary shell**: zsh with consolidated config in `.zshrc`
- **Omarchy integration**: Sources `~/.local/share/omarchy/default/bash/bashrc` for compatibility
- **Personal features**: 
  - Aliases: `ls`, `grep`, `c` (ccr code)
  - Environment: BUN_INSTALL, opencode, claude paths
  - Tools: zoxide, adaptive fastfetch function
  - Theme: GTK_THEME=Tokyonight-Dark

### Hyprland Customizations
- **Terminal override**: `$terminal = wezterm`
- **Browser override**: `$browser = brave --ozone-platform-hint=auto`
- **Cursor theme**: Breeze_Snow
- **Custom keybindings**: HJKL movement, personal app shortcuts
- **Touchpad**: Custom scroll speed (0.05)

### WezTerm Configuration
- **Wayland support**: `enable_wayland = true`
- **Theme**: Tokyo Night
- **Font size**: 14.0
- **Simple tabs**: `use_fancy_tab_bar = false`
- **No close confirmation**: `window_close_confirmation = 'NeverPrompt'`

## System Maintenance

### Updating Omarchy
```bash
omarchy-update
```
- Updates Omarchy codebase in `~/.local/share/omarchy/`
- Runs system package updates with `yay -Syu`
- Your dotfiles remain untouched due to clean separation

### Managing Dotfiles
```bash
# Navigate to dotfiles
cd ~/dotfiles

# Make changes to configs, then commit
git add .
git commit -m "description of changes"
git push

# Apply changes with stow (creates symlinks)
stow -t ~/.config config  # For .config files
stow zsh git              # For home directory files
```
- Use lowercase commit messages in the dotfiles repo
- Use single line commits only (no multiline commit messages)
- **Stow creates symlinks**: Files in `~/.config/` point to `~/dotfiles/config/`
- **Edit anywhere**: Changes to symlinked files automatically update dotfiles repo

### Package Management
- **Bare mode enabled**: `~/.local/state/omarchy/bare.mode` prevents future bloatware
- **Minimal app selection**: Kept only obsidian, spotify, typora, gnome-keyring
- **Standard Arch workflow**: Use `yay -S` for new packages, `yay -Rns` to remove

## Important Paths
- **Dotfiles repo**: `~/dotfiles/` (git-managed, stow-organized)
- **Omarchy defaults**: `~/.local/share/omarchy/` (hands-off, Omarchy-managed)
- **Personal configs**: `~/.config/` (symlinked via stow)
- **Omarchy state**: `~/.local/state/omarchy/` (bare.mode file)

## Development Workflow
- **Primary editor**: Neovim (LazyVim, Omarchy-configured)
- **Terminal multiplexing**: WezTerm tabs/panes (no tmux needed)
- **Git workflow**: Standard git with aliases (co, br, ci, st)
- **Package management**: yay for AUR packages

## Troubleshooting Notes
- **Omarchy conflicts**: Check `git status` in `~/.local/share/omarchy/` before/after updates
- **Stow issues**: Use `stow -D <package>` to unlink, fix issues, then `stow <package>` again
- **Config restoration**: All configs are in git - easy rollback if needed
- **Hyprland reload**: `Super+Escape` then "Relaunch" after config changes

## Commands Reference
```bash
# Stow management
stow -t ~/.config config     # Apply .config files
stow zsh git                 # Apply home directory files
stow -D config               # Remove config symlinks
stow -R config               # Restow config (remove + apply)

# System maintenance
omarchy-update               # Update Omarchy + system packages
yay -Syu                     # Update system packages only
yay -Rns <package>           # Remove package + dependencies + configs

# Dotfiles workflow
cd ~/dotfiles && git status  # Check dotfiles changes
git add . && git commit -m "msg" && git push  # Save changes (single line commits only)
```

## Agent Restrictions
- **NEVER use `sudo` commands** - This triggers password prompts and breaks the agent interface
- **Ask user to run sudo commands manually** if system-level changes are needed
- **Use `yay` instead of `pacman`** for package management when possible (no sudo required)
- **Keep notes succinct** - User prefers minimal additions to AGENTS.md

## Documentation Access
- **Omarchy Manual**: Available as desktop app "Omarchy Manual" (opens web version)
- **Local Omarchy docs**: `~/.local/share/omarchy/README.md`
- **Online manual**: https://manuals.omamix.org/2/the-omarchy-manual
- **Omarchy TUI**: Run `~/.local/share/omarchy/bin/omarchy` for interactive setup

## Notes for Future Sessions
- Omarchy provides the desktop environment foundation
- Personal customizations live in dotfiles repo
- Clean separation allows both systems to update independently
- Bare mode prevents future bloatware installations
- All important configs are version-controlled and portable
