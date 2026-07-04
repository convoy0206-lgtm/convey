import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../main.dart' show firebaseAvailable;

/// Provider definition for [SyncService] to integrate with Riverpod.
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

class SyncService {
  Database? _db;
  bool _isOnline = true;

  // In-memory fallback for web (sqflite not supported in browser)
  final List<Map<String, dynamic>> _inMemoryQueue = [];
  final List<Map<String, dynamic>> _inMemoryExpenses = [];

  bool get isOnline => _isOnline;

  /// Whether SQLite is available on this platform.
  bool get _sqliteAvailable => !kIsWeb;

  /// Trigger offline mode simulator
  void setOnlineStatus(bool online) {
    _isOnline = online;
    if (_isOnline) {
      processSyncQueue();
    }
  }

  /// Initialize local SQLite DB. No-op on web.
  Future<void> initDatabase() async {
    if (!_sqliteAvailable) return; // sqflite not supported on web
    if (_db != null) return;
    try {
      final databasesPath = await getDatabasesPath();
      final path = p.join(databasesPath, 'convoy_sync.db');

      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          // Sync queue table
          await db.execute(
            'CREATE TABLE sync_queue ('
            '  id INTEGER PRIMARY KEY AUTOINCREMENT,'
            '  path TEXT,'
            '  payload TEXT,'
            '  action TEXT'
            ')',
          );
          
          // Local cache expenses table
          await db.execute(
            'CREATE TABLE local_expenses ('
            '  id TEXT PRIMARY KEY,'
            '  tripId TEXT,'
            '  description TEXT,'
            '  amount REAL,'
            '  paidBy TEXT,'
            '  splitWith TEXT,'
            '  timestamp TEXT'
            ')',
          );
        },
      );
      debugPrint('SQLite Local Sync DB Initialized.');
    } catch (e) {
      debugPrint('SQLite DB Init Error: $e');
    }
  }

  /// Perform Firestore write. If offline, cache in SQLite sync queue instead.
  Future<void> performWrite({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
    String action = 'SET',
  }) async {
    await initDatabase();

    if (_isOnline && firebaseAvailable) {
      try {
        final docRef = FirebaseFirestore.instance.collection(collectionPath).doc(documentId);
        if (action == 'SET') {
          await docRef.set(data, SetOptions(merge: true));
        } else if (action == 'UPDATE') {
          await docRef.update(data);
        }
        return;
      } catch (e) {
        debugPrint('Online write failed (queueing instead): $e');
      }
    }

    // Offline caching execution
    if (_sqliteAvailable && _db != null) {
      try {
        await _db!.insert('sync_queue', {
          'path': '$collectionPath/$documentId',
          'payload': jsonEncode(data),
          'action': action,
        });
        debugPrint('Offline Mode: Queued write to SQLite for path $collectionPath/$documentId');
      } catch (e) {
        debugPrint('Failed to queue offline write to SQLite: $e');
      }
    } else {
      // Web fallback: in-memory queue
      _inMemoryQueue.add({
        'path': '$collectionPath/$documentId',
        'payload': data,
        'action': action,
      });
      debugPrint('Web Offline Mode: Queued write in-memory for path $collectionPath/$documentId');
    }
  }

  /// Flushes the local SQLite queue (or in-memory queue on web) to Firestore sequentially.
  Future<void> processSyncQueue() async {
    if (!_isOnline) return;

    if (!firebaseAvailable) {
      debugPrint('Firebase not available: skipping sync queue flush.');
      return;
    }

    // Web: flush in-memory queue
    if (!_sqliteAvailable) {
      for (final record in List.from(_inMemoryQueue)) {
        final path = record['path'] as String;
        final payload = record['payload'] as Map<String, dynamic>;
        final action = record['action'] as String;

        final pathSegments = path.split('/');
        if (pathSegments.length < 2) continue;
        final collectionPath = pathSegments.sublist(0, pathSegments.length - 1).join('/');
        final docId = pathSegments.last;

        try {
          final docRef = FirebaseFirestore.instance.collection(collectionPath).doc(docId);
          if (action == 'SET') {
            await docRef.set(payload, SetOptions(merge: true));
          } else if (action == 'UPDATE') {
            await docRef.update(payload);
          }
          _inMemoryQueue.remove(record);
        } catch (e) {
          debugPrint('Web queue flush error: $e');
        }
      }
      return;
    }

    // Native: flush SQLite queue
    await initDatabase();
    if (_db == null) return;

    try {
      final List<Map<String, dynamic>> records = await _db!.query('sync_queue', orderBy: 'id ASC');
      if (records.isEmpty) return;

      debugPrint('Processing ${records.length} pending local sync records...');
      
      for (var record in records) {
        final id = record['id'] as int;
        final path = record['path'] as String;
        final payload = jsonDecode(record['payload'] as String) as Map<String, dynamic>;
        final action = record['action'] as String;

        // Extract collection path and document ID
        final pathSegments = path.split('/');
        if (pathSegments.length < 2) continue;
        
        final collectionPath = pathSegments.sublist(0, pathSegments.length - 1).join('/');
        final docId = pathSegments.last;

        final docRef = FirebaseFirestore.instance.collection(collectionPath).doc(docId);
        
        if (action == 'SET') {
          await docRef.set(payload, SetOptions(merge: true));
        } else if (action == 'UPDATE') {
          await docRef.update(payload);
        }

        // Delete from local queue
        await _db!.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
      }
      debugPrint('SQLite Local Sync Queue successfully processed and synchronized.');
    } catch (e) {
      debugPrint('Sync process error: $e');
    }
  }

  /// Insert local cached expense record.
  Future<void> saveLocalExpense(Map<String, dynamic> expense) async {
    if (!_sqliteAvailable) {
      // Web: in-memory expense cache
      _inMemoryExpenses.removeWhere((e) => e['id'] == expense['id']);
      _inMemoryExpenses.add(expense);
      return;
    }
    await initDatabase();
    try {
      await _db?.insert('local_expenses', expense, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('SQLite local expense save error: $e');
    }
  }

  /// Retrieve local cached expense records.
  Future<List<Map<String, dynamic>>> getLocalExpenses(String tripId) async {
    if (!_sqliteAvailable) {
      // Web: filter from in-memory list
      return _inMemoryExpenses.where((e) => e['tripId'] == tripId).toList();
    }
    await initDatabase();
    if (_db == null) return [];
    try {
      return await _db!.query('local_expenses', where: 'tripId = ?', whereArgs: [tripId]);
    } catch (e) {
      debugPrint('SQLite local expenses fetch error: $e');
      return [];
    }
  }
}
