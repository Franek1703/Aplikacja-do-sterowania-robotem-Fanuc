import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fanuc_control/features/auth/data/firebase_auth_datasource.dart';
import 'package:fanuc_control/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuthDataSource _dataSource;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuthDataSource? dataSource,
    FirebaseFirestore? firestore,
  })  : _dataSource = dataSource ?? FirebaseAuthDataSource(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _dataSource.currentUser;

  Stream<User?> get authStateChanges => _dataSource.authStateChanges;

  Future<bool> isLoggedIn() => _dataSource.isLoggedIn();

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final userCredential = await _dataSource.signUpWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user == null) {
      throw Exception('User creation failed');
    }

    // Update display name in Firebase Auth
    await user.updateProfile(displayName: displayName);
    await user.reload();

    // Create user document in Firestore
    await _createUserDocument(
      userId: user.uid,
      displayName: displayName,
      email: email,
      photoUrl: null,
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _dataSource.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update lastTimeSeen
    final user = _dataSource.currentUser;
    if (user != null) {
      await _updateLastTimeSeen(user.uid);
    }
  }

  Future<void> signInWithGoogle() async {
    final userCredential = await _dataSource.signInWithGoogle();
    final user = userCredential.user;

    if (user == null) {
      throw Exception('Google sign in failed');
    }

    // Check if user document exists
    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      // New user - create document
      await _createUserDocument(
        userId: user.uid,
        displayName: user.displayName ?? 'User',
        email: user.email ?? '',
        photoUrl: user.photoURL,
      );
    } else {
      // Existing user - only update lastTimeSeen
      await _updateLastTimeSeen(user.uid);
    }
  }

  Future<void> signOut() async {
    await _dataSource.signOut();
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        return null;
      }
      return UserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Future<void> _createUserDocument({
    required String userId,
    required String displayName,
    required String email,
    String? photoUrl,
  }) async {
    final userModel = UserModel(
      uid: userId,
      displayName: displayName,
      email: email,
      role: 'engineer',
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(userId).set(
          userModel.toFirestore(),
        );
  }

  Future<void> _updateLastTimeSeen(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastTimeSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserProfile(String userId, UserModel user) async {
    await _firestore.collection('users').doc(userId).update(
          user.toFirestore(),
        );
  }
}

