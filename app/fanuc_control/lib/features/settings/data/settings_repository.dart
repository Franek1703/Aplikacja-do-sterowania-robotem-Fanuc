import '../../../config/repositories/firestore_repository.dart';
import '../../../models/user.dart';

/// Repository for settings/user profile operations
class SettingsRepository {
  final FirestoreRepository _firestore;

  SettingsRepository({FirestoreRepository? firestore})
      : _firestore = firestore ?? FirestoreRepository();

  /// Update user profile
  Future<void> updateUserProfile(String userId, UserModel user) async {
    try {
      await _firestore.updateDocument(
        'users/$userId',
        user.toFirestore(),
      );
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Update user display name
  Future<void> updateDisplayName(String userId, String displayName) async {
    try {
      await _firestore.updateDocument(
        'users/$userId',
        {'displayName': displayName},
      );
    } catch (e) {
      throw Exception('Failed to update display name: $e');
    }
  }

  /// Update user email (note: email is also in Firebase Auth)
  Future<void> updateEmail(String userId, String email) async {
    try {
      await _firestore.updateDocument(
        'users/$userId',
        {'email': email},
      );
    } catch (e) {
      throw Exception('Failed to update email: $e');
    }
  }

  /// Get user statistics (device count, robot count, etc.)
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      // Get device count
      final devicesSnapshot = await _firestore.queryCollection(
        'devices',
        queryBuilder: (query) => query.where('members', arrayContains: userId),
      );

      int robotCount = 0;
      for (var deviceDoc in devicesSnapshot.docs) {
        final deviceId = deviceDoc.id;
        final robotsSnapshot = await _firestore.queryCollection(
          'robots',
          queryBuilder: (query) => query.where('deviceId', isEqualTo: deviceId),
        );
        robotCount += robotsSnapshot.docs.length;
      }

      return {
        'deviceCount': devicesSnapshot.docs.length,
        'robotCount': robotCount,
        'uptime': 98.0, // This would be calculated from actual data
      };
    } catch (e) {
      return {
        'deviceCount': 0,
        'robotCount': 0,
        'uptime': 0.0,
      };
    }
  }
}

