# Flutter + Appwrite Development Shell

Complete development environment for Flutter mobile/web apps with Appwrite backend integration.

## Included Tools

### Flutter Stack
- **Flutter** - Flutter SDK
- **Dart** - Dart programming language (included with Flutter)
- **Android SDK** - Android Platforms 34 & 35
- **Android Build Tools** - Version 34.0.0
- **Android NDK** - Native development kit
- **JDK 17** - Java Development Kit
- **Gradle** - Android build system
- **Android Tools** - adb, fastboot, etc.
- **Chromium** - For Flutter web development

### Appwrite & Backend
- **Node.js 20** - For Appwrite CLI and cloud functions
- **npm** - Node package manager
- **pnpm** - Fast alternative package manager

### Utilities
- **Git** - Version control

## Usage in a Project

1. Copy the `.envrc` file to your Flutter project root:
   ```bash
   cp ~/serenityOs/templates/flutter-appwrite/.envrc /path/to/your/flutter-project/
   ```

2. Allow direnv:
   ```bash
   cd /path/to/your/flutter-project
   direnv allow
   ```

## Create New Flutter + Appwrite Project

```bash
# Create Flutter app
flutter create my_appwrite_app
cd my_appwrite_app

# Set up dev environment
cp ~/serenityOs/templates/flutter-appwrite/.envrc .
direnv allow

# Install Appwrite CLI globally (one-time setup)
npm install -g appwrite-cli

# Login to Appwrite
appwrite login

# Initialize Appwrite in your project
appwrite init project

# Install Flutter Appwrite SDK
flutter pub add appwrite

# Get dependencies
flutter pub get

# Run the app
flutter run
```

## Appwrite CLI Commands

### Setup & Authentication
```bash
# Install Appwrite CLI globally (one-time)
npm install -g appwrite-cli

# Login to your Appwrite instance
appwrite login

# Initialize Appwrite project
appwrite init project
```

### Collections & Databases
```bash
# Initialize database collections
appwrite init collection

# List collections
appwrite databases listCollections --databaseId [DATABASE_ID]

# Create a new collection
appwrite databases createCollection \
  --databaseId [DATABASE_ID] \
  --collectionId [COLLECTION_ID] \
  --name "MyCollection"
```

### Functions (Cloud Functions)
```bash
# Initialize a new function
appwrite init function

# Deploy function
appwrite deploy function

# List functions
appwrite functions list
```

### Storage
```bash
# List buckets
appwrite storage listBuckets

# Create bucket
appwrite storage createBucket --bucketId [BUCKET_ID] --name "MyBucket"
```

## Flutter Development Commands

**Run on different platforms:**
```bash
flutter run                    # Run on connected device
flutter run -d chrome          # Run in Chrome (web)
flutter run -d linux           # Run on Linux desktop
flutter run -d android         # Run on Android device
```

**Device Management:**
```bash
adb devices                    # List connected Android devices
flutter devices                # List all available devices
flutter emulators              # List available emulators
```

**Dependencies:**
```bash
flutter pub get                # Install Flutter dependencies
flutter pub upgrade            # Upgrade dependencies
flutter pub add appwrite       # Add Appwrite SDK
flutter pub add [package]      # Add any package
```

**Build:**
```bash
flutter build apk              # Build APK for Android
flutter build appbundle        # Build App Bundle for Play Store
flutter build web              # Build web app
flutter clean                  # Clean build artifacts
```

## Project Structure Example

```
my_appwrite_app/
├── .envrc                     # direnv config (use this template)
├── lib/
│   ├── main.dart
│   ├── services/
│   │   └── appwrite_service.dart   # Appwrite initialization
│   └── models/
├── appwrite.json              # Appwrite configuration
├── functions/                 # Cloud functions (optional)
└── pubspec.yaml
```

## Example: Setting Up Appwrite in Flutter

**1. Install Appwrite SDK:**
```bash
flutter pub add appwrite
```

**2. Create Appwrite service (`lib/services/appwrite_service.dart`):**
```dart
import 'package:appwrite/appwrite.dart';

class AppwriteService {
  static const String endpoint = 'https://[YOUR_APPWRITE_ENDPOINT]';
  static const String projectId = '[YOUR_PROJECT_ID]';

  late Client client;
  late Account account;
  late Databases databases;
  late Storage storage;

  AppwriteService() {
    client = Client()
        .setEndpoint(endpoint)
        .setProject(projectId);

    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
  }
}
```

**3. Initialize in your app:**
```dart
void main() {
  final appwrite = AppwriteService();
  runApp(MyApp(appwrite: appwrite));
}
```

## Troubleshooting

### Appwrite CLI not found
```bash
# Install globally in this shell
npm install -g appwrite-cli

# Or use npx to run without installing
npx appwrite-cli login
```

### Android SDK licenses not accepted
The shell automatically accepts licenses on startup, but if you encounter issues:
```bash
yes | sdkmanager --licenses
```

### Flutter doctor issues
```bash
flutter doctor -v              # Detailed diagnostics
flutter doctor --android-licenses  # Accept Android licenses
```

### Gradle build errors
```bash
flutter clean
rm -rf ~/.gradle/caches
flutter pub get
flutter run
```

## Environment Variables

The shell automatically sets:
- `ANDROID_SDK_ROOT` - Path to Android SDK
- `JAVA_HOME` - Path to JDK 17
- `CHROME_EXECUTABLE` - Path to Chromium browser

You can add your own in `~/.bashrc`, `~/.zshrc`, or `~/.config/nushell/env.nu`:
```bash
export APPWRITE_ENDPOINT="https://cloud.appwrite.io/v1"
export APPWRITE_PROJECT_ID="your-project-id"
```

## Customization

To modify tools or versions, edit `~/serenityOs/templates/flutter-appwrite/default.nix`:

```nix
buildInputs = with pkgs; [
  flutter
  nodejs_20  # Change to nodejs_22 for newer version
  # Add more tools:
  postman
  insomnia
];
```

Then rebuild:
```bash
cd ~/serenityOs
git add templates/flutter-appwrite/default.nix
sudo nixos-rebuild switch --flake .
cd /path/to/project
direnv reload
```

## Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Appwrite Documentation](https://appwrite.io/docs)
- [Appwrite Flutter SDK](https://pub.dev/packages/appwrite)
- [Appwrite CLI Reference](https://appwrite.io/docs/command-line)

## Tips

1. **Use Appwrite Cloud Functions** for backend logic (Node.js available in this shell)
2. **Test on multiple platforms** - This shell supports Android, web, and Linux
3. **Commit `appwrite.json`** to version control for team collaboration
4. **Use environment variables** for sensitive data (Appwrite keys, endpoints)
5. **Set up Appwrite locally** using Docker for development (Docker template available)
