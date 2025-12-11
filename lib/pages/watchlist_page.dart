import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:movie_watchlist/pages/movie_detail_page.dart';
import 'package:movie_watchlist/ui/watchlist_view.dart'; 

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  void _navigateToDetail(int movieId, bool isMovie) {
    if (movieId == 0) return; 
    
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
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Silakan login terlebih dahulu")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Watchlist',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('users')
            .doc(user.uid)
            .collection('watchlist')
            .orderBy('addedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Watchlist masih kosong'));
          }

          final List<Map<String, dynamic>> processedItems = snapshot.data!.docs.map((doc) {
            final data = doc.data();
            data['id'] = int.tryParse(doc.id) ?? 0;
            bool isMovie = true;
            if (data.containsKey('isMovie')) {
               isMovie = data['isMovie'] == true;
            }
            data['isMovie'] = isMovie;

            return data;
          }).toList();

          return WatchlistView(
            items: processedItems,
            onItemTap: _navigateToDetail, 
          );
        },
      ),
    );
  }
}