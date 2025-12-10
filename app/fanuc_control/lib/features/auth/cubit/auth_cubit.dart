import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/user.dart';
import '../data/auth_repository.dart';
import '../utils/auth_error_helper.dart';

part 'auth_state.dart';

/// Auth cubit managing authentication state
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(const AuthState.initial()) {
    // Check current user on initialization
    _checkCurrentUser();
    
    // Listen to auth state changes
    _authRepository.authStateChanges.listen((firebaseUser) async {
      await _handleAuthStateChange(firebaseUser);
    });
  }

  Future<void> _checkCurrentUser() async {
    emit(const AuthState.loading());
    final firebaseUser = _authRepository.currentUser;
    if (firebaseUser != null) {
      await _handleAuthStateChange(firebaseUser);
    }
    else {
      emit(const AuthState.initial());
    }
  }

  Future<void> _handleAuthStateChange(firebaseUser) async {
    if (firebaseUser != null) {
      // Get user profile from Firestore
      final userProfile = await _authRepository.getUserProfile(firebaseUser.uid);
      if (userProfile != null) {
        emit(AuthState.authenticated(userProfile));
      } else {
        // If profile doesn't exist yet, create a basic one from Firebase Auth
        final basicUserProfile = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'User',
          role: 'engineer',
          photoUrl: firebaseUser.photoURL,
        );
        emit(AuthState.authenticated(basicUserProfile));
      }
    } else {
      emit(const AuthState.initial());
    }
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    // Validate email
    final emailError = AuthErrorHelper.validateEmail(email);
    if (emailError != null) {
      emit(AuthState.error(emailError));
      return;
    }

    // Validate password
    final passwordError = AuthErrorHelper.validatePassword(password);
    if (passwordError != null) {
      emit(AuthState.error(passwordError));
      return;
    }

    emit(const AuthState.loading());

    try {
      await _authRepository.signInWithEmail(
        email: email.trim(),
        password: password,
      );
      // State will be updated via authStateChanges stream
    } catch (e) {
      emit(AuthState.error(AuthErrorHelper.getErrorMessage(e)));
    }
  }

  /// Sign up new user
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    String? company,
  }) async {
    // Validate email
    final emailError = AuthErrorHelper.validateEmail(email);
    if (emailError != null) {
      emit(AuthState.error(emailError));
      return;
    }

    // Validate password (with minimum length check for sign up)
    final passwordError = AuthErrorHelper.validatePassword(password, isSignUp: true);
    if (passwordError != null) {
      emit(AuthState.error(passwordError));
      return;
    }

    // Validate name
    if (name.trim().isEmpty) {
      emit(const AuthState.error('Name is required'));
      return;
    }

    emit(const AuthState.loading());

    try {
      await _authRepository.signUpWithEmail(
        email: email.trim(),
        password: password,
        displayName: name.trim(),
      );
      // State will be updated via authStateChanges stream
    } catch (e) {
      emit(AuthState.error(AuthErrorHelper.getErrorMessage(e)));
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    emit(const AuthState.loading());

    try {
      await _authRepository.signInWithGoogle();
      // State will be updated via authStateChanges stream
    } catch (e) {
      emit(AuthState.error(AuthErrorHelper.getErrorMessage(e)));
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _authRepository.signOut();
      emit(const AuthState.initial());
    } catch (e) {
      emit(AuthState.error(AuthErrorHelper.getErrorMessage(e)));
    }
  }

  /// Update user profile
  Future<void> updateUser(UserModel updatedUser) async {
    if (state.isAuthenticated) {
      emit(AuthState.authenticated(updatedUser));
    }
  }
}

