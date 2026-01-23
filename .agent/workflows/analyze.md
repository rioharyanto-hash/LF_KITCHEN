# Analyze and fix workflow for LF Kitchen Flutter project
---
description: Run flutter analyze and fix common issues
---

## Quick Check
// turbo
1. Run flutter analyze to check for issues:
```powershell
flutter analyze
```

## Auto-fix Issues
// turbo
2. Run dart fix to auto-fix common issues:
```powershell
dart fix --apply
```

## Organize Imports
// turbo
3. Sort and remove unused imports (via IDE or manually):
- VS Code: Ctrl+Shift+O on each file
- Or use: `dart format .`

## Common Manual Fixes

### Deprecated `withOpacity()`
```dart
# Before (deprecated)
color.withOpacity(0.5)

# After
color.withValues(alpha: 0.5)
```

### `use_build_context_synchronously`
```dart
# Before
await someAsyncCall();
Navigator.pop(context);  // Warning!

# After
await someAsyncCall();
if (context.mounted) {
  Navigator.pop(context);
}
```

### `curly_braces_in_flow_control_structures`
```dart
# Before
if (condition) return 0;

# After
if (condition) {
  return 0;
}
```

## Install Pre-commit Hook
// turbo
4. Install the pre-commit hook to prevent issues from being committed:
```powershell
.\scripts\install-hooks.ps1
```
