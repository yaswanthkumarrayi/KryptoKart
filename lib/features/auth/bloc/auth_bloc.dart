import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService;

  AuthBloc(this._apiService) : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuth);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onCheckAuth(CheckAuthStatus event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _apiService.loadToken();
      if (_apiService.isAuthenticated) {
        final data = await _apiService.getProfile();
        final user = UserModel.fromJson(data['user']);
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final data = await _apiService.login(
        phone: event.phone,
        password: event.password,
      );
      await _apiService.saveToken(data['token']);
      final user = UserModel.fromJson(data['user']);
      emit(Authenticated(user));
    } catch (e) {
      String message = 'Login failed. Please try again.';
      if (e.toString().contains('401')) {
        message = 'Invalid phone or password';
      } else if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        message = 'Cannot connect to server. Please check your connection.';
      }
      emit(AuthError(message));
    }
  }

  Future<void> _onRegister(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final data = await _apiService.register(
        name: event.name,
        phone: event.phone,
        password: event.password,
        upiId: event.upiId,
      );
      await _apiService.saveToken(data['token']);
      final user = UserModel.fromJson(data['user']);
      emit(Authenticated(user));
    } catch (e) {
      String message = 'Registration failed. Please try again.';
      if (e.toString().contains('409')) {
        message = 'Phone number already registered';
      } else if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        message = 'Cannot connect to server. Please check your connection.';
      }
      emit(AuthError(message));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    await _apiService.removeToken();
    emit(Unauthenticated());
  }
}
