import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

/// Top-level background message handler for FCM.
/// Must be annotated with @pragma('vm:entry-point') to prevent tree-shaking.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling background FCM push notification: ${message.messageId}");
}

/// Provider definition for [FCMService] to integrate with Riverpod.
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService(
    FirebaseMessaging.instance,
    FirebaseFirestore.instance,
    ref,
  );
});

class FCMService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final Ref _ref;

  FCMService(this._messaging, this._firestore, this._ref);

  /// Initialize Firebase Messaging configurations.
  Future<void> initializeFCM() async {
    try {
      // 1. Request OS permissions for push notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Authorization Status: ${settings.authorizationStatus}');

      // 2. Fetch and register device token
      await _registerDeviceToken();

      // 3. Configure foreground listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground Notification Received: ${message.notification?.title}');
      });

      // 4. Configure background listener
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 5. Configure app open interactive action
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification App Opened Action: ${message.data}');
      });

    } catch (e) {
      debugPrint('FCM Initialization Skip (typical in simulator/sandbox context): $e');
    }
  }

  /// Fetch and update device FCM push token in Firestore profile database.
  Future<void> _registerDeviceToken() async {
    try {
      final user = _ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM Device Token Registered: $token');
      }
    } catch (e) {
      debugPrint('FCM Device Token Fetch Skip: $e');
    }
  }
}
