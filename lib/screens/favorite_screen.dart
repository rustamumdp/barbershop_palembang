import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barbershopplg/screens/home_screen.dart';

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
                    builder: (context) => HomeScreen(onThemeChanged: widget.onThemeChanged ?? (theme) {}),
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
              return ListView.builder(
                padding: const EdgeInsets.only(top: 56.0), // Beri jarak untuk custom AppBar
                itemCount: favoritePosts.length,
                itemBuilder: (context, index) {
                  var data = favoritePosts[index].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['username'] ?? 'Anonim'),
                    subtitle: Text(data['text'] ?? ''),
                    trailing: Text(data['formattedDate'] ?? ''),
                  );
                },
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
                        MaterialPageRoute(builder: (context) => HomeScreen(onThemeChanged: widget.onThemeChanged ?? (theme) {})),
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
