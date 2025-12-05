import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:movie_watchlist/main.dart';
import 'package:movie_watchlist/notification_service.dart';
import 'package:movie_watchlist/pages/login_page.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<User?>();

    if (user != null) {
      NotificationService(navigatorKey: navigatorKey).initNotifications();
      return const MainScreen();
    } else {
      // User belum login
      return const LoginPage();
    }
  }
}
