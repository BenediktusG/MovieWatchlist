import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:movie_watchlist/firebase_options.dart';
import 'package:movie_watchlist/pages/profile_tab.dart';
import 'package:movie_watchlist/ui/auth_wrapper.dart';
import 'package:provider/provider.dart';
import 'pages/search_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:movie_watchlist/pages/home_page.dart';
import 'package:movie_watchlist/pages/watchlist_page.dart';
import 'package:movie_watchlist/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService(navigatorKey: navigatorKey).initNotifications();

  runApp(
    MultiProvider(
      providers: [
        StreamProvider<User?>(
          create: (_) => FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),

        StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>(
          create: (context) {
            return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
              if (user == null) {
                return Stream.value(null);
              }
              return FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots();
            });
          },
          initialData: null,
        ),
      ],
      child: WatchlistApp(),
    ),
  );
}

class WatchlistApp extends StatelessWidget {
  WatchlistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Watchlist',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black, // Background utama
        primarySwatch: Colors.blue,
        // Atur tema BottomNavigationBar agar sesuai
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.grey[900], // Background BNB
          selectedItemColor: Colors.blue, // Warna ikon aktif
          unselectedItemColor: Colors.grey[600], // Warna ikon tidak aktif
          type: BottomNavigationBarType.fixed, // Agar background terlihat
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Mulai di tab 'Home'

  // Buat halaman placeholder agar aplikasi bisa jalan
  static const List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    SearchPage(),
    WatchlistPage(),
    ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: 'Watchlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Widget placeholder sederhana
class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}
