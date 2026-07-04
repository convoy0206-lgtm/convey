import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class ExpenseModel {
  final String id;
  final String tripId;
  final String description;
  final double amount;
  final String paidBy; // user ID
  final List<String> splitWith; // List of user IDs
  final DateTime timestamp;

  const ExpenseModel({
    required this.id,
    required this.tripId,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.splitWith,
    required this.timestamp,
  });

  /// Factory constructor to map document from Firestore.
  factory ExpenseModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedTime = DateTime.now();
    if (map['timestamp'] is Timestamp) {
      parsedTime = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      parsedTime = DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now();
    }

    return ExpenseModel(
      id: docId,
      tripId: map['tripId'] as String? ?? '',
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidBy: map['paidBy'] as String? ?? '',
      splitWith: List<String>.from(map['splitWith'] ?? []),
      timestamp: parsedTime,
    );
  }

  /// Converts the [ExpenseModel] instance to a Map structure for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'description': description,
      'amount': amount,
      'paidBy': paidBy,
      'splitWith': splitWith,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Creates a copy of this [ExpenseModel] but with the given fields replaced with new values.
  ExpenseModel copyWith({
    String? id,
    String? tripId,
    String? description,
    double? amount,
    String? paidBy,
    List<String>? splitWith,
    DateTime? timestamp,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      splitWith: splitWith ?? this.splitWith,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ExpenseModel &&
      other.id == id &&
      other.tripId == tripId &&
      other.description == description &&
      other.amount == amount &&
      other.paidBy == paidBy &&
      listEquals(other.splitWith, splitWith) &&
      other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      tripId.hashCode ^
      description.hashCode ^
      amount.hashCode ^
      paidBy.hashCode ^
      splitWith.hashCode ^
      timestamp.hashCode;
  }

  @override
  String toString() {
    return 'ExpenseModel(id: $id, tripId: $tripId, description: $description, amount: $amount, paidBy: $paidBy, splitWith: $splitWith, timestamp: $timestamp)';
  }
}
