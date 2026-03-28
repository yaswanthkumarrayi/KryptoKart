import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService;

  /// Key used in SharedPreferences to store biometric preference locally.
  static const _kBiometricKey = 'biometric_enabled';

  AuthBloc(this._apiService) : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuth);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<BiometricLoginRequested>(_onBiometricLogin);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onCheckAuth(CheckAuthStatus event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _apiService.loadToken();
      if (_apiService.isAuthenticated) {
        final data = await _apiService.getProfile();
        final user = UserModel.fromJson(data['user']);

        // Check if biometric is enabled locally
        final prefs = await SharedPreferences.getInstance();
        final biometricEnabled = prefs.getBool(_kBiometricKey) ?? false;

        if (biometricEnabled) {
          // Don't auto-login yet — require biometric first
          emit(BiometricAuthRequired(user));
        } else {
          emit(Authenticated(user));
        }
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  /// Called after successful biometric verification on the splash screen.
  Future<void> _onBiometricLogin(BiometricLoginRequested event, Emitter<AuthState> emit) async {
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

  /// Save biometric preference to local storage (called from settings screen).
  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricKey, enabled);
  }
}
