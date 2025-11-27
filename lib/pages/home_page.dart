// Lokasi file: lib/pages/home.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movie_watchlist/constants.dart';
// import 'package:movie_watchlist/ui/movie_card.dart';
import 'package:movie_watchlist/pages/movie_detail_page.dart';
import 'package:movie_watchlist/ui/home_search_bar.dart';
import 'package:movie_watchlist/ui/movie_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _popularMovies = [];
  List<dynamic> _nowPlayingMovies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final popularResponse = await http.get(Uri.parse(
          '$tmdbBaseUrl/movie/popular?api_key=$tmdbApiKey&language=id-ID'));
          
      final nowPlayingResponse = await http.get(Uri.parse(
          '$tmdbBaseUrl/movie/now_playing?api_key=$tmdbApiKey&language=id-ID'));

      if (popularResponse.statusCode == 200 &&
          nowPlayingResponse.statusCode == 200) {
        setState(() {
          _popularMovies = json.decode(popularResponse.body)['results'];
          _nowPlayingMovies = json.decode(nowPlayingResponse.body)['results'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HomeSearchBar(),
                    MovieSection(
                      title: 'Sedang Populer',
                      movies: _popularMovies,
                      onMovieTap: _navigateToDetail, 
                    ),
                    MovieSection(
                      title: 'Rilis Terbaru',
                      movies: _nowPlayingMovies,
                      onMovieTap: _navigateToDetail, 
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}