import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movie_watchlist/constants.dart';
import 'package:url_launcher/url_launcher.dart'; 

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

    // Request data dengan translations dan video support EN+ID
    final response = await http.get(Uri.parse(
        '$tmdbBaseUrl/$endpoint/${widget.movieId}?api_key=$tmdbApiKey&language=id-ID&append_to_response=credits,videos,translations&include_video_language=en,id'
    ));

    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
           _movieData = json.decode(response.body);
        });
      }
    } else {
      throw Exception('Gagal memuat data film');
    }
  }

  Future<void> _launchTrailer() async {
    final videos = _movieData?['videos']?['results'] as List?;
    if (videos == null || videos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trailer tidak tersedia')),
      );
      return;
    }

    final trailer = videos.firstWhere(
      (v) => v['site'] == 'YouTube' && v['type'] == 'Trailer',
      orElse: () => null,
    );

    final videoToPlay = trailer ?? videos.firstWhere(
      (v) => v['site'] == 'YouTube', 
      orElse: () => null
    );

    if (videoToPlay != null) {
      final String key = videoToPlay['key'];
      final Uri url = Uri.parse('https://www.youtube.com/watch?v=$key');
      
      try {
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
           throw Exception('Could not launch $url');
        }
      } catch (e) {
        debugPrint("Error launching URL: $e");
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuka YouTube')),
          );
        }
      }
    } else {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video tidak ditemukan')),
        );
      }
    }
  }

  Future<void> _fetchWatchlistStatus(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).collection('watchlist').doc(widget.movieId.toString()).get();
      if (mounted) setState(() { _isInWatchlist = doc.exists; });
    } catch (e) { debugPrint("Error watchlist: $e"); }
  }

  Future<void> _fetchRatingStatus(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).collection('ratings').doc(widget.movieId.toString()).get();
      if (doc.exists && mounted) { 
        setState(() { _userRating = (doc.data()?['score'] as num?)?.toInt() ?? 0; }); 
      }
    } catch (e) { debugPrint("Error rating status: $e"); }
  }

  Future<void> _fetchAppGlobalRating() async {
    try {
      final doc = await _firestore.collection('movies').doc(widget.movieId.toString()).get();
      if (doc.exists && mounted) {
        setState(() {
          _appGlobalRating = (doc.data()?['app_vote_average'] as num?)?.toDouble() ?? 0.0;
          _appVoteCount = (doc.data()?['app_vote_count'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (e) { debugPrint('Error fetch global rating: $e'); }
  }

  Future<void> _toggleWatchlist() async {
     final user = _auth.currentUser;
     if (user == null) return;
     final docRef = _firestore.collection('users').doc(user.uid).collection('watchlist').doc(widget.movieId.toString());
     final newState = !_isInWatchlist;
     setState(() { _isInWatchlist = newState; });
     try {
       if (newState) {
         await docRef.set({
           'addedAt': Timestamp.now(),
           'title':  _movieData?['title'] ?? _movieData?['name'],
           'poster_path': _movieData?['poster_path'],
         });
       } else { await docRef.delete(); }
     } catch (e) {
       setState(() { _isInWatchlist = !newState; });
     }
  }

  Future<void> _saveRating(int newRating) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final String movieIdStr = widget.movieId.toString();
    final userRatingRef = _firestore.collection('users').doc(user.uid).collection('ratings').doc(movieIdStr);
    final movieGlobalRef = _firestore.collection('movies').doc(movieIdStr);

    setState(() { _userRating = newRating; });

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
    } catch (e) { debugPrint('Gagal menyimpan rating: $e'); }
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
                    icon: Icon(index < localRating ? Icons.star : Icons.star_border, color: Colors.blue[300], size: 32),
                    onPressed: () { setDialogState(() { localRating = index + 1; }); },
                  );
                }),
              ),
              actions: [
                TextButton(child: Text('Batal', style: TextStyle(color: Colors.grey[400])), onPressed: () => Navigator.pop(context)),
                TextButton(child: const Text('Simpan', style: TextStyle(color: Colors.blue)), onPressed: () { _saveRating(localRating); Navigator.pop(context); }),
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
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  String _getCrewName(List crewList, String job) {
    if (crewList.isEmpty) return '-';
    
    final filtered = crewList.where((c) {
      final cJob = c['job'] as String?;
      final cDept = c['department'] as String?;
      return cJob == job || cDept == 'Writing';
    }).toList();

    if (filtered.isEmpty) return '-';
    return filtered.take(2).map((c) => c['name']?.toString() ?? 'Unknown').join(', ');
  }

  Widget _buildCrewInfo() {
    final credits = _movieData?['credits'];
    if (credits == null) return const SizedBox.shrink();
    final List crew = credits['crew'] ?? [];
    
    final String director = _getCrewName(crew, 'Director');
    
    String writer = '-';
    try {
      final writerEntry = crew.firstWhere(
          (c) => c['job'] == 'Screenplay' || c['job'] == 'Writer' || c['job'] == 'Story', 
          orElse: () => null
      );
      if (writerEntry != null) {
        writer = writerEntry['name']?.toString() ?? '-';
      }
    } catch (e) {
      writer = '-';
    }
    
    if (director == '-' && writer == '-') {
       return const SizedBox.shrink();
    }

    return Column(
      children: [
        const Divider(color: Colors.white24, height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sutradara", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(director, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
            
            const SizedBox(width: 24), 

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Penulis", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(writer, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
        const Divider(color: Colors.white24, height: 32),
      ],
    );
  }

  Widget _buildContent() {
    final String posterPath = _movieData!['poster_path'] ?? '';
    final String title = _movieData!['title'] ?? _movieData!['name'] ?? 'No Title';
    final double voteAverage = (_movieData!['vote_average'] as num?)?.toDouble() ?? 0.0;
    final String releaseDate = _movieData!['release_date'] ?? _movieData!['first_air_date'] ?? ''; 
    final String year = releaseDate.isNotEmpty ? releaseDate.split('-')[0] : 'N/A';

    int runtime = 0;
    if (widget.isMovie) {
       runtime = _movieData!['runtime'] ?? 0;
    } else {
       final List runtimes = _movieData!['episode_run_time'] ?? [];
       if (runtimes.isNotEmpty) runtime = runtimes[0];
    }
    
    String genres = '-';
    if (_movieData!['genres'] != null) {
       genres = (_movieData!['genres'] as List).map((g) => g['name'] as String).join(', ');
    }

    // ID -> EN -> No Result
    String overview = _movieData!['overview'] as String? ?? '';

    // 1. Jika kosong, cek Translations
    if (overview.isEmpty) {
      final translations = _movieData!['translations']?['translations'] as List?;
      if (translations != null) {
        final enTranslation = translations.firstWhere(
          (t) => t['iso_639_1'] == 'en',
          orElse: () => null,
        );
        if (enTranslation != null) {
          overview = enTranslation['data']['overview'] ?? '';
        }
      }
    }

    // 2. Jika masih kosong, baru pakai teks default
    if (overview.isEmpty) {
      overview = 'Sinopsis belum tersedia.';
    }

    return Column(
      children: [
        // AREA KONTEN (SCROLLABLE)
        Expanded(
          child: SingleChildScrollView(
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
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _launchTrailer,
                          icon: const Icon(Icons.play_circle_fill),
                          label: const Text('Tonton Trailer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      DetailInfo(
                        year: year,
                        runtime: runtime,
                        genres: genres,
                        overview: overview,
                      ),
                      
                      _buildCrewInfo(),

                      const SizedBox(height: 16),
                      const Text(
                        "Pemain", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                      ),
                      const SizedBox(height: 12),
                      
                      _buildCastList(),

                      const SizedBox(height: 16), 
                    ],
                  ),
                )
              ],
            ),
          ),
        ),

        // AREA TOMBOL (STICKY)
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.black, 
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, -5), 
              ),
            ],
            border: const Border(top: BorderSide(color: Colors.white10)) 
          ),
          child: DetailActionButtons(
            userRating: _userRating,
            isInWatchlist: _isInWatchlist,
            onRatingPressed: _showRatingDialog,
            onWatchlistPressed: _toggleWatchlist,
          ),
        ),
      ],
    );
  }

  Widget _buildCastList() {
    final credits = _movieData?['credits'];
    if (credits == null) return const Text("Info pemain tidak tersedia", style: TextStyle(color: Colors.grey));
    
    final List cast = credits['cast'] ?? [];
    if (cast.isEmpty) {
      return const Text("Info pemain tidak tersedia", style: TextStyle(color: Colors.grey));
    }

    return SizedBox(
      height: 110, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cast.length > 10 ? 10 : cast.length, 
        itemBuilder: (context, index) {
          final actor = cast[index];
          final String name = actor['name'] ?? 'Unknown';
          final String character = actor['character'] ?? '-';

          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  character, 
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12, 
                    color: Colors.grey[400],
                    height: 1.2,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}