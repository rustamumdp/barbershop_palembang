import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barbershopplg/screens/sign_in_screen.dart';
import 'package:barbershopplg/screens/add_post_screen.dart';
import 'package:barbershopplg/screens/detail_screen.dart';
import 'package:barbershopplg/screens/favorite_screen.dart'; // Import FavoriteScreen
import 'package:barbershopplg/screens/akun_screen.dart'; // Import AkunScreen

class HomeScreen extends StatelessWidget {
  final Function(ThemeMode) onThemeChanged; // Callback untuk mengubah tema

  const HomeScreen({Key? key, required this.onThemeChanged}) : super(key: key);

  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda Barbershop Palembang'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        actions: [
          IconButton(
            onPressed: () {
              signOut(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Beranda'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FavoriteScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle), // Icon untuk menuju halaman akun
              title: const Text('Profil'), // Judul untuk menuju halaman akun
              onTap: () {
                Navigator.pop(context); // Tutup drawer saat menu dipilih
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AkunScreen()), // Navigasi ke AkunScreen
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Mode Terang'),
              onTap: () {
                onThemeChanged(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_2),
              title: const Text('Mode Gelap'),
              onTap: () {
                onThemeChanged(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('Mode Sistem'),
              onTap: () {
                onThemeChanged(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Tidak ada postingan tersedia'));
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var post = snapshot.data!.docs[index];
              var data = post.data() as Map<String, dynamic>;
              var postTime = data['timestamp'] as Timestamp;
              var date = postTime.toDate();
              var formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';

              var username = data.containsKey('username') ? data['username'] : 'Anonim';
              var imageUrl = data.containsKey('image_url') ? data['image_url'] : '';
              var text = data.containsKey('text') ? data['text'] : '';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(
                        postId: post.id,
                        username: username,
                        imageUrl: imageUrl,
                        text: text,
                        formattedDate: formattedDate,
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.all(4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl.isNotEmpty)
                        Expanded(
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Text('Gagal memuat gambar'));
                            },
                          ),
                        )
                      else
                        const Expanded(
                          child: Center(child: Text('Gambar tidak tersedia')),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                color: Colors.lightBlueAccent,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPostScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
