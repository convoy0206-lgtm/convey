import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

/// Provider definition for [LocationService] to integrate with Riverpod.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(
    FirebaseFirestore.instance,
    ref,
  );
});

/// Exposes a stream of the current user's coordinate location updates.
final locationStreamProvider = StreamProvider.autoDispose<LocationData>((ref) {
  final service = ref.watch(locationServiceProvider);
  return service.locationStream;
});

/// Model class representing shared coordinate updates.
class LocationData {
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final String timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp,
    };
  }

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] as String? ?? '',
    );
  }
}

class LocationService {
  final FirebaseFirestore _firestore;
  final Ref _ref;
  final _locationController = StreamController<LocationData>.broadcast();
  bool _isTracking = false;
  bool _isSimulationActive = false;
  Timer? _simulationTimer;
  int _simulationIndex = 0;

  LocationService(this._firestore, this._ref);

  /// Exposes location updates stream
  Stream<LocationData> get locationStream => _locationController.stream;

  bool get isTracking => _isTracking;
  bool get isSimulationActive => _isSimulationActive;

  /// Route coordinates mockup for Sierra Nevada Trail simulation.
  static const List<List<double>> sierraNevadaRoute = [
    [37.7456, -119.5332], // Yosemite Start
    [37.7490, -119.5290],
    [37.7525, -119.5210],
    [37.7560, -119.5120],
    [37.7595, -119.5050],
    [37.7630, -119.4970],
    [37.7675, -119.4890],
    [37.7710, -119.4790],
    [37.7750, -119.4680], // Pass midpoint
    [37.7780, -119.4570],
    [37.7815, -119.4480],
    [37.7850, -119.4390],
    [37.7890, -119.4280],
    [37.7925, -119.4190],
    [37.7960, -119.4100], // Nevada Pass End
  ];

  /// Initialize and start tracking coordinates.
  Future<void> startTracking(String tripId, {bool ghostMode = false}) async {
    if (_isTracking) return;
    _isTracking = true;

    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        // Configure BackgroundGeolocation
        await bg.BackgroundGeolocation.ready(bg.Config(
          desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
          distanceFilter: 10.0,
          stopOnTerminate: false,
          startOnBoot: true,
          debug: false,
          logLevel: bg.Config.LOG_LEVEL_OFF,
          notification: bg.Notification(
            title: 'Convoy Active Tracking',
            text: 'Broadcasting your coordinate sync stream...',
          ),
        ));

        // Location listener
        bg.BackgroundGeolocation.onLocation((bg.Location location) {
          final data = LocationData(
            latitude: location.coords.latitude,
            longitude: location.coords.longitude,
            speed: location.coords.speed,
            heading: location.coords.heading,
            timestamp: DateTime.now().toIso8601String(),
          );
          
          _locationController.add(data);
          
          if (!ghostMode) {
            _broadcastToFirestore(tripId, data);
          }
        });

        await bg.BackgroundGeolocation.start();
      } catch (e) {
        debugPrint('BackgroundGeolocation Setup Skip (falling back to simulator): $e');
        _startSimulator(tripId, ghostMode);
      }
    } else {
      // Fallback for emulator and web simulator contexts
      _startSimulator(tripId, ghostMode);
    }
  }

  /// Stop tracking coordinates.
  Future<void> stopTracking() async {
    _isTracking = false;
    _stopSimulator();

    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        await bg.BackgroundGeolocation.stop();
      } catch (e) {
        debugPrint('BackgroundGeolocation Stop Error: $e');
      }
    }
  }

  /// Starts the GPS simulation stream along the Sierra Nevada path.
  void _startSimulator(String tripId, bool ghostMode) {
    _stopSimulator();
    _isSimulationActive = true;
    _simulationIndex = 0;

    _simulationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isTracking) {
        _stopSimulator();
        return;
      }

      final coords = sierraNevadaRoute[_simulationIndex % sierraNevadaRoute.length];
      final heading = _simulationIndex * 24.5 % 360;
      // Simulated speed fluctuations between 5 and 35 mph
      final speed = 15.0 + (5.0 * (_simulationIndex % 4));

      final data = LocationData(
        latitude: coords[0],
        longitude: coords[1],
        speed: speed,
        heading: heading,
        timestamp: DateTime.now().toIso8601String(),
      );

      _locationController.add(data);

      if (!ghostMode) {
        _broadcastToFirestore(tripId, data);
      }

      _simulationIndex++;
    });
  }

  /// Stops the GPS simulation stream.
  void _stopSimulator() {
    _isSimulationActive = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  /// Write coordinate record to Firebase Firestore.
  Future<void> _broadcastToFirestore(String tripId, LocationData data) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('locations')
          .doc(user.uid)
          .set({
            ...data.toMap(),
            'displayName': user.displayName,
            'email': user.email,
            'photoUrl': user.photoUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Firestore location write error: $e');
    }
  }

  /// Exposes a stream of location updates for all active members in the trip.
  Stream<Map<String, dynamic>> streamGroupLocations(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('locations')
        .snapshots()
        .map((snapshot) {
          final Map<String, dynamic> membersLocations = {};
          for (var doc in snapshot.docs) {
            membersLocations[doc.id] = doc.data();
          }
          return membersLocations;
        });
  }
}
