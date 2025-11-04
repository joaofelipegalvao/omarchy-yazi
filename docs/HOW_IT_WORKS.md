# How It Works

Understanding how **Omarchy Yazi** integrates with your system.

## Overview

Omarchy Yazi automatically updates Yazi's theme when you change your Omarchy theme.

When Omarchy sets a new theme, it calls an installed hook which creates a symlink to the corresponding Yazi theme configuration.

## Architecture

### 1. Theme Directories

Each Omarchy theme directory contains a `theme-yazi.toml` file generated during installation:

```
~/.config/omarchy/themes/
├── tokyo-night/
│   └── theme-yazi.toml
├── catppuccin/
│   └── theme-yazi.toml
└── ...
```

### 2. Theme Files

The installer copies theme configurations from the plugin repository to each theme directory:

```bash
~/.local/share/omarchy-yazi/themes/tokyo-night/theme.toml
    ↓ (copied during installation)
~/.config/omarchy/themes/tokyo-night/theme-yazi.toml
```

### 3. Omarchy Hook

The installer adds a hook script to `~/.local/bin/omarchy-yazi-hook` and registers it in `~/.config/omarchy/hooks/theme-set`.

When Omarchy switches themes, this hook:
1. Creates a symlink: `~/.config/yazi/theme.toml` → `~/.config/omarchy/themes/<theme>/theme-yazi.toml`
2. Clears Yazi's state cache to force reload
3. Removes orphaned backup files

### 4. Seamless Integration

When you switch Omarchy themes (`Super + Ctrl + Shift + Space`):
- The hook instantly updates the symlink
- Yazi automatically picks up the new theme on next launch
- Running Yazi instances need to be restarted

## Generated Files

### Per Theme

Each theme gets a `theme-yazi.toml` file:

```bash
~/.config/omarchy/themes/tokyo-night/theme-yazi.toml
~/.config/omarchy/themes/catppuccin/theme-yazi.toml
# ... for all installed themes
```

### Active Theme Symlink

```bash
~/.config/yazi/theme.toml → ~/.config/omarchy/themes/tokyo-night/theme-yazi.toml
```

## Variant Detection

The installer includes smart fallback for theme variants:

- If you have `catppuccin` in Omarchy but only `catppuccin-macchiato` in the repository, it automatically uses the variant
- Works for themes like `tokyo-night*`, `catppuccin*`, `gruvbox*`, etc.

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│   User switches Omarchy theme (Super+Ctrl+Shift+Space)      │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│  Omarchy calls hooks:                                       │
│  ~/.config/omarchy/hooks/theme-set <new-theme>              │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ Hook script executes:                                       │
│ ~/.local/bin/omarchy-yazi-hook <new-theme>                  │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│  Hook updates symlink:                                      │
│  ~/.config/yazi/theme.toml →                                │
│    ~/.config/omarchy/themes/<new-theme>/theme-yazi.toml     │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│  Hook clears Yazi cache:                                    │
│  rm -rf ~/.local/state/yazi                                 │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│  ✨ New theme applied on next Yazi launch                   │
└─────────────────────────────────────────────────────────────┘
```

## File Locations

| Purpose | Location |
|---------|----------|
| Plugin repository | `~/.local/share/omarchy-yazi/` |
| Theme configs | `~/.config/omarchy/themes/*/theme-yazi.toml` |
| Active theme symlink | `~/.config/yazi/theme.toml` |
| Hook script | `~/.local/bin/omarchy-yazi-hook` |
| Hook registration | `~/.config/omarchy/hooks/theme-set` |
| Yazi cache | `~/.local/state/yazi` |

## Key Features

### Automatic Backup

Before creating the symlink, the hook automatically backs up any existing non-symlinked `theme.toml`:

```bash
~/.config/yazi/theme.toml.backup.20231104_230145
```

### Cache Clearing

The hook clears Yazi's state cache to ensure the new theme is immediately recognized, avoiding stale color schemes.

### Orphan Cleanup

Old backup files are automatically cleaned up to prevent clutter in your config directory.
