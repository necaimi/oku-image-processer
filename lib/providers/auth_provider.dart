import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isLoggedIn;
  final String? userName;
  final String? email;

  AuthState({
    this.isLoggedIn = false,
    this.userName,
    this.email,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userName,
    String? email,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userName: userName ?? this.userName,
      email: email ?? this.email,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState();
  }

  void login(String name, String email) {
    state = state.copyWith(isLoggedIn: true, userName: name, email: email);
  }

  void logout() {
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
