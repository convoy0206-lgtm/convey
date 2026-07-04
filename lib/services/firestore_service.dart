import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/trip_model.dart';
import '../models/message_model.dart';
import '../models/expense_model.dart';
import '../models/itinerary_item_model.dart';
import 'sync_service.dart';

/// Provider definition for [FirestoreService] to integrate with Riverpod.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance);
});

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  /// Collection references.
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _tripsCollection => _firestore.collection('trips');

  /// Create or update user profile document in Firestore.
  Future<void> createUserDocument(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user profile: ${e.toString()}');
    }
  }

  /// Retrieve user profile document.
  Future<UserModel?> getUserDocument(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user profile: ${e.toString()}');
    }
  }

  /// Create a new collaborative Trip.
  Future<TripModel> createTrip({
    required String name,
    required String creatorUid,
  }) async {
    try {
      final String inviteCode = _generateInviteCode();
      
      final docRef = await _tripsCollection.add({
        'name': name,
        'inviteCode': inviteCode,
        'members': [creatorUid],
        'isGhostActive': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return TripModel(
        id: docRef.id,
        name: name,
        inviteCode: inviteCode,
        members: [creatorUid],
        isGhostActive: false,
      );
    } catch (e) {
      throw Exception('Failed to create trip: ${e.toString()}');
    }
  }

  /// Join an existing trip group using a unique invite code.
  Future<TripModel> joinTripWithInviteCode({
    required String inviteCode,
    required String userUid,
  }) async {
    try {
      final querySnapshot = await _tripsCollection
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase().trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('No active group found for this invite code.');
      }

      final doc = querySnapshot.docs.first;
      final tripData = doc.data() as Map<String, dynamic>;
      final List<String> currentMembers = List<String>.from(tripData['members'] ?? []);

      if (!currentMembers.contains(userUid)) {
        currentMembers.add(userUid);
        await doc.reference.update({
          'members': currentMembers,
        });
      }

      return TripModel.fromMap(
        {
          ...tripData,
          'members': currentMembers,
        },
        doc.id,
      );
    } catch (e) {
      if (e.toString().contains('No active group found')) rethrow;
      throw Exception('Failed to join trip: ${e.toString()}');
    }
  }

  /// Stream trip updates in real-time.
  Stream<TripModel?> streamTrip(String tripId) {
    return _tripsCollection.doc(tripId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return TripModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
      }
      return null;
    });
  }

  /// Update privacy settings: toggle Ghost Mode.
  Future<void> updateGhostMode({
    required String tripId,
    required bool isGhostActive,
  }) async {
    try {
      await _tripsCollection.doc(tripId).update({
        'isGhostActive': isGhostActive,
      });
    } catch (e) {
      throw Exception('Failed to update privacy settings: ${e.toString()}');
    }
  }

  /// Generate a unique 8-character invite code (e.g. TRIP-3A9F).
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude ambiguous characters like I, O, 0, 1
    final rand = Random();
    final code = List.generate(4, (index) => chars[rand.nextInt(chars.length)]).join();
    return 'TRIP-$code';
  }

  /// Stream collaborative chat messages in real-time.
  Stream<List<MessageModel>> streamMessages(String tripId) {
    return _tripsCollection
        .doc(tripId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MessageModel.fromMap(data, doc.id);
      }).toList();
    });
  }

  /// Send a new message to the group.
  Future<void> sendMessage(String tripId, MessageModel message) async {
    try {
      await _tripsCollection
          .doc(tripId)
          .collection('messages')
          .add(message.toMap());
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  /// Stream expense tracking records.
  Stream<List<ExpenseModel>> streamExpenses(String tripId) {
    return _tripsCollection
        .doc(tripId)
        .collection('expenses')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ExpenseModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Add a new expense using SyncService support for offline queuing.
  Future<void> addExpense(String tripId, ExpenseModel expense, SyncService syncService) async {
    try {
      final docId = expense.id.isEmpty 
          ? _tripsCollection.doc(tripId).collection('expenses').doc().id 
          : expense.id;

      final expenseData = expense.copyWith(id: docId);

      // Save to local SQLite cache first (so it's available offline)
      final localMap = {
        'id': docId,
        'tripId': tripId,
        'description': expenseData.description,
        'amount': expenseData.amount,
        'paidBy': expenseData.paidBy,
        'splitWith': expenseData.splitWith.join(','),
        'timestamp': expenseData.timestamp.toIso8601String(),
      };
      await syncService.saveLocalExpense(localMap);

      // Write to Firestore / local sync queue
      await syncService.performWrite(
        collectionPath: 'trips/$tripId/expenses',
        documentId: docId,
        data: expenseData.toMap(),
      );
    } catch (e) {
      throw Exception('Failed to save expense: ${e.toString()}');
    }
  }

  /// Stream itinerary details in real-time.
  Stream<List<ItineraryItemModel>> streamItinerary(String tripId) {
    return _tripsCollection
        .doc(tripId)
        .collection('itinerary')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ItineraryItemModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Add a new itinerary item/milestone checkpoint.
  Future<void> addItineraryItem(String tripId, ItineraryItemModel item) async {
    try {
      final docId = item.id.isEmpty
          ? _tripsCollection.doc(tripId).collection('itinerary').doc().id
          : item.id;
      final itemData = item.copyWith(id: docId);
      
      await _tripsCollection
          .doc(tripId)
          .collection('itinerary')
          .doc(docId)
          .set(itemData.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to add itinerary item: ${e.toString()}');
    }
  }
}
