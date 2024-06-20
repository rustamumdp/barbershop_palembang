import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barbershopplg/screens/home_screen.dart';
import 'package:barbershopplg/screens/detail_screen.dart';
import 'package:barbershopplg/screens/sign_in_screen.dart'; // Import Sign In Screen

class FavoriteScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;

  const FavoriteScreen({Key? key, this.onThemeChanged}) : super(key: key);

  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late List<DocumentSnapshot> _favoritePosts;
  late List<DocumentSnapshot> _filteredPosts;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchFavorites().then((favorites) {
      setState(() {
        _favoritePosts = favorites;
        _filteredPosts = _favoritePosts;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Beranda'),
              onTap: () {
                Navigator.pop(context); // Tutup drawer
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HomeScreen(onThemeChanged: widget.onThemeChanged ?? (theme) {}),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorit'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout), // Icon untuk logout
              title: const Text('Keluar'), // Judul untuk logout
              onTap: () async {
                await _auth.signOut(); // Logout dari Firebase Auth
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SignInScreen()), // Navigasi ke SignInScreen
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text('Postingan Favorit'),
        actions: [
          if (_searchController.text.isNotEmpty) // Menampilkan icon clear hanya jika ada teks pencarian
            IconButton(
              onPressed: () {
                _searchController.clear();
                _filterPosts('');
              },
              icon: Icon(Icons.clear),
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
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_filteredPosts.isEmpty)
            Center(
              child: Text('Belum ada postingan favorit'),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 56.0),
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: _filteredPosts.length,
                itemBuilder: (context, index) {
                  var data = _filteredPosts[index].data() as Map<String, dynamic>;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(
                            postId: _filteredPosts[index].id,
                            username: data['username'] ?? 'Anonim',
                            imageUrl: data['imageUrl'] ?? '',
                            text: data['text'] ?? '',
                            formattedDate: data['formattedDate'] ?? '',
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                data['imageUrl'] ?? '',
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(child: Text('Gagal memuat gambar'));
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['username'] ?? 'Anonim',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['text'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['formattedDate'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<List<DocumentSnapshot>> _fetchFavorites() async {
    User? user = _auth.currentUser;
    List<DocumentSnapshot> favorites = [];

    if (user != null) {
      String userId = user.uid;

      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();

      favorites = querySnapshot.docs;
    }

    return favorites;
  }

  void _filterPosts(String query) {
    List<DocumentSnapshot> filteredList = [];
    if (query.isNotEmpty) {
      filteredList = _favoritePosts.where((post) {
        var data = post.data() as Map<String, dynamic>;
        var username = data['username']?.toString().toLowerCase() ?? '';
        var text = data['text']?.toString().toLowerCase() ?? '';
        return username.contains(query.toLowerCase()) || text.contains(query.toLowerCase());
      }).toList();
    } else {
      filteredList = _favoritePosts;
    }

    setState(() {
      _filteredPosts = filteredList;
    });
  }
}
