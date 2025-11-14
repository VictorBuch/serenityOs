# Flutter Development Template

Complete Flutter development environment with Android SDK, Dart, and all necessary tools.

## What's Included

- **Flutter SDK** - Latest stable Flutter
- **Android SDK** - Platforms 34, 35, and latest
- **Android NDK** - Native development kit
- **JDK 17** - Java Development Kit
- **Gradle** - Android build tool
- **Android tools** - adb, fastboot, etc.
- **Chromium** - For Flutter web development
- **Git hooks** - Dart format runs on commit
- **Custom scripts** - Flutter workflow helpers

## Quick Start

```bash
# Create a new Flutter app
flutter create my_flutter_app
cd my_flutter_app

# Copy this template
cp -r ~/serenityOs/devshells/flutter/* .

# Allow direnv
direnv allow

# Verify setup
doctor

# Run your app
flutter run
```

## Available Scripts

- **`doctor`** - Run `flutter doctor -v` to check installation
- **`devices`** - List available devices and connected Android devices
- **`clean`** - Clean and get dependencies
- **`run-android`** - Run on Android device
- **`run-web`** - Run in Chrome browser
- **`analyze`** - Analyze Dart code

## Environment Variables

The template automatically sets:

- **`ANDROID_SDK_ROOT`** - Android SDK location
- **`JAVA_HOME`** - Java installation path
- **`CHROME_EXECUTABLE`** - Chromium browser for Flutter web

## Git Hooks

Dart format automatically runs on commit for all `.dart` files.

## First Time Setup

When you first enter the environment:

1. Accept Android SDK licenses (done automatically)
2. Flutter configures Android SDK path (done automatically)
3. Run `doctor` to verify everything works
4. Connect a device or start an emulator
5. Run your app with `flutter run`

## Customization

### Add iOS Support (macOS only)

```nix
{ pkgs, ... }:

{
  # ... existing config ...

  packages = with pkgs; [
    # Add iOS tools (macOS only)
    cocoapods
    xcodeWrapper
  ];
}
```

### Add More Flutter Tools

```nix
{ pkgs, ... }:

{
  # ... existing config ...

  scripts = {
    # Add custom scripts
    ios.exec = ''
      flutter run -d ios
    '';

    release.exec = ''
      flutter build apk --release
    '';
  };
}
```

## Troubleshooting

**Android licenses not accepted?**
```bash
devenv shell
# Licenses are accepted automatically on shell entry
```

**Flutter doctor shows issues?**
- Run `doctor` script to see detailed diagnostics
- Most issues are auto-configured by the template

**No devices found?**
```bash
# List devices
devices

# Check ADB
adb devices

# For emulator, you need to enable it in devenv.nix:
# android.emulator.enable = true;
```

**Gradle issues?**
- The template sets a temporary Gradle cache to avoid Nix store writes
- This is normal and prevents errors

## Platform Support

- ✅ **Android** - Fully supported with SDK platforms 34, 35
- ✅ **Web** - Chromium included for web development
- ⚠️ **iOS** - Requires macOS and additional setup
- ⚠️ **Desktop** - May require additional platform-specific packages
