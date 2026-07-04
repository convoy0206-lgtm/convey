# Tech Stack Rules

## Mobile
- Use Flutter (Dart) only.
- Follow Clean Architecture.
- Separate UI, Domain, and Data layers.
- Use Material 3 widgets.
- Keep widgets small and reusable.
- Support Android and iOS from a single codebase.

## State Management
- Use Riverpod as the primary state management solution.
- Use Bloc only for complex event-driven workflows.
- Never mix multiple state management solutions in the same feature.

## Background Location
- Use flutter_background_geolocation for all background tracking.
- Optimize for low battery consumption.
- Request runtime permissions before tracking.
- Handle foreground, background, and terminated app states.

## Local Storage
- Use Hive for caching and app settings.
- Use SQLite for structured relational offline data.
- Implement offline-first synchronization.
- Never store sensitive information in plain text.

## Backend
- Use Firebase Cloud Firestore as the primary database.
- Use Cloud Functions (Node.js) for server-side logic.
- Keep business logic inside Cloud Functions, not the client.
- Secure all Firestore collections with Security Rules.

## Authentication
- Use Firebase Authentication.
- Support:
  - Email/Password
  - Google Sign-In
  - Apple Sign-In (iOS)
- Never store passwords manually.

## File Storage
- Store images and media in Firebase Cloud Storage.
- Compress images before upload.
- Use secure Storage Rules.

## Notifications
- Use Firebase Cloud Messaging (FCM).
- Support:
  - Push notifications
  - Background notifications
  - Deep-link notifications

## Maps
- Use Google Maps SDK for Flutter.
- Use Google Directions API for routes.
- Use Google Distance Matrix API for ETA calculations.
- Use Google Places Autocomplete for location search.
- Cache route data when appropriate.

## Navigation
- Open external navigation using native Apple Maps (iOS) or Google Maps (Android).
- Use deep links when launching external navigation apps.

## Code Standards
- Use Dart null safety.
- Follow Effective Dart guidelines.
- Use feature-based folder structure.
- Keep business logic out of UI.
- Use dependency injection where applicable.
- Write reusable services and repositories.
- Use immutable models where possible.

## Error Handling
- Use centralized exception handling.
- Show user-friendly error messages.
- Log crashes using Firebase Crashlytics.

## Performance
- Minimize unnecessary widget rebuilds.
- Lazy load large datasets.
- Paginate Firestore queries.
- Optimize image loading and caching.

## Security
- Never hardcode API keys.
- Store secrets using environment variables or secure configuration.
- Validate all backend requests.
- Enforce Firebase Security Rules.

## Testing
- Write unit tests for business logic.
- Write widget tests for UI.
- Write integration tests for critical flows.

## Build & Release
- iOS:
  - Xcode
  - CocoaPods
  - TestFlight

- Android:
  - Android Studio
  - Gradle
  - Google Play Console

- Automate releases using Fastlane.

## API Rules
- Keep API calls inside repository classes.
- Use typed models.
- Handle retries and timeouts.
- Avoid duplicate network requests.

## Documentation
- Document every public class and method.
- Maintain a project README.
- Keep architecture diagrams updated.

## General Rules
- Prefer composition over inheritance.
- Keep code modular and scalable.
- Follow SOLID principles.
- Follow DRY and KISS principles.
- Build features that are production-ready, maintainable, and testable.
