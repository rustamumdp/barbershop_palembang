import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barbershopplg/screens/detail_screen.dart';

class AkunScreen extends StatefulWidget {
  @override
  _AkunScreenState createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late User _currentUser;
  DocumentSnapshot? _userProfile;
  QuerySnapshot? _userPosts;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _currentUser = _auth.currentUser!;
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_currentUser.uid).get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>?;

        // Periksa apakah userData tidak null dan memiliki kunci 'photoUrl'
        if (userData != null && userData.containsKey('photoUrl')) {
          _userProfile = userDoc;
          _userPosts = await _firestore.collection('posts').where('userId', isEqualTo: _currentUser.uid).get();
        } else {
          // Handle case where 'photoUrl' field is missing or userDoc.data() is null
          print('Document does not exist or photoUrl field is missing');
        }
      } else {
        // Handle case where document doesn't exist
        print('Document does not exist');
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _userProfile != null
                    ? NetworkImage(_userProfile!['photoUrl'])
                    : AssetImage('assets/images/default_profile.png') as ImageProvider,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              _currentUser.displayName ?? '',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              _currentUser.email ?? '',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 16.0),
            Text(
              'Postingan Saya',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            _buildUserPosts(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserPosts() {
    if (_userPosts == null || _userPosts!.docs.isEmpty) {
      return Center(
        child: Text('Belum ada postingan'),
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: _userPosts!.docs.length,
        itemBuilder: (context, index) {
          var post = _userPosts!.docs[index];
          var data = post.data() as Map<String, dynamic>;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(
                    postId: post.id,
                    username: _currentUser.displayName ?? 'Anonim',
                    imageUrl: data['image_url'] ?? '',
                    text: data['text'] ?? '',
                    formattedDate: '${data['timestamp']}',
                  ),
                ),
              );
            },
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                data['image_url'] ?? '',
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      );
    }
  }
}
