# How It Works

Understanding how **Omarchy Yazi** integrates with your system.

## Overview

Omarchy Yazi automatically updates Yazi's theme when you change your Omarchy theme.

When Omarchy sets a new theme, it calls an installed hook which regenerates a persistent theme profile and updates a symlink to that profile.

## Architecture

### 1. Persistent Theme Profiles

Each theme has a persistent profile stored in Yazi's config directory:

```
~/.config/yazi/omarchy-themes/
├── tokyo-night.toml
├── catppuccin-latte.toml
└── ...
```

### 2. Theme Templates

The generator copies theme templates from the plugin repository into the persistent profiles (only if they don't already exist):

```bash
~/.local/share/omarchy-yazi/themes/tokyo-night/theme.toml
    ↓ (copied on first use)
~/.config/yazi/omarchy-themes/tokyo-night.toml
```

### 3. Omarchy Hook

The installer adds a hook script to `~/.local/bin/omarchy-yazi-hook` and registers it in `~/.config/omarchy/hooks/theme-set`.

When Omarchy switches themes, this hook:
1. Runs the generator (reads `~/.config/omarchy/current/theme.name`)
2. Ensures the persistent profile exists
3. Updates the symlink: `~/.config/yazi/theme.toml` → `~/.config/yazi/omarchy-themes/<theme>.toml`
4. Clears Yazi's state cache to force reload

### 4. Seamless Integration

When you switch Omarchy themes (`Super + Ctrl + Shift + Space`):
- The hook instantly updates the symlink
- Yazi automatically picks up the new theme on next launch
- Running Yazi instances need to be restarted

## Generated Files

### Per Theme

Each theme gets a persistent profile:

```bash
~/.config/yazi/omarchy-themes/tokyo-night.toml
~/.config/yazi/omarchy-themes/catppuccin-latte.toml
# ... for all installed themes
```

### Active Theme Symlink

```bash
~/.config/yazi/theme.toml → ~/.config/yazi/omarchy-themes/tokyo-night.toml
```

## Variant Detection

The generator includes smart fallback for theme variants:

- If Omarchy uses a theme name that isn't an exact match, it searches for a prefix match (e.g., `catppuccin*` or `tokyo-night*`).
- If no match is found, it falls back to `tokyo-night`.

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
│ Generator ensures profile exists:                           │
│ ~/.config/yazi/omarchy-themes/<new-theme>.toml              │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│  Hook updates symlink:                                      │
│  ~/.config/yazi/theme.toml →                                │
│    ~/.config/yazi/omarchy-themes/<new-theme>.toml           │
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
| Theme templates | `~/.local/share/omarchy-yazi/themes/` |
| Persistent profiles | `~/.config/yazi/omarchy-themes/` |
| Active theme symlink | `~/.config/yazi/theme.toml` |
| Hook script | `~/.local/bin/omarchy-yazi-hook` |
| Generator script | `~/.local/bin/omarchy-yazi-generator` |
| Hook registration | `~/.config/omarchy/hooks/theme-set` |
| Yazi cache | `~/.local/state/yazi` |

## Key Features

### Automatic Backup

Before creating the symlink, the generator automatically backs up any existing non-symlinked `theme.toml`:

```bash
~/.config/yazi/theme.toml.backup.20231104_230145
```

### Cache Clearing

The hook clears Yazi's state cache to ensure the new theme is immediately recognized, avoiding stale color schemes.

### Orphan Cleanup

Temporary `theme.toml-*` files are automatically cleaned up to prevent clutter in your config directory.
