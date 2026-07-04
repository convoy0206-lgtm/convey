import 'package:flutter/foundation.dart';

@immutable
class ItineraryItemModel {
  final String id;
  final String tripId;
  final String title;
  final String description;
  final String timeLabel; // e.g. "Day 1 - 09:00 AM"
  final double latitude;
  final double longitude;
  final double distanceMiles;
  final int estimatedTimeMinutes;

  const ItineraryItemModel({
    required this.id,
    required this.tripId,
    required this.title,
    required this.description,
    required this.timeLabel,
    required this.latitude,
    required this.longitude,
    required this.distanceMiles,
    required this.estimatedTimeMinutes,
  });

  /// Factory constructor to map document from Firestore.
  factory ItineraryItemModel.fromMap(Map<String, dynamic> map, String docId) {
    return ItineraryItemModel(
      id: docId,
      tripId: map['tripId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      timeLabel: map['timeLabel'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      distanceMiles: (map['distanceMiles'] as num?)?.toDouble() ?? 0.0,
      estimatedTimeMinutes: (map['estimatedTimeMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  /// Converts the [ItineraryItemModel] instance to a Map structure for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'title': title,
      'description': description,
      'timeLabel': timeLabel,
      'latitude': latitude,
      'longitude': longitude,
      'distanceMiles': distanceMiles,
      'estimatedTimeMinutes': estimatedTimeMinutes,
    };
  }

  /// Creates a copy of this [ItineraryItemModel] but with the given fields replaced with new values.
  ItineraryItemModel copyWith({
    String? id,
    String? tripId,
    String? title,
    String? description,
    String? timeLabel,
    double? latitude,
    double? longitude,
    double? distanceMiles,
    int? estimatedTimeMinutes,
  }) {
    return ItineraryItemModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      description: description ?? this.description,
      timeLabel: timeLabel ?? this.timeLabel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceMiles: distanceMiles ?? this.distanceMiles,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ItineraryItemModel &&
      other.id == id &&
      other.tripId == tripId &&
      other.title == title &&
      other.description == description &&
      other.timeLabel == timeLabel &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.distanceMiles == distanceMiles &&
      other.estimatedTimeMinutes == estimatedTimeMinutes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      tripId.hashCode ^
      title.hashCode ^
      description.hashCode ^
      timeLabel.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      distanceMiles.hashCode ^
      estimatedTimeMinutes.hashCode;
  }

  @override
  String toString() {
    return 'ItineraryItemModel(id: $id, tripId: $tripId, title: $title, description: $description, timeLabel: $timeLabel, latitude: $latitude, longitude: $longitude, distanceMiles: $distanceMiles, estimatedTimeMinutes: $estimatedTimeMinutes)';
  }
}
