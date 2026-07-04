import 'package:flutter/foundation.dart';

@immutable
class TripModel {
  final String id;
  final String name;
  final String inviteCode;
  final List<String> members;
  final bool isGhostActive;

  const TripModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.members,
    this.isGhostActive = false,
  });

  /// Factory constructor to create a [TripModel] from a Map structure (e.g. from Firestore).
  factory TripModel.fromMap(Map<String, dynamic> map, String docId) {
    return TripModel(
      id: docId,
      name: map['name'] as String? ?? '',
      inviteCode: map['inviteCode'] as String? ?? '',
      members: List<String>.from(map['members'] ?? []),
      isGhostActive: map['isGhostActive'] as bool? ?? false,
    );
  }

  /// Converts the [TripModel] instance to a Map structure for Firestore uploads.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'inviteCode': inviteCode,
      'members': members,
      'isGhostActive': isGhostActive,
    };
  }

  /// Creates a copy of this [TripModel] but with the given fields replaced with new values.
  TripModel copyWith({
    String? id,
    String? name,
    String? inviteCode,
    List<String>? members,
    bool? isGhostActive,
  }) {
    return TripModel(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      members: members ?? this.members,
      isGhostActive: isGhostActive ?? this.isGhostActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is TripModel &&
      other.id == id &&
      other.name == name &&
      other.inviteCode == inviteCode &&
      listEquals(other.members, members) &&
      other.isGhostActive == isGhostActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      inviteCode.hashCode ^
      members.hashCode ^
      isGhostActive.hashCode;
  }

  @override
  String toString() {
    return 'TripModel(id: $id, name: $name, inviteCode: $inviteCode, members: $members, isGhostActive: $isGhostActive)';
  }
}
