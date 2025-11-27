// lib/pages/watchlist_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:movie_watchlist/pages/movie_detail_page.dart';
import 'package:movie_watchlist/ui/movie_card.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  void _navigateToDetail(int movieId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailPage(movieId: movieId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return _buildEmptyView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist Saya'),
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
            return _buildEmptyView();
          }

          final items = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.6,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index].data();
              final movieId = int.parse(items[index].id);
              final bool isMovie = true;

              return GestureDetector(
                onTap: () => _navigateToDetail(movieId),
                child: MovieCard(item: item, isMovie: isMovie),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_remove_outlined,
            size: 80,
            color: Colors.grey[800],
          ),
          const SizedBox(height: 16),
          Text(
            'Watchlist kamu masih kosong',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}