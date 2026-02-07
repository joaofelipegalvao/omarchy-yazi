# Troubleshooting

Common issues and fixes for **Omarchy Yazi**.

## 1. Theme not updating automatically

### Check if hook is installed

```bash
cat ~/.config/omarchy/hooks/theme-set
```

Should contain a line like:
```bash
/home/YOUR_USERNAME/.local/bin/omarchy-yazi-hook $1
```

### Verify hook script exists

```bash
ls -la ~/.local/bin/omarchy-yazi-hook
```

If missing, reinstall:
```bash
bash ~/.local/share/omarchy-yazi/scripts/omarchy-yazi-install.sh --force
```

### Test hook manually

```bash
~/.local/bin/omarchy-yazi-hook tokyo-night
```

Should output:
```
[omarchy-yazi] Cleared Yazi state cache
[omarchy-yazi] Theme sync complete
```

## 2. Theme file not found

### Error: "Theme file not found"

Check if theme config exists:
```bash
ls -la ~/.config/yazi/omarchy-themes/YOUR_THEME.toml
```

If missing, regenerate theme configs:
```bash
bash ~/.local/share/omarchy-yazi/scripts/omarchy-yazi-install.sh --force
```

### Check available themes

```bash
ls ~/.local/share/omarchy-yazi/themes/
```

If your theme variant is missing from the repository, the generator should use a fallback variant automatically.

## 3. Yazi not picking up theme

### Clear Yazi cache manually

```bash
rm -rf ~/.local/state/yazi
```

### Restart Yazi

Kill all running instances:
```bash
killall yazi
```

Then launch Yazi again:
```bash
yazi
```

### Verify symlink

```bash
ls -la ~/.config/yazi/theme.toml
```

Should be a symlink (indicated by `->`) pointing to:
```
~/.config/yazi/omarchy-themes/YOUR_THEME.toml
```

If it's a regular file, remove it and let the hook recreate it:
```bash
rm ~/.config/yazi/theme.toml
~/.local/bin/omarchy-yazi-hook YOUR_THEME
```

## 4. Installation errors

### Error: "Omarchy not found"

Make sure Omarchy is installed:
```bash
ls -la ~/.config/omarchy/
```

Install from: https://omarchy.org

### Error: "Theme name file not found"

Update Omarchy to version 3.3 or later. The `~/.config/omarchy/current/theme.name` file was introduced in this version.

### Error: "No Yazi theme found for: THEME_NAME"

This means your theme doesn't have a corresponding Yazi theme in the repository. The generator should automatically use a variant if available.

Check if a variant exists:
```bash
ls ~/.local/share/omarchy-yazi/themes/ | grep YOUR_THEME
```

## 5. Permission issues

### Hook script not executable

```bash
chmod +x ~/.local/bin/omarchy-yazi-hook
```

### Cannot write to config directories

Make sure you own the config directories:
```bash
ls -la ~/.config/omarchy/
ls -la ~/.config/yazi/
```

Fix ownership if needed:
```bash
sudo chown -R $USER:$USER ~/.config/omarchy/
sudo chown -R $USER:$USER ~/.config/yazi/
```

## 6. Theme looks incorrect

### Colors not matching Omarchy

1. Verify you're using the correct theme:
```bash
readlink ~/.config/yazi/theme.toml
```

2. Check Omarchy's current theme:
```bash
cat ~/.config/omarchy/current/theme.name
```

3. Manually switch to correct theme:
```bash
~/.local/bin/omarchy-yazi-hook CORRECT_THEME_NAME
```

### Theme file corrupted

Regenerate theme configs:
```bash
bash ~/.local/share/omarchy-yazi/scripts/omarchy-yazi-install.sh --force
```

## 7. Multiple Yazi instances

If you have multiple Yazi instances running, they may not all update immediately:

```bash
# Kill all Yazi instances
killall yazi

# Launch fresh instance
yazi
```

## 8. Backup files accumulating

Old backup files can be safely removed:

```bash
rm ~/.config/yazi/theme.toml.backup.*
```

These backups are not automatically cleaned, so you can remove them manually if needed.

## Getting Help

If issues persist, open a [GitHub Issue](https://github.com/joaofelipegalvao/omarchy-yazi/issues) with:

### System Information
```bash
# Operating system
uname -a

# Yazi version
yazi --version

# Omarchy version
cat ~/.local/share/omarchy/version 2>/dev/null || echo "Unknown"
```

### Configuration Status
```bash
# Current theme symlink
ls -la ~/.config/yazi/theme.toml

# Current Omarchy theme
cat ~/.config/omarchy/current/theme.name

# Hook installation
cat ~/.config/omarchy/hooks/theme-set

# Available theme configs
ls -la ~/.config/yazi/omarchy-themes
```

### Hook Test
```bash
# Test hook manually (replace with your theme)
~/.local/bin/omarchy-yazi-hook tokyo-night
```

Include all this information in your issue report for faster assistance!
