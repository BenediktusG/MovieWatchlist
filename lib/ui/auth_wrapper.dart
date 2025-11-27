import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:movie_watchlist/main.dart';
import 'package:movie_watchlist/pages/login_page.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 4. 'context.watch' adalah cara baru untuk mendengarkan perubahan
    // Ia akan 'mendengarkan' StreamProvider<User?> yang kita buat di main.dart
    final User? user = context.watch<User?>();

    // 5. Logika if/else yang sama, tapi sekarang lebih bersih
    if (user != null) {
      // User sudah login
      return const MainScreen();
    } else {
      // User belum login
      return const LoginPage();
    }

    // Catatan: Anda tidak perlu lagi 'ConnectionState.waiting'
    // karena 'initialData: null' di StreamProvider sudah menangani
    // kondisi awal (dianggap sebagai 'logout').
  }
}
