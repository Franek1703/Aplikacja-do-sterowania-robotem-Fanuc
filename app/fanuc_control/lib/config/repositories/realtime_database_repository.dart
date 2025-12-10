import 'package:firebase_database/firebase_database.dart';

/// Base Realtime Database repository providing simple read/write operations
class RealtimeDatabaseRepository {
  final DatabaseReference _database;

  RealtimeDatabaseRepository({DatabaseReference? database})
      : _database = database ?? FirebaseDatabase.instance.ref();

  /// Get a value at a path
  Future<DataSnapshot> getValue(String path) async {
    return await _database.child(path).get();
  }

  /// Set a value at a path
  Future<void> setValue(String path, dynamic value) async {
    await _database.child(path).set(value);
  }

  /// Update values at a path
  Future<void> updateValue(String path, Map<String, dynamic> values) async {
    await _database.child(path).update(values);
  }

  /// Push a new child (auto-generates key)
  Future<DatabaseReference> push(String path, dynamic value) async {
    final ref = _database.child(path).push();
    await ref.set(value);
    return ref;
  }

  /// Remove a value at a path
  Future<void> remove(String path) async {
    await _database.child(path).remove();
  }

  /// Stream a value at a path
  Stream<DatabaseEvent> streamValue(String path) {
    return _database.child(path).onValue;
  }

  /// Stream child events (added, changed, removed)
  Stream<DatabaseEvent> streamChildEvents(String path) {
    return _database.child(path).onChildAdded;
  }

  /// Stream all child events
  Stream<DatabaseEvent> streamAllChildEvents(String path) {
    return _database.child(path).onChildAdded;
  }

  /// Get a reference to a path
  DatabaseReference ref(String path) {
    return _database.child(path);
  }

  /// Run a transaction
  Future<TransactionResult> runTransaction(
    String path,
    TransactionHandler handler,
  ) async {
    return await _database.child(path).runTransaction(handler);
  }
}

