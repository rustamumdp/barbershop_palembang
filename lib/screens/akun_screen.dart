import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AkunScreen extends StatefulWidget {
  @override
  _AkunScreenState createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late User _currentUser;
  late DocumentSnapshot _userProfile;
  late QuerySnapshot _userPosts;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _currentUser = _auth.currentUser!;
    _userProfile = await _firestore.collection('users').doc(_currentUser.uid).get();
    _userPosts = await _firestore.collection('posts').where('userId', isEqualTo: _currentUser.uid).get();

    setState(() {
      isLoading = false;
    });
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
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(_userProfile['photoUrl']),
            ),
            SizedBox(height: 16),
            Text(
              'Nama Pengguna: ${_userProfile['username']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Email: ${_currentUser.email}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            Text(
              'Postingan yang Diunggah',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _userPosts.size == 0
                ? Center(child: Text('Belum ada postingan yang diunggah'))
                : Column(
              children: _userPosts.docs.map((doc) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(doc['text']),
                    subtitle: Text(doc['formattedDate']),
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(doc['imageUrl']),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}