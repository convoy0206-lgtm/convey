import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final String type; // 'text', 'location_alert', 'speed_alert'

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.type = 'text',
  });

  /// Factory constructor to map document from Firestore.
  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedTime = DateTime.now();
    if (map['timestamp'] is Timestamp) {
      parsedTime = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      parsedTime = DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now();
    }

    return MessageModel(
      id: docId,
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? 'Squad Member',
      text: map['text'] as String? ?? '',
      timestamp: parsedTime,
      type: map['type'] as String? ?? 'text',
    );
  }

  /// Converts the [MessageModel] instance to a Map structure for Firestore uploads.
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type,
    };
  }

  /// Creates a copy of this [MessageModel] but with the given fields replaced with new values.
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? text,
    DateTime? timestamp,
    String? type,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is MessageModel &&
      other.id == id &&
      other.senderId == senderId &&
      other.senderName == senderName &&
      other.text == text &&
      other.timestamp == timestamp &&
      other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      senderId.hashCode ^
      senderName.hashCode ^
      text.hashCode ^
      timestamp.hashCode ^
      type.hashCode;
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, senderId: $senderId, senderName: $senderName, text: $text, timestamp: $timestamp, type: $type)';
  }
}
