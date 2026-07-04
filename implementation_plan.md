# Convoy Implementation Plan

Convoy is a collaborative travel application for iOS and Android built with Flutter and Firebase. It enables group travelers to coordinate itineraries, track real-time locations with privacy control, chat, share photo albums, and split expenses offline-resiliently.

To allow immediate visual and interactive verification of all screens (Screens 1 to 9) on your Macbook, we are introducing a **Phase 0 Interactive Web Prototype** that runs inside a high-fidelity mobile emulator wrapper in the browser.

## User Review Required

> [!IMPORTANT]
> - **Active Workspace Directory**: Please set `/Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy` as your active workspace in the IDE.
> - **Phase 0 Deliverable**: We will create a local web prototype in the folder `/Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy/prototype`. You can run it on your Macbook by opening `index.html` directly in Safari or Chrome, or by running a local HTTP server.
> - **Firebase Configuration**: Prior to Phase 1, we still require Firebase configuration setup and API keys for the production Flutter app.

## Open Questions

> [!NOTE]
> - **State Management**: Do you have a preferred state management solution for this Flutter app? We recommend **Provider** or **Riverpod** for structured state handling.
> - **Local Caching Database**: We can use **Hive** or **Isar** for lightweight, fast NoSQL local storage, or **sqflite** if you prefer relational querying. We recommend **Hive/Isar** for ease of syncing document-based Firestore structures.

## Proposed Changes

Proposed directory structure under `/Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy`:

```
convoy/
├── prototype/                # [NEW] Phase 0 Web-Based Interactive Mobile Simulator
│   ├── index.html            # Main markup with simulated phone iframe/shell
│   ├── styles.css            # Premium CSS styling (glassmorphism, dark mode theme)
│   └── app.js                # Core JS logic for screen routing & interactive states
├── android/                  # Native Android configuration & Fastlane setup
│   └── fastlane/
├── ios/                      # Native iOS configuration & Fastlane setup
│   └── fastlane/
├── .github/
│   └── workflows/            # GitHub Actions CI/CD workflows
├── lib/
│   ├── main.dart             # App entrypoint (supports environment flavors)
│   ├── models/               # Data models
│   │   ├── user_model.dart
│   │   ├── trip_model.dart
│   │   ├── expense_model.dart
│   │   ├── chat_model.dart
│   │   └── itinerary_model.dart
│   ├── services/             # Firebase, local database & analytics logic
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── location_service.dart
│   │   ├── sync_service.dart
│   │   ├── storage_service.dart
│   │   └── analytics_service.dart
│   ├── screens/              # UI Screens mapped to prototype designs
│   │   ├── auth/             # Login / Sign up screens
│   │   ├── dashboard/        # Screen 3: Landing Screen (Ready to Explore?)
│   │   ├── setup/            # Screen 2: Trip Setup Form
│   │   ├── map/              # Screen 1: Map Preview & Screen 4: Active tracking
│   │   ├── radar/            # Screen 5: Active Groups & Proximity Radar
│   │   ├── stats/            # Screen 6: Leaderboard & Stats
│   │   ├── timeline/         # Screens 7, 8, 9: Timeline Feed & Notifications
│   │   ├── chat/             # Shared group chat
│   │   └── expenses/         # Shared expense splitter UI
│   └── widgets/              # Reusable UI components (buttons, nav bars)
├── pubspec.yaml              # Project dependencies
└── functions/                # Firebase Cloud Functions (Node.js/TypeScript)
```

---

### Phase 0: Web-Based Interactive Mobile Simulator [NEW]
Builds a high-fidelity, single-page web simulator showing a mobile phone shell where you can click through and interact with all 9 design screens.
* **Deliverable Files:** `prototype/index.html`, `prototype/styles.css`, `prototype/app.js`.
* **Interactivity Included:**
  * Screen transitions (Landing -> Setup -> Live Map Setup -> Active tracking).
  * Tab switching (Explore, Groups, Timeline, Stats).
  * Active location speed-up simulation and dynamic distance changes.
  * Ghost Mode status update simulation.

---

### Phase 1: Flutter Project Setup, Auth, & Core Trip Setup
Initializes the project, configurations, authentication screens, and setup forms.
* **UI Prototypes Mapped:**
  * **Screen 3 (Landing Screen):** Home dashboard offering `"Create New Trip"` and `"Join Existing Group"`.
  * **Screen 2 (Trip Setup Form):** Fields for Trip Title (`Sierra Nevada Trip`), Date, Time, and Route dropdown.
  * **Screen 1 (Live Map Preview - Setup Phase):** Initial interactive map showing starting location before launching tracking.

#### [NEW] [pubspec.yaml](file:///Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy/pubspec.yaml)
- Define dependencies: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_analytics`, `mixpanel_flutter`, `firebase_crashlytics`, `firebase_performance`, `provider` or `flutter_riverpod`, and dev dependencies.

#### [NEW] [main.dart](file:///Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy/lib/main.dart)
- Initializes Firebase, Crashlytics, and Performance Monitoring. Routes to Login/Signup, or opens Dashboard if already authenticated. Handles environment configurations (Dev/Staging/Prod).

#### [NEW] [user_model.dart](file:///Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy/lib/models/user_model.dart)
- Defines User properties: `uid`, `email`, `displayName`, `photoUrl`.

#### [NEW] [trip_model.dart](file:///Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy/lib/models/trip_model.dart)
- Defines Trip properties: `id`, `name`, `inviteCode`, `members` (list of user IDs), `isGhostActive` (privacy settings).

#### [NEW] [auth_service.dart](file:///Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy/lib/services/auth_service.dart)
- Wraps Firebase Auth login, registration, and sign out workflows.

#### [NEW] [firestore_service.dart](file:///Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy/lib/services/firestore_service.dart)
- Handles user document creation, trip creation, and joining trips via invite codes.

---

### Phase 2: Live Map Tracking, Proximity Radar, & Ghost Mode Toggle
Implements background location tracking, customized map overlay markers, and proximity metrics.
* **UI Prototypes Mapped:**
  * **Screen 4 (Live Map Active Tracking):** Progress tracker displaying distance (`3.2 mi`), velocity indicator (`65 MPH`), and detailed member card (`Marcus Wright`, `4.1 miles back`).
  * **Screen 5 (Active Groups / Proximity Radar):** Sync progress radial gauge (`60%`), mesh network connector card, and radar scanner.
  * **Screen 6 (Trip Leaderboard & Statistics):** Ranks pathfinders, shows ETA/distances, and velocity-flow graphs.

#### [NEW] [location_service.dart](file:///Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy/lib/services/location_service.dart)
- Stream real-time location. Integrates foreground/background tracking while listening to the user's "Ghost Mode" preferences.

#### [NEW] [map_screen.dart](file:///Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy/lib/screens/map/map_screen.dart)
- Native Google Maps view displaying traveler markers with customized avatar overlays. Includes a quick access toggle for "Ghost Mode".

---

### Phase 3: Collaborative Chat & FCM
Provides instant communication for trip members.

#### [NEW] [chat_screen.dart](file:///Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy/lib/screens/chat/chat_screen.dart)
- Displays messages stream and inputs. Automatically retrieves chat history and updates in real-time.

---

### Phase 4: Expense Tracker & Offline Sync
Enables tracking trip expenses with Splitwise-style splits and local caching for offline usability.

#### [NEW] [sync_service.dart](file:///Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy/lib/services/sync_service.dart)
- Implements the SQLite/Hive local storage queue. Saves edits locally when offline, and pushes them sequentially to Firestore upon network recovery.

#### [NEW] [index.js](file:///Users/priteshkumar/.gemini/antigravity-ide/functions/index.js)
- Serverless Cloud Functions triggered by Firestore writes to perform net balance calculations (debt resolution algorithms) to minimize client-side computations.

---

### Phase 5: Daily Timeline & Itinerary Planner
Maintains chronological milestone logs, itineraries, and map routing optimizations.
* **UI Prototypes Mapped:**
  * **Screen 9 (Timeline - Empty State):** Standard dashboard warning that no active tracking journeys are running.
  * **Screen 7 (Trip Timeline):** Timeline list showing chronological waypoint notifications and interactive topographic previews.
  * **Screen 8 (Timeline History & Notifications):** Daily alerts (weather warnings, unplanned stops).

#### [NEW] [itinerary_screen.dart](file:///Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy/lib/screens/itinerary/itinerary_screen.dart)
- Displays scrollable timeline of daily trip stops. Integrates system map deep-linking for turn-by-turn navigation (e.g., Apple/Google Maps apps via URL Launcher) to minimize API cost.

---

### Phase 6: Shared Photo Album
Enables uploading and organizing travel memories together.

#### [NEW] [storage_service.dart](file:///Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy/lib/services/storage_service.dart)
- Connects to Firebase Cloud Storage, executing compression/resizing on images prior to upload to optimize bandwidth.

---

### Phase 7: Analytics, Logging, and CI/CD Pipelines
Setting up automated build pipelines, environment variables, crash reporting, and user tracking.

#### [NEW] [analytics_service.dart](file:///Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy/lib/services/analytics_service.dart)
- Centralized tracking interface for both Firebase Analytics and Mixpanel SDK. Maps analytics schemas like trip creation, chat sends, expense splits, and Ghost Mode switches.

#### [NEW] [Fastfile](file:///Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy/android/fastlane/Fastfile)
- Fastlane lanes for Android to automate Keystore decoding, version bumping, bundle building, and publishing to the Google Play Store (Internal Test track).

#### [NEW] [Fastfile](file:///Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy/ios/fastlane/Fastfile)
- Fastlane lanes for iOS using Match to sync certificates and profiles, compile the app, and release to TestFlight.

#### [NEW] [main.yml](file:///Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy/.github/workflows/main.yml)
- GitHub Actions CI workflow to run static analysis, tests, and invoke deployment lanes on push to development/staging/production branches.

---

### Phase 2 Product Release: Desktop Coordinator Website (Post-MVP)
* **UI Prototypes Mapped:**
  * **Screen 10 (Desktop Map Dashboard):** Map dashboard featuring waypoint alerts, broadcast controls, and multi-convoy node indicators.
  * **Screen 11 (Desktop Trip Summary Dashboard):** Cumulative metrics (fastest squad, average speed, travel duration, custom stops) and the final Arrival Leaderboard ranking.

---

## Verification Plan

### Automated Tests
We will verify operations through unit testing and validation scripts:
- **Auth & Service Tests**: Run `flutter test test/services/auth_service_test.dart` to verify successful login, registration, and logout states.
- **Offline Sync Queue Tests**: Run `flutter test test/services/sync_service_test.dart` to ensure offline caching stores queue data correctly and resumes sync on connection changes.
- **CI Lint & Tests**: Verify github workflow syntax by executing tests on PR triggers.

### Manual Verification
- **Web Simulator Interactions**: Run the local web server and verify all screens render correctly inside the phone bezel interface. Tap through the flows (Landing -> Setup Form -> Map Preview -> Active location tracking) and ensure tab controllers and state changes trigger as expected.
- **Multi-Device Live Geolocation**: Run the application concurrently on an iOS Simulator and Android Emulator to verify marker updates. Toggle "Ghost Mode" on one device and verify it transitions the status indicator and marker details on the other device.
- **Network Interruption Simulation**: Disable Wi-Fi/Cellular connectivity on the test device, submit multiple expenses, verify they persist locally, restore connection, and confirm they sync automatically to Firestore.
- **Analytics Event Validation**: Use Firebase Analytics DebugView and Mixpanel Live View to trigger and verify events (e.g. `trip_created`, `ghost_mode_toggled`, `expense_added`).
- **Crashlytics Triggering**: Add a debug crash trigger button to verify connection to Crashlytics dashboard.
