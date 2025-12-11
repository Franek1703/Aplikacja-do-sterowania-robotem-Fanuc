import 'package:firebase_auth/firebase_auth.dart';

/// Helper class to convert Firebase errors to user-friendly messages
class AuthErrorHelper {
  /// Converts Firebase Auth exceptions to simple, user-friendly error messages
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'Password is too weak. Please use at least 6 characters.';
        case 'email-already-in-use':
          return 'This email is already registered. Please sign in instead.';
        case 'invalid-email':
          return 'Invalid email address. Please check your email format.';
        case 'user-not-found':
          return 'No account found with this email. Please sign up first.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled. Please contact support.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'invalid-credential':
          return 'Invalid email or password. Please try again.';
        default:
          return error.message ?? 'An error occurred. Please try again.';
      }
    }
    
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    
    return error.toString();
  }
  
  /// Validates email format
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  /// Validates password
  static String? validatePassword(String? password, {bool isSignUp = false}) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    
    if (isSignUp && password.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    return null;
  }
}

