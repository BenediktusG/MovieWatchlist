// Lokasi file: lib/pages/watchlist_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:movie_watchlist/pages/movie_detail_page.dart';

// <--- IMPOR UI COMPONENT KITA
import 'package:movie_watchlist/ui/watchlist_view.dart'; 

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  // Dependencies
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // <--- LOGIKA NAVIGASI (Sama seperti search_page)
  void _navigateToDetail(int movieId, bool isMovie) {
    if (movieId == 0) return; // Validasi sederhana
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailPage(
          movieId: movieId,
          isMovie: isMovie,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Cek User Login
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Silakan login terlebih dahulu")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist Saya'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      
      // 2. LOGIKA DATA (StreamBuilder)
      // Page bertanggung jawab mengambil data, bukan UI
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('users')
            .doc(user.uid)
            .collection('watchlist')
            .orderBy('addedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // A. Handle Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // B. Handle Error
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi error: ${snapshot.error}'));
          }

          // C. Transformasi Data
          // Mengubah format Firestore QuerySnapshot menjadi List biasa
          // agar UI (WatchlistView) tidak perlu tahu soal Firestore.
          final List<Map<String, dynamic>> processedItems = 
              snapshot.data?.docs.map((doc) {
            final data = doc.data();
            // PENTING: Masukkan ID dokumen ke dalam map data
            // agar bisa dibaca oleh UI
            data['id'] = doc.id; 
            return data;
          }).toList() ?? [];

          // 3. PANGGIL UI (View)
          return WatchlistView(
            items: processedItems,
            onItemTap: _navigateToDetail, // Oper fungsi navigasi ke UI
          );
        },
      ),
    );
  }
}