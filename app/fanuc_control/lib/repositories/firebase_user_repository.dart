import '../models/user.dart';

/// Abstract user repository interface for Firebase operations
/// TODO: Implement Firebase Firestore integration
abstract class UserRepository {
  /// Get user profile by UID
  Future<User?> getUser(String uid);

  /// Create new user
  Future<User> createUser(User user);

  /// Update user profile
  Future<User> updateUser(User user);

  /// Delete user
  Future<void> deleteUser(String uid);
}

