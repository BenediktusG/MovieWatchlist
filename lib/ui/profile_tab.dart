import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:movie_watchlist/pages/profile_page.dart';
import 'package:movie_watchlist/pages/select_genre_page.dart';
import 'package:provider/provider.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // State untuk mengontrol halaman mana yang tampil
  bool _isShowingGenrePage = false;

  // Fungsi untuk menyimpan genre baru ke Firestore
  Future<void> _saveGenres(Set<String> newGenres) async {
    // Tampilkan loading
    setState(() {
      _isShowingGenrePage = false; // Kembali ke profil
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'favoriteGenres': newGenres.toList(),
      });
    } catch (e) {
      // Handle error (misal: tampilkan snackbar)
      debugPrint('Gagal menyimpan genre: $e');
      // Jika gagal, mungkin kita harus kembali ke halaman genre
      // setState(() {
      //   _isShowingGenrePage = true;
      // });
    }
  }

  // Fungsi untuk menampilkan halaman genre
  void _showGenrePage() {
    setState(() {
      _isShowingGenrePage = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data user dari Provider
    final doc = Provider.of<DocumentSnapshot<Map<String, dynamic>>?>(context);
    final data = doc?.data();

    // Ambil data genre dari provider
    // Kita asumsikan data disimpan sebagai List<dynamic> atau List<String>
    final List<dynamic> genreList = data?['favoriteGenres'] ?? [];
    final Set<String> favoriteGenres = genreList
        .map((e) => e.toString())
        .toSet();

    if (_isShowingGenrePage) {
      // Tampilkan halaman pilih genre
      return SelectGenrePage(
        initialGenres: favoriteGenres,
        onSave: _saveGenres, // Berikan fungsi callback
      );
    } else {
      // Tampilkan halaman profil
      return ProfilePage(
        favoriteGenres: favoriteGenres, // Berikan data genre
        onSelectGenre: _showGenrePage, // Berikan fungsi callback
      );
    }
  }
}
