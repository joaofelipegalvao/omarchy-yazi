# Installation Guide

This document explains all installation methods for **Omarchy Yazi**.

## Requirements

- [Omarchy](https://omarchy.org) (version 3.1+)
- [Yazi](https://github.com/sxyazi/yazi)
- `git`

## Quick Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/joaofelipegalvao/omarchy-yazi/main/scripts/omarchy-yazi-install.sh | bash
```

## Security Tip: Always review scripts before running

```bash
git clone https://github.com/joaofelipegalvao/omarchy-yazi ~/.local/share/omarchy-yazi
bash ~/.local/share/omarchy-yazi/scripts/omarchy-yazi-install.sh
```

## Manual Installation

### 1. Install Dependencies

#### Arch Linux
```bash
sudo pacman -S yazi git
```

#### Other distributions
Follow [Yazi's installation guide](https://github.com/sxyazi/yazi#installation)

### 2. Clone the plugin

```bash
git clone https://github.com/joaofelipegalvao/omarchy-yazi ~/.local/share/omarchy-yazi
```

### 3. Run the installer

```bash
bash ~/.local/share/omarchy-yazi/scripts/omarchy-yazi-install.sh
```

The installer will:
- ✅ Check for Omarchy installation
- ✅ Copy theme configurations for all your themes
- ✅ Install the hook script
- ✅ Create initial symlink to current theme

### 4. Restart Yazi

If Yazi is running, restart it to see the theme:

```bash
killall yazi
yazi
```

## Installation Options

### Quiet Mode

Minimal output during installation:

```bash
bash ~/.local/share/omarchy-yazi/scripts/omarchy-yazi-install.sh --quiet
```

### Force Reinstall

Force reinstall even if already installed:

```bash
bash ~/.local/share/omarchy-yazi/scripts/omarchy-yazi-install.sh --force
```

### Show Version

```bash
bash ~/.local/share/omarchy-yazi/scripts/omarchy-yazi-install.sh --version
```

## Verify Installation

### Check plugin files

```bash
ls -la ~/.local/share/omarchy-yazi/
```

### Check theme configs

```bash
ls -la ~/.config/omarchy/themes/*/theme-yazi.toml
```

### Check hook installation

```bash
cat ~/.config/omarchy/hooks/theme-set
```

Should contain:
```bash
/home/YOUR_USERNAME/.local/bin/omarchy-yazi-hook $1
```

### Check active theme

```bash
ls -la ~/.config/yazi/theme.toml
```

Should be a symlink pointing to your current Omarchy theme.

## Post-Installation

### Test Theme Switching

1. Change Omarchy theme with `Super + Ctrl + Shift + Space`
2. Restart Yazi: `killall yazi && yazi`
3. Theme should match your new Omarchy theme

### Update the Plugin

To update to the latest version:

```bash
bash ~/.local/share/omarchy-yazi/scripts/omarchy-yazi-install.sh
```

The installer will pull the latest changes from GitHub if the directory contains a git repository.

## Uninstall

### Quick Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/joaofelipegalvao/omarchy-yazi/main/scripts/omarchy-yazi-uninstall.sh | bash
```

### Keep Theme Configs

To remove the plugin but keep your theme configurations:

```bash
bash ~/.local/share/omarchy-yazi/scripts/omarchy-yazi-uninstall.sh --keep-configs
```

### Force Uninstall (No Prompts)

```bash
bash ~/.local/share/omarchy-yazi/scripts/omarchy-yazi-uninstall.sh --force
```

## Troubleshooting

If installation fails, see [Troubleshooting Guide](TROUBLESHOOTING.md).

## What Gets Installed

The installer creates/modifies:

| Location | Purpose |
|----------|---------|
| `~/.local/share/omarchy-yazi/` | Plugin files and theme templates |
| `~/.config/omarchy/themes/*/theme-yazi.toml` | Theme configs for each theme |
| `~/.config/yazi/theme.toml` | Symlink to active theme |
| `~/.local/bin/omarchy-yazi-hook` | Hook script for theme switching |
| `~/.config/omarchy/hooks/theme-set` | Hook registration (modified) |

## Notes

- The plugin **does not modify** Omarchy's core files in `~/.local/share/omarchy`
- All configurations are in user-editable locations (`~/.config`)
- You can manually edit theme files in `~/.config/omarchy/themes/*/theme-yazi.toml`
- Backups are automatically created before replacing existing configs
