import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movie_watchlist/constants.dart';

import 'package:movie_watchlist/ui/detail_header.dart';
import 'package:movie_watchlist/ui/detail_info.dart';
import 'package:movie_watchlist/ui/detail_action_buttons.dart';

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

  double _appGlobalRating = 0.0;
  int _appVoteCount = 0;

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
      final futures = <Future>[
        _fetchMovieData(),
        _fetchAppGlobalRating(),
      ];
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

  Future<void> _fetchAppGlobalRating() async {
    try {
      final doc = await _firestore
          .collection('movies')
          .doc(widget.movieId.toString())
          .get();

      if (doc.exists) {
        setState(() {
          // Ambil rata-rata dan jumlah vote, default ke 0 jika belum ada
          _appGlobalRating = (doc.data()?['app_vote_average'] as num?)?.toDouble() ?? 0.0;
          _appVoteCount = (doc.data()?['app_vote_count'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetch global rating: $e');
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
          'title':  _movieData?['title'] ?? _movieData?['name'],
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

  Future<void> _saveRating(int newRating) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final String movieIdStr = widget.movieId.toString();
    
    // Referensi Dokumen Personal
    final userRatingRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('ratings')
        .doc(movieIdStr);

    // Referensi Dokumen Global (Rata-rata Aplikasi)
    final movieGlobalRef = _firestore.collection('movies').doc(movieIdStr);

    // Update UI lokal sementara supaya responsif
    setState(() {
      _userRating = newRating;
    });

    try {
      await _firestore.runTransaction((transaction) async {
        final movieSnapshot = await transaction.get(movieGlobalRef);
        
        final userRatingSnapshot = await transaction.get(userRatingRef);
        int oldRating = 0;
        bool isUpdate = false;
        
        if (userRatingSnapshot.exists) {
          oldRating = (userRatingSnapshot.data()?['score'] as num?)?.toInt() ?? 0;
          isUpdate = true;
        }

        double currentAverage = 0.0;
        int currentCount = 0;

        if (movieSnapshot.exists) {
          currentAverage = (movieSnapshot.data()?['app_vote_average'] as num?)?.toDouble() ?? 0.0;
          currentCount = (movieSnapshot.data()?['app_vote_count'] as num?)?.toInt() ?? 0;
        }

        double newAverage;
        int newCount;

        if (isUpdate) {
          if (currentCount > 0) {
            double totalScore = (currentAverage * currentCount) - oldRating + newRating;
            newAverage = totalScore / currentCount;
            newCount = currentCount; 
          } else {
            newAverage = newRating.toDouble();
            newCount = 1;
          }
        } else {
          double totalScore = (currentAverage * currentCount) + newRating;
          newCount = currentCount + 1;
          newAverage = totalScore / newCount;
        }

        transaction.set(userRatingRef, {
          'score': newRating,
          'ratedAt': Timestamp.now(),
        });

        transaction.set(movieGlobalRef, {
          'app_vote_average': newAverage,
          'app_vote_count': newCount,
          'title': _movieData?['title'] ?? _movieData?['name'],
          'poster_path': _movieData?['poster_path'],
        }, SetOptions(merge: true));
      });
      
      _fetchAppGlobalRating();

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
    for(final e in _movieData!.keys){
      debugPrint('${e} : ${_movieData![e]}');
    }
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
          DetailHeader(
            posterPath: posterPath,
            title: title,
            tmdbRating: voteAverage,
            appRating: _appGlobalRating,
            appVoteCount: _appVoteCount,
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailInfo(
                  year: year,
                  runtime: runtime,
                  genres: genres,
                  overview: overview,
                ),
                
                const SizedBox(height: 24),

                DetailActionButtons(
                  userRating: _userRating,
                  isInWatchlist: _isInWatchlist,
                  onRatingPressed: _showRatingDialog,
                  onWatchlistPressed: _toggleWatchlist,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}