import '../models/user.dart';

/// Abstract user repository interface for Firebase operations
/// TODO: Implement Firebase Firestore integration
abstract class UserRepository {
  /// Get user profile by UID
  Future<UserModel?> getUser(String uid);

  /// Create new user
  Future<UserModel> createUser(UserModel user);

  /// Update user profile
  Future<UserModel> updateUser(UserModel user);

  /// Delete user
  Future<void> deleteUser(String uid);
}

