import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckStatus extends AuthEvent {
  const AuthCheckStatus();
}

class AuthLogin extends AuthEvent {
  final String email;
  final String password;
  const AuthLogin({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthRegister extends AuthEvent {
  final String email;
  final String password;
  final String? name;
  const AuthRegister({required this.email, required this.password, this.name});
  @override
  List<Object?> get props => [email, password, name];
}

class AuthGoogleSignIn extends AuthEvent {
  const AuthGoogleSignIn();
}

class AuthLogout extends AuthEvent {
  const AuthLogout();
}
