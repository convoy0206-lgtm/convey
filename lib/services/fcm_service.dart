import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart' show firebaseAvailable;
import 'auth_service.dart';

/// Top-level background message handler for FCM.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling background FCM push notification: ${message.messageId}");
}

/// Provider definition for [FCMService] to integrate with Riverpod.
final fcmServiceProvider = Provider<FCMService>((ref) {
  if (!firebaseAvailable) {
    return FCMService(null, null, ref);
  }
  try {
    return FCMService(
      FirebaseMessaging.instance,
      FirebaseFirestore.instance,
      ref,
    );
  } catch (e) {
    debugPrint("FCM provider init error, falling back to mock: $e");
    return FCMService(null, null, ref);
  }
});

class FCMService {
  final FirebaseMessaging? _messaging;
  final FirebaseFirestore? _firestore;
  final Ref _ref;

  FCMService(this._messaging, this._firestore, this._ref);

  /// Initialize Firebase Messaging configurations.
  Future<void> initializeFCM() async {
    if (_messaging == null) {
      debugPrint("FCM skipped: Firebase not available in mock mode.");
      return;
    }

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint("FCM User granted permission.");
        
        final token = await _messaging.getToken();
        if (token != null) {
          await _registerDeviceToken(token);
        }

        _messaging.onTokenRefresh.listen((newToken) async {
          await _registerDeviceToken(newToken);
        });

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint("FCM Foreground notification received: ${message.notification?.title}");
        });

        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      } else {
        debugPrint("FCM Push notification permissions denied by user.");
      }
    } catch (e) {
      debugPrint("FCM Initialization Error: $e");
    }
  }

  /// Register current device token to user's profile metadata.
  Future<void> _registerDeviceToken(String token) async {
    if (_firestore == null) return;
    try {
      final user = _ref.read(authServiceProvider).currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set({'fcmToken': token}, SetOptions(merge: true));
        debugPrint("FCM Device token registered successfully.");
      }
    } catch (e) {
      debugPrint("Failed to register FCM device token: $e");
    }
  }
}
