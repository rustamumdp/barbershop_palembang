import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({Key? key}) : super(key: key);

  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Postingan Favorit'),
      ),
      body: FutureBuilder(
        future: _fetchFavorites(),
        builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Belum ada postingan favorit'));
          }

          List<DocumentSnapshot> favoritePosts = snapshot.data!;
          return ListView.builder(
            itemCount: favoritePosts.length,
            itemBuilder: (context, index) {
              var data = favoritePosts[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['username']),
                subtitle: Text(data['text']),
                trailing: Text(data['formattedDate']),
              );
            },
          );
        },
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
