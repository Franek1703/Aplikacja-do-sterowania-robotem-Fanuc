part of 'auth_cubit.dart';

/// Auth state
class AuthState extends Equatable {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  const AuthState.initial()
      : user = null,
        isLoading = false,
        error = null;

  const AuthState.loading()
      : user = null,
        isLoading = true,
        error = null;

  const AuthState.authenticated(UserModel this.user)
      : isLoading = false,
        error = null;

  const AuthState.error(String this.error)
      : user = null,
        isLoading = false;

  bool get isAuthenticated => user != null;

  @override
  List<Object?> get props => [user, isLoading, error];
}

