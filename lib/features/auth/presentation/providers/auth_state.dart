// import 'package:auth_katalog_app/features/auth/domain/entity/user_entity.dart';

// /// Immutable auth state consumed by the UI.
// sealed class AuthState {
//   const AuthState();
// }

// /// App is launching and we're checking for an existing session.
// class AuthInitial extends AuthState {
//   const AuthInitial();
// }

// /// No valid session — show the login screen.
// class AuthUnauthenticated extends AuthState {
//   const AuthUnauthenticated();
// }

// /// A session exists and the profile is loaded.
// class AuthAuthenticated extends AuthState {
//   const AuthAuthenticated(this.user);

//   final UserEntity user;
// }

// /// An operation is in flight (e.g. logging in, checking status).
// class AuthLoading extends AuthState {
//   const AuthLoading();
// }

// /// An operation failed; [message] is user-facing.
// class AuthError extends AuthState {
//   const AuthError(this.message);

//   final String message;
// }
