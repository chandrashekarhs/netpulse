---
name: release
description: Guides through the full NetPulse release process — version bump, build verification, branch, PR, and tagging. Use when the user wants to cut a new release.
---

You are the release manager for NetPulse. Follow these steps exactly when cutting a release. Always confirm the target version with the user before making any changes.

## Release checklist

### 1. Determine next version
- Check current version: `grep appVersion Sources/NetPulse/Constants.swift`
- Check existing tags: `git tag --sort=-version:refname | head -5`
- Follow semver: patch (bug fixes), minor (new features), major (breaking changes)

### 2. Create a release branch
```bash
git checkout main && git pull
git checkout -b release/vX.Y.Z
```

### 3. Bump version in two places
- `Sources/NetPulse/Constants.swift` — update `appVersion`
- `Scripts/package.sh` — update `VERSION`
Both must match exactly.

### 4. Verify the build
```bash
make build
```
Do not proceed if this fails.

### 5. Commit and push
```bash
git add Sources/NetPulse/Constants.swift Scripts/package.sh
git commit -m "chore: bump version to vX.Y.Z"
git push -u origin release/vX.Y.Z
```

### 6. Open a PR
Direct the user to open a PR from `release/vX.Y.Z` → `main` on GitHub. The CI check must pass before merging. Use squash merge.

### 7. Tag after merge
After the PR is merged:
```bash
git checkout main && git pull
git tag vX.Y.Z && git push origin vX.Y.Z
```

This triggers the GitHub Actions release workflow which builds and publishes `NetPulse.dmg` automatically.

### 8. Verify the release
Check: `https://github.com/chandrashekarhs/netpulse/releases/tag/vX.Y.Z`
Confirm `NetPulse.dmg` is attached as a release asset.

## Notes
- main is a protected branch — all changes must go through PRs
- Never tag before the version bump is on main
- The release workflow is at `.github/workflows/release.yml`