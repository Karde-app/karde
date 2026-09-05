# Release Signing Guide for Google Play Store

To publish Karde on the Google Play Store, you must sign the Android app with a release key. The debug key currently used for development is not accepted by the Play Store.

## Step 1: Generate a Keystore

Run the following command to generate a private key and keystore. Make sure to keep the generated `.jks` file secure and never commit it to source control.

**For Mac/Linux:**
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**For Windows:**
```bash
keytool -genkey -v -keystore c:\Users\USER_NAME\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

> [!WARNING]
> Remember the passwords you use during this process. If you lose the keystore or password, you won't be able to submit updates to your app.

## Step 2: Configure `key.properties`

Create a file named `key.properties` inside the `android/` directory (this file is ignored by git).

```properties
storePassword=<password from previous step>
keyPassword=<password from previous step>
keyAlias=upload
storeFile=<path to your keystore file>
```
*Example path for Windows:* `storeFile=C:\\Users\\USER_NAME\\upload-keystore.jks`

## Step 3: Update `build.gradle.kts`

Modify `android/app/build.gradle.kts` to use the `key.properties` file for the release build type:

```kotlin
// Load keystore
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

## Step 4: Build App Bundle

Build the Android App Bundle (AAB) for the Play Store with this exact command:

```bash
flutter build appbundle --obfuscate --split-debug-info=build/debug-info --extra-gen-snapshot-options=--strip
```

The resulting file is at `build/app/outputs/bundle/release/app-release.aab`. Upload it to
the Google Play Console.

### Why each flag matters

- `--obfuscate` renames Dart classes and methods in the shipped binary. Without it the
  release build ships readable Dart symbols — encryption channel names, the Keystore key
  alias, and the app's security logic are all trivially recoverable by decompiling the
  APK. Gradle's R8 minification only covers the Kotlin side; this covers Dart.
- `--split-debug-info` writes the symbol files that map obfuscated names back to real
  ones. **Keep them.** Without the symbol files for a given release you cannot read that
  release's crash reports.
- `--extra-gen-snapshot-options=--strip` removes DWARF debugging information from the
  compiled library. Omitting it produces the build warning "The generated ELF library
  contains unobfuscated DWARF debugging information", which means much of what
  `--obfuscate` was meant to hide is still readable.

> [!IMPORTANT]
> Archive the contents of `build/debug-info/` alongside each released build, tagged with
> the version number. These files are the only way to decode stack traces from that
> release, and they are regenerated (and therefore invalidated) on every build.

> [!WARNING]
> Do **not** pass `--dart-define=KARDE_ALLOW_SCREENSHOTS=true` to a build you intend to
> publish. That flag disables `FLAG_SECURE`, which is the app's screenshot and
> task-switcher protection. It exists only for development, defaults to off, and any
> build with it enabled shows a permanent red "SCREENSHOTS ON" banner.
