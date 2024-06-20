import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barbershopplg/screens/sign_in_screen.dart';
import 'package:barbershopplg/screens/add_post_screen.dart';
import 'package:barbershopplg/screens/detail_screen.dart';
import 'package:barbershopplg/screens/favorite_screen.dart'; // Import FavoriteScreen
import 'package:barbershopplg/screens/akun_screen.dart'; // Import AkunScreen

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged; // Callback untuk mengubah tema

  const HomeScreen({Key? key, required this.onThemeChanged}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late List<DocumentSnapshot> _posts;
  late List<DocumentSnapshot> _filteredPosts;
  TextEditingController _searchController = TextEditingController(); // Controller untuk TextField pencarian

  @override
  void initState() {
    super.initState();
    _fetchPosts().then((posts) {
      setState(() {
        _posts = posts;
        _filteredPosts = _posts;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose(); // Pastikan untuk membuang controller setelah tidak digunakan
    super.dispose();
  }

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
        backgroundColor: Colors.pink,
        actions: [
          if (_searchController.text.isNotEmpty) // Menampilkan icon clear hanya jika ada teks pencarian
            IconButton(
              onPressed: () {
                _searchController.clear();
                _filterPosts('');
              },
              icon: Icon(Icons.clear),
              color: Colors.black, // Warna ikon 'x' (hapus pencarian)
            ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Cari Postingan'),
                  content: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _filterPosts(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Masukkan kata kunci',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () {
                        _filterPosts(_searchController.text);
                        Navigator.of(context).pop();
                      },
                      child: Text('Cari'),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(Icons.search),
            color: Colors.black, // Warna ikon pencarian
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.pinkAccent,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
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
                widget.onThemeChanged(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_2),
              title: const Text('Mode Gelap'),
              onTap: () {
                widget.onThemeChanged(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('Mode Sistem'),
              onTap: () {
                widget.onThemeChanged(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Konfirmasi Logout'),
                    content: Text('Apakah Anda yakin ingin logout?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          signOut(context);
                        },
                        child: Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: _buildPostsList(),
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

  Widget _buildPostsList() {
    if (_filteredPosts.isEmpty) {
      return const Center(child: Text('Tidak ada postingan tersedia'));
    } else {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
        ),
        itemCount: _filteredPosts.length,
        itemBuilder: (context, index) {
          var post = _filteredPosts[index];
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
    }
  }

  Future<List<DocumentSnapshot>> _fetchPosts() async {
    var snapshot = await FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).get();
    return snapshot.docs;
  }

  void _filterPosts(String query) {
    List<DocumentSnapshot> filteredList = [];
    if (query.isNotEmpty) {
      filteredList = _posts.where((post) {
        var data = post.data() as Map<String, dynamic>;
        var username = data['username']?.toString().toLowerCase() ?? '';
        var text = data['text']?.toString().toLowerCase() ?? '';
        return username.contains(query.toLowerCase()) || text.contains(query.toLowerCase());
      }).toList();
    } else {
      filteredList = _posts;
    }

    setState(() {
      _filteredPosts = filteredList;
    });
  }
}
