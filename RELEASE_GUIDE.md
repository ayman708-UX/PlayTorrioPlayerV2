# PlayTorrio Release Guide

This guide explains how to create automated releases using GitHub Actions.

## Automatic Release (Recommended)

The GitHub Actions workflow automatically builds portable executables for all desktop platforms and creates a release.

### Method 1: Create a Git Tag (Automatic)

1. Update version in `pubspec.yaml`:
   ```yaml
   version: 1.8.13  # Increment version
   ```

2. Commit and push:
   ```bash
   git add pubspec.yaml
   git commit -m "Bump version to 1.8.13"
   git push
   ```

3. Create and push a version tag:
   ```bash
   git tag v1.8.13
   git push origin v1.8.13
   ```

4. GitHub Actions will automatically:
   - Build Windows (x64)
   - Build macOS (Universal: Intel + Apple Silicon)
   - Build Linux (x64)
   - Create a GitHub Release with all artifacts
   - Attach portable builds as downloadable assets

### Method 2: Manual Trigger

1. Go to your GitHub repository
2. Click **Actions** tab
3. Select **Release Desktop Builds** workflow
4. Click **Run workflow** button
5. Select branch and click **Run workflow**

## Release Artifacts

The workflow creates three portable builds:

### Windows
- **File**: `PlayTorrio-Windows-x64.zip`
- **Contents**: Complete Release folder with `PlayTorrio.exe` and dependencies
- **Usage**: Extract and run `PlayTorrio.exe`

### macOS
- **File**: `PlayTorrio-macOS-Universal.zip`
- **Contents**: `PlayTorrio.app` bundle (Universal binary)
- **Usage**: Extract and run `PlayTorrio.app`
- **Architectures**: Intel (x86_64) + Apple Silicon (arm64)

### Linux
- **File**: `PlayTorrio-Linux-x64.tar.gz`
- **Contents**: Complete bundle folder with executable and dependencies
- **Usage**: Extract and run `bundle/playtorrio`

## Downloading Releases

After the workflow completes:

1. Go to your repository's **Releases** page
2. Find the latest release (e.g., "PlayTorrio 1.8.13")
3. Download the appropriate file for your platform
4. Extract and use

## For Electron Integration

Download the release artifacts and bundle them with your Electron app:

```
your-electron-app/
├── player/
│   ├── windows/
│   │   └── (extracted from PlayTorrio-Windows-x64.zip)
│   ├── macos/
│   │   └── PlayTorrio.app/
│   └── linux/
│       └── bundle/
```

## Versioning

Follow semantic versioning (MAJOR.MINOR.PATCH):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

Example tags:
- `v1.8.13` - Patch release
- `v1.9.0` - Minor release with new features
- `v2.0.0` - Major release with breaking changes

## Workflow Details

The workflow (`.github/workflows/release-desktop.yml`) runs on:
- **Trigger**: Push tags matching `v*.*.*` (e.g., v1.8.13)
- **Manual**: Via GitHub Actions "Run workflow" button
- **Runners**: 
  - Windows: `windows-latest`
  - macOS: `macos-latest` (builds universal binary)
  - Linux: `ubuntu-latest`

## Troubleshooting

### Build Fails
- Check the Actions tab for error logs
- Ensure `pubspec.yaml` dependencies are correct
- Verify Flutter version compatibility

### Release Not Created
- Ensure you have write permissions to the repository
- Check that `GITHUB_TOKEN` has proper permissions
- Verify tag format matches `v*.*.*`

### macOS Build Issues
- Universal builds are automatic in recent Flutter versions
- If issues occur, check Flutter version (3.0+)

## Testing Before Release

Test locally before creating a release:

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## Quick Release Checklist

- [ ] Update version in `pubspec.yaml`
- [ ] Test builds locally (optional)
- [ ] Commit changes
- [ ] Create and push version tag
- [ ] Wait for GitHub Actions to complete
- [ ] Verify release artifacts
- [ ] Test downloaded builds
- [ ] Update release notes if needed

## Example: Creating v1.8.13 Release

```bash
# 1. Update version
# Edit pubspec.yaml: version: 1.8.13

# 2. Commit
git add pubspec.yaml
git commit -m "Release v1.8.13"
git push

# 3. Tag and push
git tag v1.8.13
git push origin v1.8.13

# 4. Wait for GitHub Actions (check Actions tab)
# 5. Download from Releases page
```

That's it! GitHub Actions handles the rest.
