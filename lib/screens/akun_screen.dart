import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:barbershopplg/screens/detail_screen.dart';

class AkunScreen extends StatefulWidget {
  @override
  _AkunScreenState createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

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
    setState(() {
      isLoading = true;
    });
    try {
      _currentUser = _auth.currentUser!;
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_currentUser.uid).get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>?;

        if (userData != null && userData.containsKey('photoUrl')) {
          _userProfile = userDoc;
          _userPosts = await _firestore.collection('posts').where('userId', isEqualTo: _currentUser.uid).get();
        } else {
          print('Document does not exist or photoUrl field is missing');
        }
      } else {
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

  Future<void> _changeProfilePicture() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        File file = File(pickedFile.path);
        String fileName = 'profile_pictures/${_currentUser.uid}.jpg';
        TaskSnapshot uploadTask = await _storage.ref().child(fileName).putFile(file);

        String downloadUrl = await uploadTask.ref.getDownloadURL();

        await _firestore.collection('users').doc(_currentUser.uid).update({'photoUrl': downloadUrl});

        // Reload user data after updating profile picture
        await _loadData();
      }
    } catch (e) {
      print('Error updating profile picture: $e');
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
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _userProfile != null && _userProfile!['photoUrl'] != null
                        ? NetworkImage(_userProfile!['photoUrl'])
                        : AssetImage('assets/images/default_profile.png') as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.camera_alt, color: Colors.blue),
                      onPressed: _changeProfilePicture,
                    ),
                  ),
                ],
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
