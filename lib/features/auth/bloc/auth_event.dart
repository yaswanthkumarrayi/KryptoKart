import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String phone;
  final String password;
  const LoginRequested({required this.phone, required this.password});
  @override
  List<Object> get props => [phone, password];
}

class RegisterRequested extends AuthEvent {
  final String name;
  final String phone;
  final String password;
  final String? upiId;
  const RegisterRequested({
    required this.name,
    required this.phone,
    required this.password,
    this.upiId,
  });
  @override
  List<Object?> get props => [name, phone, password, upiId];
}

class CheckAuthStatus extends AuthEvent {}

class LogoutRequested extends AuthEvent {}
