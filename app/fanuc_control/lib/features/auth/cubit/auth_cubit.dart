import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/user.dart';

part 'auth_state.dart';

/// Auth cubit managing authentication state with fake data
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState.initial());

  /// Login with email and password
  Future<void> login(String email, String password) async {
    emit(const AuthState.loading());
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Fake user data
    final user = User(
      uid: 'uid123',
      email: email,
      displayName: 'John Smith',
      role: 'engineer',
      company: 'Acme Manufacturing',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLoginAt: DateTime.now(),
    );
    
    emit(AuthState.authenticated(user));
  }

  /// Sign up new user
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    String? company,
  }) async {
    emit(const AuthState.loading());
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Fake user data
    final user = User(
      uid: 'uid${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: name,
      role: 'engineer',
      company: company,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    
    emit(AuthState.authenticated(user));
  }

  /// Logout
  void logout() {
    emit(const AuthState.initial());
  }

  /// Update user profile
  Future<void> updateUser(User updatedUser) async {
    if (state.isAuthenticated) {
      emit(AuthState.authenticated(updatedUser));
    }
  }
}

