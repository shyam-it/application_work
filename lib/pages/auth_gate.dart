import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../navigation/main_navigation.dart';
import '../services/auth_service.dart';
import 'account_status_page.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.authService});

  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    final service = authService ?? AuthService();

    return StreamBuilder<User?>(
      stream: service.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final user = authSnapshot.data;

        if (user == null) {
          return LoginPage(authService: service);
        }

        return FutureBuilder<String?>(
          future: service.roleFor(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (roleSnapshot.hasError) {
              return const AccountStatusPage(
                title: 'Unable to verify account',
                message:
                    'Please check your connection and try again. If the problem continues, contact the administrator.',
              );
            }

            final role = roleSnapshot.data;

            if (role == null) {
              return const AccountStatusPage(
                title: 'Account setup required',
                message:
                    'Your login exists, but an Owner or administrator must assign your WorkMate role in Firestore before you can continue.',
              );
            }

            return MainNavigation(role: role);
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
