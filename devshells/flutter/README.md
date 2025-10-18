# Flutter + Android Development Shell

Complete Flutter development environment with Android SDK, tools, and web support.

## Included Tools

- **Flutter** - Flutter SDK
- **Dart** - Dart programming language (included with Flutter)
- **Android SDK** - Android Platform 34 (Android 14)
- **Android Build Tools** - Version 34.0.0
- **Android NDK** - Native development kit
- **JDK 17** - Java Development Kit
- **Gradle** - Android build system
- **Android Tools** - adb, fastboot, etc.
- **Chromium** - For Flutter web development
- **Git** - Version control

## Usage in a Project

1. Copy the `.envrc` file to your Flutter project root:
   ```bash
   cp ~/serenityOs/templates/flutter/.envrc /path/to/your/flutter-project/
   ```

2. Allow direnv:
   ```bash
   cd /path/to/your/flutter-project
   direnv allow
   ```

## Create New Flutter Project

```bash
flutter create my_awesome_app
cd my_awesome_app
cp ~/serenityOs/templates/flutter/.envrc .
direnv allow
flutter pub get
flutter run
```

## Common Commands

**Development:**
```bash
flutter run                    # Run on connected device
flutter run -d chrome          # Run in Chrome (web)
flutter run -d linux           # Run on Linux desktop
flutter hot-reload            # Hot reload changes
```

**Device Management:**
```bash
adb devices                    # List connected devices
flutter devices                # List available devices
flutter emulators              # List available emulators
```

**Project Management:**
```bash
flutter pub get                # Install dependencies
flutter pub upgrade            # Upgrade dependencies
flutter clean                  # Clean build artifacts
flutter doctor                 # Check environment setup
```

**Build:**
```bash
flutter build apk              # Build APK
flutter build appbundle        # Build App Bundle for Play Store
flutter build web              # Build web app
```

## Troubleshooting

**Android SDK licenses not accepted:**
The shell automatically accepts licenses on startup, but if you encounter issues:
```bash
yes | sdkmanager --licenses
```

**Gradle issues:**
```bash
flutter clean
rm -rf ~/.gradle/caches
flutter pub get
```

**Check environment:**
```bash
flutter doctor -v
```

## Customization

To change Android SDK versions or add/remove tools, edit `~/serenityOs/templates/flutter/default.nix`:

```nix
platformVersions = [ "34" "33" ];  # Add multiple versions
buildToolsVersions = [ "34.0.0" "33.0.0" ];
includeEmulator = true;  # Enable Android emulator
```

Then rebuild:
```bash
cd ~/serenityOs
sudo nixos-rebuild switch --flake .
```
