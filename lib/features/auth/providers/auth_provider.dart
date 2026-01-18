import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_manager.dart';

class AuthProvider extends ChangeNotifier {
  Session? _session;
  bool _isInitializing = true;
  bool _isAuthenticating = false;

  Session? get session => _session;
  bool get isInitializing => _isInitializing;
  bool get isSignedIn => _session != null;
  bool get isAuthenticating => _isAuthenticating;

  AuthProvider() {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!SupabaseManager.isInitialized) {
      _session = null;
      _isInitializing = false;
      notifyListeners();
      return;
    }

    _session = SupabaseManager.client.auth.currentSession;
    _isInitializing = false;
    notifyListeners();
  }

  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (!SupabaseManager.isInitialized) {
      throw StateError('Supabase belum dikonfigurasi.');
    }
    _isAuthenticating = true;
    notifyListeners();
    try {
      final response = await SupabaseManager.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _session = response.session;
      return response;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (!SupabaseManager.isInitialized) {
      throw StateError('Supabase belum dikonfigurasi.');
    }
    _isAuthenticating = true;
    notifyListeners();
    try {
      final response = await SupabaseManager.client.auth.signUp(
        email: email,
        password: password,
      );
      _session = response.session;
      return response;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (!SupabaseManager.isInitialized) {
      _session = null;
      notifyListeners();
      return;
    }
    await SupabaseManager.client.auth.signOut();
    _session = null;
    notifyListeners();
  }
}
