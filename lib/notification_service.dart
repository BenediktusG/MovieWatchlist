import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:movie_watchlist/pages/movie_detail_page.dart'; // Pastikan impor ini benar

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final GlobalKey<NavigatorState>? navigatorKey;

  NotificationService({this.navigatorKey});

  Future<void> initNotifications() async {
    // 1. Minta Izin
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Subscribe ke topik 'all_users' untuk notifikasi broadcast jadwal
      await _fcm.subscribeToTopic('all_users');
      
      if (kDebugMode) {
        print('Berhasil subscribe ke topik all_users');
      }
    }

    // 3. Ambil Token (Untuk notifikasi personal jika nanti butuh)
    final String? fcmToken;
    if (kIsWeb) {
      fcmToken = await _fcm.getToken(
        vapidKey: "BGD4vReWoafMTP_El6TA8WxrA_QQlY9PT2nXHR3O6yBlzEOpwQcdUkRu1oHmSaiE8k4oh1ksmaWXXz5Ntzs6gF8",
      );
    } else {
      fcmToken = await _fcm.getToken();
    }

    if (fcmToken != null) {
      await _saveTokenToDatabase(fcmToken);
    }

    // 4. Setup Listeners
    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);
    await _setupMessageListeners();
  }

  Future<void> _saveTokenToDatabase(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set(
          {'fcmToken': token},
          SetOptions(merge: true),
        );
      } catch (e) {
        if (kDebugMode) print('Error saving token: $e');
      }
    }
  }

  // Handle logika saat notifikasi diklik
  void _handleMessage(RemoteMessage? message) {
    if (message == null) return;

    if (kDebugMode) {
      print('Notifikasi diklik: ${message.notification?.title}');
      print('Data payload: ${message.data}');
    }
    
    // Cek apakah ada movieId di dalam data
    if (message.data['movieId'] != null) {
      final String movieIdStr = message.data['movieId'];
      final int? movieId = int.tryParse(movieIdStr);
      
      if (movieId != null && navigatorKey != null) {
        // Navigasi ke halaman detail
        navigatorKey!.currentState?.push(
          MaterialPageRoute(
            builder: (context) => MovieDetailPage(
              movieId: movieId,
              isMovie: true, // Asumsikan notifikasi rilis film baru adalah Movie
            ),
          ),
        );
      }
    }
  }

  Future<void> _setupMessageListeners() async {
    // 1. App Terminated (Aplikasi mati total)
    FirebaseMessaging.instance.getInitialMessage().then(_handleMessage);

    // 2. App Background (Aplikasi diminimize)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // 3. App Foreground (Aplikasi sedang dibuka)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('--- Notifikasi Foreground Masuk ---');
        print('Judul: ${message.notification?.title}');
        print('Isi: ${message.notification?.body}');
      }
      // Di sini kamu bisa tambahkan logika untuk menampilkan 
      // dialog atau snackbar jika mau notifikasi muncul saat app dibuka
    });
  }
}