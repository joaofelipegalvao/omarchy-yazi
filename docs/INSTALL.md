# Installation Guide

This document explains all installation methods for **Omarchy Yazi v2.0**.

## Requirements

- [Omarchy](https://omarchy.org) (version 3.3+ recommended, 3.1+ minimum)
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

### 2. Clone the repository

```bash
git clone https://github.com/joaofelipegalvao/omarchy-yazi ~/.local/share/omarchy-yazi
```

### 3. Run the installer

```bash
bash ~/.local/share/omarchy-yazi/scripts/omarchy-yazi-install.sh
```

The installer will:

- ✅ Check for Omarchy installation (3.3+ required)
- ✅ Clone/update theme template repository
- ✅ Create generator and reload scripts
- ✅ Generate profile for your current theme
- ✅ Install Omarchy hook
- ✅ Create symlink to active theme

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

Force reinstall even if already installed (regenerates scripts, preserves profiles):

```bash
bash ~/.local/share/omarchy-yazi/scripts/omarchy-yazi-install.sh --force
```

### Show Version

```bash
bash ~/.local/share/omarchy-yazi/scripts/omarchy-yazi-install.sh --version
```

## Verify Installation

### Check template repository

```bash
ls -la ~/.local/share/omarchy-yazi/
```

Should show:

```
drwxr-xr-x themes/
drwxr-xr-x scripts/
drwxr-xr-x .git/
```

### Check generator script

```bash
ls -la ~/.local/bin/omarchy-yazi-generator
```

Should be executable.

### Check reload script

```bash
ls -la ~/.local/bin/omarchy-yazi-reload
```

Should be executable.

### Check hook installation

```bash
cat ~/.config/omarchy/hooks/theme-set
```

Should contain:

```bash
/home/YOUR_USERNAME/.local/bin/omarchy-yazi-reload
```

### Check active theme

```bash
ls -la ~/.config/yazi/theme.toml
```

Should be a symlink pointing to `~/.config/yazi/omarchy-themes/THEME.toml`

### Check theme profile

```bash
# Get current theme
current_theme=$(cat ~/.config/omarchy/current/theme.name 2>/dev/null || echo "unknown")

# Check profile exists
ls -la ~/.config/yazi/omarchy-themes/$current_theme.toml
```

## Post-Installation

### Test Theme Switching

1. Change Omarchy theme with `Super + Ctrl + Shift + Space`
2. Check symlink updated: `readlink ~/.config/yazi/theme.toml`
3. Restart Yazi: `killall yazi && yazi`
4. Theme should match your new Omarchy theme

### Customize Your Theme

```bash
# Get current theme
current_theme=$(cat ~/.config/omarchy/current/theme.name)

# Edit your persistent profile
nvim ~/.config/yazi/omarchy-themes/$current_theme.toml

# Restart Yazi
killall yazi && yazi
```

**Your customizations will persist when you switch themes and return!**

### Update the Repository

To update to the latest version:

```bash
bash ~/.local/share/omarchy-yazi/scripts/omarchy-yazi-install.sh
```

The installer will:

- Pull latest theme templates from GitHub
- Update generator and reload scripts
- **Never touch your existing profiles** - customizations safe!

## Uninstall

### Quick Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/joaofelipegalvao/omarchy-yazi/main/scripts/omarchy-yazi-uninstall.sh | bash
```

### Keep Theme Profiles

To remove the repository but keep your customized theme profiles:

```bash
bash ~/.local/share/omarchy-yazi/scripts/omarchy-yazi-uninstall.sh --keep-configs
```

Your profiles remain in `~/.config/yazi/omarchy-themes/` for future reinstall.

### Force Uninstall (No Prompts)

```bash
bash ~/.local/share/omarchy-yazi/scripts/omarchy-yazi-uninstall.sh --force
```

## Troubleshooting

If installation fails, see [Troubleshooting Guide](TROUBLESHOOTING.md).

## What Gets Installed

The installer creates/modifies:

| Location | Purpose | Editable? |
|----------|---------|-----------|
| `~/.local/share/omarchy-yazi/` | Template repository (git) | No |
| `~/.local/share/omarchy-yazi/themes/` | Theme templates | No |
| **`~/.config/yazi/omarchy-themes/`** | **Your persistent profiles** | **Yes!** |
| `~/.config/yazi/theme.toml` | Symlink to active profile | Auto |
| `~/.local/bin/omarchy-yazi-generator` | Profile generator script | No |
| `~/.local/bin/omarchy-yazi-reload` | Reload script | No |
| `~/.config/omarchy/hooks/theme-set` | Hook registration (modified) | No |

## v2.0 Architecture

### Directory Structure

```
~/.local/share/omarchy-yazi/         # Template repository
├── themes/
│   ├── tokyo-night/theme.toml       # Read-only template
│   └── ...
└── scripts/

~/.config/yazi/
├── omarchy-themes/                  # Your persistent profiles
│   ├── tokyo-night.toml             # EDITABLE - Your customizations
│   └── ...
└── theme.toml → omarchy-themes/tokyo-night.toml  # Symlink

~/.local/bin/
├── omarchy-yazi-generator           # Creates profiles on-demand
└── omarchy-yazi-reload              # Called by Omarchy hook
```

### Key Difference from v1.x

**v1.x**: Themes in `~/.config/omarchy/themes/*/theme-yazi.toml` - lost on update ❌

**v2.0**: Themes in `~/.config/yazi/omarchy-themes/*.toml` - persistent! ✅

## Notes

- The repository **does not modify** Omarchy's core files in `~/.local/share/omarchy`
- All configurations are in user-editable locations (`~/.config`)
- You can manually edit theme profiles in `~/.config/yazi/omarchy-themes/*.toml`
- Your customizations **persist across theme switches** and **survive repository updates**
- Updates only refresh templates in `~/.local/share/omarchy-yazi/themes/`
