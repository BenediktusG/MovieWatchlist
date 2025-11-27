// lib/pages/movie_detail_page.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movie_watchlist/constants.dart';

class MovieDetailPage extends StatefulWidget {
  final int movieId;
  final bool isMovie;

  const MovieDetailPage({
    super.key,
    required this.movieId,
    this.isMovie = true,
  });

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _movieData;
  bool _isInWatchlist = false;
  int _userRating = 0;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    final user = _auth.currentUser;
    final uid = user?.uid;

    try {
      final futures = <Future>[_fetchMovieData()];
      if (uid != null) {
        futures.add(_fetchWatchlistStatus(uid));
        futures.add(_fetchRatingStatus(uid));
      }
      await Future.wait(futures);
    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMovieData() async {
    final String endpoint = widget.isMovie ? 'movie' : 'tv';

    final response = await http.get(Uri.parse(
        '$tmdbBaseUrl/$endpoint/${widget.movieId}?api_key=$tmdbApiKey&language=id-ID'
    ));

    if (response.statusCode == 200) {
      _movieData = json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data film');
    }
  }

  Future<void> _fetchWatchlistStatus(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('watchlist')
        .doc(widget.movieId.toString())
        .get();
    _isInWatchlist = doc.exists;
  }

  Future<void> _fetchRatingStatus(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('ratings')
        .doc(widget.movieId.toString())
        .get();
    if (doc.exists) {
      _userRating = (doc.data()?['score'] as num?)?.toInt() ?? 0;
    }
  }

  Future<void> _toggleWatchlist() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('watchlist')
        .doc(widget.movieId.toString());

    final newState = !_isInWatchlist;
    setState(() {
      _isInWatchlist = newState;
    });

    try {
      if (newState) {
        await docRef.set({
          'addedAt': Timestamp.now(),
          'title': _movieData?['title'],
          'poster_path': _movieData?['poster_path'],
        });
      } else {
        await docRef.delete();
      }
    } catch (e) {
      setState(() {
        _isInWatchlist = !newState;
      });
      debugPrint('Gagal update watchlist: $e');
    }
  }

  Future<void> _saveRating(int rating) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('ratings')
        .doc(widget.movieId.toString());

    setState(() {
      _userRating = rating;
    });

    try {
      await docRef.set({
        'score': rating,
        'ratedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Gagal menyimpan rating: $e');
    }
  }

  Future<void> _showRatingDialog() async {
    int localRating = _userRating;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('Beri Rating', style: TextStyle(color: Colors.white)),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < localRating ? Icons.star : Icons.star_border,
                      color: Colors.blue[300],
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        localRating = index + 1;
                      });
                    },
                  );
                }),
              ),
              actions: [
                TextButton(
                  child: Text('Batal', style: TextStyle(color: Colors.grey[400])),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text('Simpan', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    _saveRating(localRating);
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _movieData == null
              ? const Center(child: Text('Gagal memuat film'))
              : Stack(
                  children: [
                    _buildContent(),
                    _buildBackButton(),
                  ],
                ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 40,
      left: 16,
      child: CircleAvatar(
        backgroundColor: Colors.black.withOpacity(0.5),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final String posterPath = _movieData!['poster_path'] ?? '';
    final String title = _movieData!['title'] ?? _movieData!['name'] ?? '';

    final double voteAverage = (_movieData!['vote_average'] as num).toDouble();

    // Film pakai 'release_date', tv series pakai 'first_air_date'
    final String releaseDate = _movieData!['release_date'] ?? _movieData!['first_air_date'] ?? ''; 
    final String year = releaseDate.isNotEmpty ? releaseDate.split('-')[0] : 'N/A';

    // Hitung durasi (TV biasanya pakai episode_run_time yang berupa List)
    int runtime = 0;
    if (widget.isMovie) {
       runtime = _movieData!['runtime'] ?? 0;
    } else {
       final List runtimes = _movieData!['episode_run_time'] ?? [];
       if (runtimes.isNotEmpty) runtime = runtimes[0];
    }
    
    final String genres = (_movieData!['genres'] as List)
        .map((g) => g['name'] as String)
        .join(', ');

    final String overview = _movieData!['overview'] ?? 'Tidak ada sinopsis';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(posterPath, title, voteAverage),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetadataRow(year, runtime, genres),
                const SizedBox(height: 24),
                _buildSynopsis(overview),
                const SizedBox(height: 24),
                _buildRatingButton(),
                const SizedBox(height: 16),
                _buildWatchlistButton(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader(String posterPath, String title, double voteAverage) {
    return Stack(
      children: [
        Image.network(
          '$imageBaseUrl$posterPath',
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
        ),
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  '$imageBaseUrl$posterPath',
                  height: 120,
                  width: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.yellow[700], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          voteAverage.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(String year, int runtime, String genres) {
    return Row(
      children: [
        Text(year, style: TextStyle(color: Colors.grey[400])),
        const SizedBox(width: 8),
        Text('•', style: TextStyle(color: Colors.grey[400])),
        const SizedBox(width: 8),
        Text('$runtime min', style: TextStyle(color: Colors.grey[400])),
        const SizedBox(width: 8),
        Text('•', style: TextStyle(color: Colors.grey[400])),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            genres,
            style: TextStyle(color: Colors.grey[400]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSynopsis(String overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sinopsis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          overview,
          style: TextStyle(color: Colors.grey[300], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildRatingButton() {
    final bool hasRating = _userRating > 0;
    final int rating = _userRating;

    return OutlinedButton(
      onPressed: _showRatingDialog,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: Colors.grey[800]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.blue[300]),
          const SizedBox(width: 12),
          Text(
            hasRating ? 'Rating Anda: $rating Bintang' : 'Beri Rating',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: index < rating ? Colors.blue[300] : Colors.grey,
                size: 20,
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildWatchlistButton() {
    return ElevatedButton(
      onPressed: _toggleWatchlist,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isInWatchlist ? Colors.grey[800] : Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isInWatchlist ? Icons.check : Icons.add,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            _isInWatchlist ? 'Sudah di Watchlist' : 'Tambah ke Watchlist',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}