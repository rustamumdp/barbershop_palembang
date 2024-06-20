import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailScreen extends StatefulWidget {
  final String postId;
  final String username;
  final String imageUrl;
  final String text;
  final String formattedDate;

  const DetailScreen({
    Key? key,
    required this.postId,
    required this.username,
    required this.imageUrl,
    required this.text,
    required this.formattedDate,
  }) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool showComments = true; // State to toggle showing comments
  bool isFavorite = false; // State to track favorite status

  Future<void> _toggleFavorite() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String userId = user.uid;

      // Check if this post is already in favorites
      DocumentSnapshot favoriteDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(widget.postId)
          .get();

      if (favoriteDoc.exists) {
        // Post is already in favorites, remove it
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc(widget.postId)
            .delete();
        setState(() {
          isFavorite = false;
        });
      } else {
        // Post is not in favorites, add it
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc(widget.postId)
            .set({
          'username': widget.username,
          'imageUrl': widget.imageUrl,
          'text': widget.text,
          'formattedDate': widget.formattedDate,
        });
        setState(() {
          isFavorite = true;
        });
      }
    }
  }

  Future<bool> _checkFavorite() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String userId = user.uid;

      // Check if this post is already in favorites
      DocumentSnapshot favoriteDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(widget.postId)
          .get();

      return favoriteDoc.exists;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _checkFavorite().then((isFavorite) {
      setState(() {
        this.isFavorite = isFavorite;
      });
    });
  }

  Future<void> _addComment(String text) async {
    User? user = _auth.currentUser;
    if (user != null) {
      String username = user.email ?? 'Anonymous'; // Assuming the user's email as username
      await _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'username': username,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _commentController.clear(); // Clear the comment field after adding comment
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Postingan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.imageUrl.isNotEmpty)
                Image.network(
                  widget.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(child: Text('Gagal memuat gambar'));
                  },
                )
              else
                Center(child: Text('Gambar tidak tersedia')),
              SizedBox(height: 8),
              Text(
                widget.username,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 8),
              Text(widget.formattedDate),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : null,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Komentar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: Icon(showComments ? Icons.expand_less : Icons.expand_more),
                    onPressed: () {
                      setState(() {
                        showComments = !showComments;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (showComments) // Show comments section only if showComments is true
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('posts')
                          .doc(widget.postId)
                          .collection('comments')
                          .orderBy('timestamp')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(child: Text('Belum ada komentar'));
                        }

                        List<Widget> commentWidgets = snapshot.data!.docs.map((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(data['username']),
                            subtitle: Text(data['text']),
                            trailing: Text(
                              '${(data['timestamp'] as Timestamp).toDate().day}/${(data['timestamp'] as Timestamp).toDate().month}/${(data['timestamp'] as Timestamp).toDate().year} ${(data['timestamp'] as Timestamp).toDate().hour}:${(data['timestamp'] as Timestamp).toDate().minute}',
                            ),
                          );
                        }).toList();

                        return ListView(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          children: commentWidgets,
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              labelText: 'Tambahkan komentar',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send),
                          onPressed: () {
                            if (_commentController.text.isNotEmpty) {
                              _addComment(_commentController.text);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
