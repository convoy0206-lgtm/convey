# Firebase Multi-Project Flavor Setup

To support separate Firebase projects for development, staging, and production:

## Android (Automatic Resolution)
Place the respective `google-services.json` downloaded from the Firebase console into these directories:
1. **Development**: `android/app/src/dev/google-services.json`
2. **Staging**: `android/app/src/staging/google-services.json`
3. **Production**: `android/app/src/prod/google-services.json`

Gradle is configured to automatically pick up the correct file based on the selected build flavor (`flutter run --flavor dev`).

---

## iOS Configuration
Place the respective `GoogleService-Info.plist` files here:
1. **Development**: `ios/config/dev/GoogleService-Info.plist`
2. **Staging**: `ios/config/staging/GoogleService-Info.plist`
3. **Production**: `ios/config/prod/GoogleService-Info.plist`

During the build phase, Xcode runs a run script to copy the correct configuration file into the root of the app bundle based on the current scheme context.
