// lib/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Ganti dengan halaman detail Anda
// import 'package:movie_watchlist/pages/movie_detail_page.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final GlobalKey<NavigatorState>? navigatorKey;

  NotificationService({this.navigatorKey});

  Future<void> initNotifications() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    final String? fcmToken;
    if (kIsWeb) {
      fcmToken = await _fcm.getToken(vapidKey: dotenv.env['VAPID_KEY']);
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
  }

  Future<void> _saveTokenToDatabase(String token) async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmTokens': FieldValue.arrayUnion([token]),
        }, SetOptions(merge: true));
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
}
