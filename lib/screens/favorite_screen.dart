import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barbershopplg/screens/home_screen.dart';
import 'package:barbershopplg/screens/detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;

  const FavoriteScreen({Key? key, this.onThemeChanged}) : super(key: key);

  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
          ],
        ),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<DocumentSnapshot>>(
            future: _fetchFavorites(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Belum ada postingan favorit'));
              }

              List<DocumentSnapshot> favoritePosts = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.only(top: 56.0), // Jarak dari AppBar kustom
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.9, // Sesuaikan dengan aspek rasio item
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: favoritePosts.length,
                  itemBuilder: (context, index) {
                    var data = favoritePosts[index].data() as Map<String, dynamic>;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(
                              postId: favoritePosts[index].id,
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
              );
            },
          ),
          // Custom AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Theme.of(context).primaryColor,
              height: 56.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            HomeScreen(onThemeChanged: widget.onThemeChanged ?? (theme) {})),
                      );
                    },
                  ),
                  const Text(
                    'Postingan Favorit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 48), // Space holder to balance the layout
                ],
              ),
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
}
