import 'package:cloud_firestore/cloud_firestore.dart';

/// Base Firestore repository providing simple read/write operations
class FirestoreRepository {
  final FirebaseFirestore _firestore;

  FirestoreRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get a document by path
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(String path) async {
    return await _firestore.doc(path).get();
  }

  /// Get a collection
  Future<QuerySnapshot<Map<String, dynamic>>> getCollection(String path) async {
    return await _firestore.collection(path).get();
  }

  /// Query a collection with filters
  Future<QuerySnapshot<Map<String, dynamic>>> queryCollection(
    String path, {
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>>)? queryBuilder,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return await query.get();
  }

  /// Set a document (create or overwrite)
  Future<void> setDocument(
    String path,
    Map<String, dynamic> data, {
    SetOptions? options,
  }) async {
    await _firestore.doc(path).set(data, options);
  }

  /// Update a document
  Future<void> updateDocument(
    String path,
    Map<String, dynamic> data,
  ) async {
    await _firestore.doc(path).update(data);
  }

  /// Delete a document
  Future<void> deleteDocument(String path) async {
    await _firestore.doc(path).delete();
  }

  /// Stream a document
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDocument(String path) {
    return _firestore.doc(path).snapshots();
  }

  /// Stream a collection
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(String path) {
    return _firestore.collection(path).snapshots();
  }

  /// Stream a collection with query
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollectionQuery(
    String path, {
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>>)? queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }

  /// Batch write operations
  WriteBatch batch() {
    return _firestore.batch();
  }

  /// Get server timestamp
  FieldValue serverTimestamp() {
    return FieldValue.serverTimestamp();
  }
}

