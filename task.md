# Convoy Development Tasks

## Phase 0: Web-Based Interactive Mobile Simulator [NEW]
- [x] Create `/prototype` directory inside the project workspace
- [x] Write `prototype/index.html` featuring phone device shell and mockup page layouts
- [x] Write `prototype/styles.css` with dark-themed premium styling and glassmorphic panels
- [x] Write `prototype/app.js` with responsive client-side routing, tab switching, and simulator state controls
- [x] Verify the prototype page runs smoothly on MacBook browsers (Chrome/Safari)

## Phase 1: Flutter Project Setup, Auth, & Core Trip Setup (Screens 1, 2, 3)
- [x] Initialize Flutter project in workspace directory (`/Users/priteshkumar/.gemini/antigravity-ide/scratch/convoy`)
- [x] Install package dependencies (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_analytics`, `mixpanel_flutter`, `firebase_performance`, `firebase_crashlytics`, `provider` or `flutter_riverpod`)
- [x] Setup flavor structures for multi-project Firebase configuration (dev, staging, production)
- [x] Implement user model and Authentication Service (`lib/services/auth_service.dart`)
- [x] Implement Firebase Firestore Service (`lib/services/firestore_service.dart`)
- [x] Build Authentication screens (Login, Registration)
- [x] Build Screen 3: Landing Dashboard View (Option for Create Trip / Join Group)
- [x] Build Screen 2: Trip Setup Form UI (Fields for Title, Date, Time, Route path selection)
- [x] Build Screen 1: Live Map Preview UI with custom location and overlay map controls

## Phase 2: Live Tracking, Proximity Radar, & Ghost Mode (Screens 4, 5, 6)
- [ ] Configure background location tracking permissions and setup Google Maps SDK configurations
- [ ] Implement Location Service (`lib/services/location_service.dart`)
- [ ] Design Screen 4: Active tracking map screen with progress bar, velocity tracker, and dynamic member panels
- [ ] Build custom Marker overlays with avatar graphics
- [ ] Design Screen 5: Proximity Radar and active groups view including sync progress gauges and radar scanning circle
- [ ] Design Screen 6: Trip Leaderboard and velocity graph views
- [ ] Implement Ghost Mode toggle logic updating `isGhostActive: true` and stopping location broadcast stream

## Phase 3: Collaborative Chat & FCM
- [ ] Design Firestore chat collection schema and message models
- [ ] Build Chat UI screen (`lib/screens/chat/chat_screen.dart`) with real-time stream subscription
- [ ] Configure Firebase Cloud Messaging (FCM) credentials and permissions
- [ ] Integrate background push notification receiver for immediate updates

## Phase 4: Expense Tracker & Offline Caching
- [ ] Build local database wrapper (SQLite or Hive) and model synchronization queue (`lib/services/sync_service.dart`)
- [ ] Implement network status detector to swap network/local target repositories
- [ ] Design Expense Tracker dashboard displaying total spendings and personal balance
- [ ] Construct Add Expense form with multi-member split checkboxes
- [ ] Create serverless Firebase Cloud Functions for net balance debt calculations

## Phase 5: Day-by-Day Timeline & Itinerary (Screens 7, 8, 9)
- [ ] Design Daily Itinerary schema supporting location references, timing, and travel details
- [ ] Build Screen 9: Timeline empty state UI dashboard
- [ ] Build Screen 7: Chronological milestone feed with topographic map preview cards
- [ ] Build Screen 8: Timeline history and yesterday's notification feed (weather warning, stopped alerts)
- [ ] Implement caching for itinerary distance/time metrics
- [ ] Integrate external map deep-linking URLs for navigation directions (Apple/Google Maps apps)

## Phase 6: Shared Photo Album
- [ ] Set up Firebase Cloud Storage bucket permissions and directories
- [ ] Implement storage utility service (`lib/services/storage_service.dart`) supporting image compression
- [ ] Build gallery UI view for collaborative trip photo stream and downloads

## Phase 7: Analytics, Logging, and CI/CD Integration
- [ ] Configure Firebase Analytics and Mixpanel SDK inside `lib/services/analytics_service.dart`
- [ ] Instrument analytics tracking across core app funnels: Trip creation, chat sends, expense splits, and Ghost Mode switches
- [ ] Configure Firebase Crashlytics to monitor uncaught native/Dart exceptions and Firebase Performance Monitoring for Maps API latency
- [ ] Set up Fastlane Match for iOS code-signing certificates and profiles synchronization
- [ ] Construct Android Keystore secrets and Fastlane lanes for automated bundle building
- [ ] Build GitHub Actions CI/CD workflows for automated build execution and deployment to Google Play Internal / TestFlight

## Deferred Phase 2 Product Release: Desktop Coordinator Website (Screens 10, 11)
- [ ] Setup web project module configuration
- [ ] Build Screen 10: Desktop Map Dashboard (Waypoints, convoy markers, map layers, broadcast triggers)
- [ ] Build Screen 11: Desktop Summary Dashboard (Avg speed, travel duration, arrival leaderboards, and share panel)
