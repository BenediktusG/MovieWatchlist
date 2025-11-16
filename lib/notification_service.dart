// lib/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Ganti dengan halaman detail Anda
// import 'package:movie_watchlist/pages/movie_detail_page.dart'; 

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final GlobalKey<NavigatorState>? navigatorKey;

  NotificationService({this.navigatorKey});

  Future<void> initNotifications() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final String? fcmToken;
    if (kIsWeb) {
      fcmToken = await _fcm.getToken(
        vapidKey: "BGD4vReWoafMTP_El6TA8WxrA_QQlY9PT2nXHR3O6yBlzEOpwQcdUkRu1oHmSaiE8k4oh1ksmaWXXz5Ntzs6gF8",
      );
    } else {
      fcmToken = await _fcm.getToken();
    }

    if (kDebugMode) {
      print('=======================================');
      print('FCM Token: $fcmToken');
      print('=======================================');
    }

    if (fcmToken != null) {
      await _saveTokenToDatabase(fcmToken);
    }

    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);
    await _setupMessageListeners();
  }

  Future<void> _saveTokenToDatabase(String token) async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set(
          {
            'fcmToken': token,
          },
          SetOptions(merge: true),
        );
        if (kDebugMode) {
          print('FCM Token berhasil disimpan ke Firestore.');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error menyimpan FCM Token: $e');
        }
      }
    }
  }

  void _handleMessage(RemoteMessage? message) {
    if (message == null) return;
    
    if (message.data['movieId'] != null) {
      final movieId = message.data['movieId'];
      
      if (navigatorKey != null) {
        navigatorKey!.currentState?.push(
          MaterialPageRoute(
            // GANTI 'MovieDetailPage' DENGAN NAMA HALAMAN ANDA
            builder: (context) => Scaffold( // Hapus Scaffold ini jika MovieDetailPage sudah punya Scaffold
              body: Center(
                child: Text('Buka Halaman Detail untuk Movie ID: $movieId'),
                // child: MovieDetailPage(movieId: movieId),
              ),
            ),
          ),
        );
      }
    }
    
    if (kDebugMode) {
      print('Notifikasi diterima!');
      print('Judul: ${message.notification?.title}');
      print('Isi: ${message.notification?.body}');
      print('Data: ${message.data}');
    }
  }

  Future<void> _setupMessageListeners() async {
    FirebaseMessaging.instance.getInitialMessage().then(_handleMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('--- Notifikasi Foreground Diterima ---');
        _handleMessage(message);
        print('--------------------------------------');
      }
    });
  }
}