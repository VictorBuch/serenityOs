# Flutter + Appwrite Development Template

Complete Flutter development environment with Appwrite backend integration.

## What's Included

Everything from the [Flutter template](../flutter/README.md) plus:

- **Node.js 20** - For Appwrite CLI
- **Appwrite CLI** - Auto-installed on first shell entry
- **pnpm** - Package managers for Appwrite CLI
- **Additional scripts** - Appwrite workflow helpers

## Quick Start

```bash
# Create a new Flutter app
flutter create my_appwrite_app
cd my_appwrite_app

# Copy this template
cp -r ~/serenityOs/devshells/flutter-appwrite/* .

# Allow direnv
direnv allow

# Appwrite CLI is automatically installed!
# Verify setup
doctor
appwrite-login
```

## Available Scripts

### Flutter Scripts

- **`doctor`** - Run `flutter doctor -v`
- **`devices`** - List available devices
- **`clean`** - Clean and get dependencies
- **`run-android`** - Run on Android device
- **`run-web`** - Run in Chrome
- **`analyze`** - Analyze Dart code

### Appwrite Scripts

- **`appwrite-login`** - Login to Appwrite Cloud or self-hosted
- **`appwrite-deploy`** - Deploy Appwrite functions

## Appwrite CLI Commands

The full Appwrite CLI is available:

```bash
# Initialize Appwrite in your project
appwrite init tabels
appwrite init function

# Deploy functions
appwrite deploy function

# Manage your Appwrite project
appwrite databases list
appwrite storage list
appwrite functions list
```

## Typical Workflow

1. **Create Flutter app and copy template**

   ```bash
   flutter create my_app
   cd my_app
   cp -r ~/serenityOs/devshells/flutter-appwrite/* .
   direnv allow
   ```

2. **Login to Appwrite**

   ```bash
   appwrite-login
   # Follow prompts to login
   ```

3. **Initialize Appwrite**

   ```bash
   appwrite init project
   appwrite init tabel
   ```

4. **Add Appwrite Flutter SDK**

   ```bash
   flutter pub add appwrite
   ```

5. **Develop and deploy**

   ```bash
   # Develop your Flutter app
   flutter run

   # Deploy Appwrite functions
   appwrite-deploy
   ```

## Environment Setup

### Appwrite CLI Installation

The Appwrite CLI is automatically installed on first shell entry via npm global installation. It's installed to `~/.npm-global/bin/` which is added to your PATH.

If you need to reinstall:

```bash
npm install -g appwrite-cli
```

## Troubleshooting

**Appwrite CLI not found?**

```bash
# Reinstall manually
npm install -g appwrite-cli

# Or reload shell
direnv reload
```

**Can't login to Appwrite?**

- Make sure you have an account at https://cloud.appwrite.io
- Or configure for self-hosted: `appwrite client --endpoint https://your-appwrite-server/v1`

**Flutter + Appwrite integration issues?**

- Check Appwrite Flutter SDK docs: https://appwrite.io/docs/sdks#flutter
- Verify your Appwrite project ID and endpoint

## Resources

- **Appwrite Documentation**: https://appwrite.io/docs
- **Appwrite Flutter SDK**: https://appwrite.io/docs/sdks#flutter
- **Flutter Documentation**: https://flutter.dev/docs
- **Appwrite CLI Reference**: https://appwrite.io/docs/command-line
