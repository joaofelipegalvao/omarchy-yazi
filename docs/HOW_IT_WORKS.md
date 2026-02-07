# How It Works

Understanding how **Omarchy Yazi v2.0** integrates with your system using persistent theme profiles.

## Overview

Omarchy Yazi automatically updates Yazi's theme when you change your Omarchy theme, while preserving your per-theme customizations.

When Omarchy sets a new theme, it calls an installed hook which triggers a generator that creates (or reuses) a persistent theme profile and updates a symlink.

## Architecture v2.0: Persistent Profiles

### 1. Template Repository

Theme templates are stored in a git-managed repository:

```
~/.local/share/omarchy-yazi/
├── themes/
│   ├── tokyo-night/theme.toml       # Template (read-only)
│   ├── catppuccin-latte/theme.toml  # Template (read-only)
│   ├── hackerman/theme.toml         # Template (read-only)
│   └── ...
└── scripts/
```

**These are templates** - updates via `git pull` don't affect your customizations.

### 2. Persistent Theme Profiles

Your actual configurations live separately:

```
~/.config/yazi/omarchy-themes/
├── tokyo-night.toml       # YOUR customizations
├── catppuccin-latte.toml  # YOUR customizations
├── hackerman.toml         # YOUR customizations
└── ...
```

**These are yours** - edit freely, changes persist when you switch themes!

### 3. Active Theme Symlink

```bash
~/.config/yazi/theme.toml → omarchy-themes/tokyo-night.toml
```

The symlink always points to your current theme's persistent profile.

### 4. Generator Script

Located at `~/.local/bin/omarchy-yazi-generator`, this script:

1. Reads current theme from `~/.config/omarchy/current/theme.name`
2. Checks if profile exists in `~/.config/yazi/omarchy-themes/`
3. **If profile doesn't exist:** Copies from template repository
4. **If profile exists:** Skips (preserves your customizations!)
5. Updates symlink to point to the profile

### 5. Omarchy Hook

The installer registers `~/.local/bin/omarchy-yazi-reload` in `~/.config/omarchy/hooks/theme-set`.

When Omarchy switches themes, the reload script:

1. Calls the generator to create/update profile
2. Clears Yazi's state cache to force reload

## Seamless Integration

When you switch Omarchy themes (`Super + Ctrl + Shift + Space`):

- The hook instantly generates/updates the theme profile
- Yazi automatically picks up the new theme on next launch
- Running Yazi instances need to be restarted
- **Your customizations persist** when you switch back

## Theme Detection

The generator includes smart fallback for theme variants:

- Reads theme name from `~/.config/omarchy/current/theme.name` (Omarchy 3.3+)
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
│ Reload script executes:                                     │
│ ~/.local/bin/omarchy-yazi-reload                            │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ Generator script executes:                                  │
│ ~/.local/bin/omarchy-yazi-generator                         │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ Generator checks profile exists:                            │
│ ~/.config/yazi/omarchy-themes/<new-theme>.toml              │
│   • NO  → Copy from template                                │
│   • YES → Skip (preserve customizations!)                   │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ Generator updates symlink:                                  │
│ ~/.config/yazi/theme.toml → omarchy-themes/<theme>.toml     │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ Reload clears Yazi cache:                                   │
│ rm -rf ~/.local/state/yazi                                  │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ ✨ New theme applied on next Yazi launch                    │
│ ✨ Your customizations preserved                            │
└─────────────────────────────────────────────────────────────┘
```

## File Locations

| Purpose | Location |
|---------|----------|
| Template repository | `~/.local/share/omarchy-yazi/` |
| Theme templates | `~/.local/share/omarchy-yazi/themes/*/theme.toml` |
| **Your theme profiles** | **`~/.config/yazi/omarchy-themes/*.toml`** |
| Active theme symlink | `~/.config/yazi/theme.toml` |
| Generator script | `~/.local/bin/omarchy-yazi-generator` |
| Reload script | `~/.local/bin/omarchy-yazi-reload` |
| Hook registration | `~/.config/omarchy/hooks/theme-set` |
| Yazi cache | `~/.local/state/yazi` |

## Key Features

### Persistent Customizations (NEW in v2.0!)

The biggest change in v2.0: your theme customizations **never get lost**!

```bash
# Edit Tokyo Night
nvim ~/.config/yazi/omarchy-themes/tokyo-night.toml

# Switch to Hackerman
Super + Ctrl + Shift + Space

# ... days later, switch back to Tokyo Night ...
Super + Ctrl + Shift + Space

# Your customizations are STILL THERE! 🎉
```

### Safe Updates

```bash
# Update repository
cd ~/.local/share/omarchy-yazi
git pull

# Templates updated, but YOUR profiles untouched ✅
```

### Automatic Profile Creation

Profiles are created **on-demand** when you first switch to a theme:

- First time switching to `hackerman`: Profile created from template
- Second time: Profile already exists, customizations preserved
- Third time: Still using your customized profile

### Cache Clearing

The reload script clears Yazi's state cache to ensure the new theme is immediately recognized, avoiding stale color schemes.

## Customization Workflow

### Edit Your Theme Profile

```bash
# 1. Find current theme
current=$(cat ~/.config/omarchy/current/theme.name)

# 2. Edit profile
nvim ~/.config/yazi/omarchy-themes/$current.toml

# 3. Restart Yazi to see changes
killall yazi && yazi
```

### Reset to Default

```bash
# Remove your customized profile
rm ~/.config/yazi/omarchy-themes/tokyo-night.toml

# Switch away and back (or run generator)
~/.local/bin/omarchy-yazi-generator

# Fresh profile created from template
```

## Differences from v1.x

| Feature | v1.x | v2.0 |
|---------|------|------|
| **Profile location** | `~/.config/omarchy/themes/*/theme-yazi.toml` | `~/.config/yazi/omarchy-themes/*.toml` |
| **Customizations** | Lost on update | Persistent |
| **Template storage** | Mixed with configs | Separate in `~/.local/share/` |
| **Update safety** | Overwrites configs | Never touches profiles |
| **Theme detection** | Manual | Auto from `theme.name` |

## Why This Architecture?

### Separation of Concerns

- **Templates** (`~/.local/share/`) - Managed by git, updated safely
- **Your configs** (`~/.config/`) - Never touched by updates

### XDG Compliance

Following [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html):

- `~/.config/` - User-modifiable configuration
- `~/.local/share/` - Application data (read-only templates)

### Easy Backup

```bash
# Backup only YOUR customizations
tar -czf yazi-backup.tar.gz ~/.config/yazi/omarchy-themes/
```

### Predictable Updates

```bash
# Update templates
cd ~/.local/share/omarchy-yazi && git pull

# Your profiles untouched ✅
```
