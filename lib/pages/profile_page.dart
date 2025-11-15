import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  // 1. TAMBAHKAN PARAMETER INI
  final Set<String> favoriteGenres;
  final VoidCallback onSelectGenre;

  const ProfilePage({
    super.key,
    required this.favoriteGenres,
    required this.onSelectGenre,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // State untuk mengontrol switch notifikasi
  bool _isNotificationOn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotification();
  }

  // Fungsi untuk logout
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _loadNotification() async {
    // (Logika _loadNotification Anda tetap sama)
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (mounted) {
      setState(() {
        _isNotificationOn = doc.data()?['isNotificationOn'] ?? false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // (Logika build Anda untuk user, doc, data, email, username tetap sama)
    final user = Provider.of<User?>(context);
    final doc = Provider.of<DocumentSnapshot<Map<String, dynamic>>?>(context);
    final data = doc?.data();
    final String email = user?.email ?? 'user@example.com';
    final String username = data?['username'] ?? email.split('@').first;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProfileCard(username, email),
                  const SizedBox(height: 24),
                  _buildSettingsCard(), // Widget ini akan kita modifikasi
                  const SizedBox(height: 24),
                  _buildLogoutButton(),
                ],
              ),
            ),
    );
  }

  // (Widget _buildProfileCard tetap sama)
  Widget _buildProfileCard(String username, String email) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900], // Warna kartu
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          // Avatar
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 16),
          // Nama & Email
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. MODIFIKASI _buildSettingsCard
  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // (Bagian Notifikasi Film Baru tetap sama)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Pengaturan Notifikasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.notifications_none_outlined,
              color: Colors.grey[400],
            ),
            title: const Text('Notifikasi Film Baru'),
            trailing: Switch(
              value: _isNotificationOn,
              onChanged: (value) {
                setState(() {
                  _isNotificationOn = value;
                  final uid = FirebaseAuth.instance.currentUser!.uid;
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({'isNotificationOn': value});
                });
              },
              activeColor: Colors.blue,
              // Ganti activeThumbColor jadi activeColor
            ),
          ),
          Divider(color: Colors.grey[800], height: 1),

          // 3. UBAH BARIS PILIH GENRE FAVORIT
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.label_outline, color: Colors.grey[400]),
            title: const Text('Pilih Genre Favorit'),
            trailing: Text(
              // Ambil data dari widget
              '${widget.favoriteGenres.length} dipilih',
              style: TextStyle(color: Colors.blue[300], fontSize: 14),
            ),
            // Panggil fungsi callback dari widget
            onTap: widget.onSelectGenre,
          ),
        ],
      ),
    );
  }

  // (Widget _buildLogoutButton tetap sama)
  Widget _buildLogoutButton() {
    return InkWell(
      onTap: _logout,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
