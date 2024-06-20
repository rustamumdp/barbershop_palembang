import 'package:flutter/material.dart';

// Model untuk komentar
class Comment {
  final String username;
  final String text;
  final DateTime timestamp;
  List<Comment> replies;

  Comment({
    required this.username,
    required this.text,
    required this.timestamp,
    this.replies = const [],
  });
}

class DetailScreen extends StatefulWidget {
  final String username;
  final String imageUrl;
  final String text;
  final String formattedDate;

  const DetailScreen({
    super.key,
    required this.username,
    required this.imageUrl,
    required this.text,
    required this.formattedDate,
  });

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final List<Comment> _comments = [];
  final ScrollController _scrollController = ScrollController();

  // Menambahkan komentar baru
  void _addComment(String text) {
    final newComment = Comment(
      username: 'Current User', // Ubah dengan logika untuk mendapatkan username pengguna saat ini
      text: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _comments.add(newComment);
    });

    _commentController.clear();
  }

  // Menambahkan balasan pada komentar
  void _replyToComment(Comment parentComment, String replyText) {
    final reply = Comment(
      username: 'Current User', // Ubah dengan logika untuk mendapatkan username pengguna saat ini
      text: replyText,
      timestamp: DateTime.now(),
    );

    setState(() {
      parentComment.replies.add(reply);
    });
  }

  // Fungsi untuk membangun widget komentar dengan rekursi untuk menangani balasan
  Widget _buildComment(Comment comment, int depth) {
    return Card(
      margin: EdgeInsets.only(
        top: 8.0,
        left: 8.0 * depth,
        right: 8.0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comment.username,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14, // Ukuran teks lebih kecil
              ),
            ),
            const SizedBox(height: 4),
            Text(
              comment.text,
              style: const TextStyle(fontSize: 12), // Ukuran teks lebih kecil
            ),
            const SizedBox(height: 4),
            Text(
              '${comment.timestamp.hour}:${comment.timestamp.minute}, ${comment.timestamp.day}/${comment.timestamp.month}/${comment.timestamp.year}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _showReplyDialog(comment),
              child: const Text(
                'Balas',
                style: TextStyle(fontSize: 12), // Ukuran teks lebih kecil
              ),
            ),
            // Menampilkan balasan komentar
            if (comment.replies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Column(
                  children: comment.replies
                      .map((reply) => _buildComment(reply, depth + 1))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Dialog untuk membalas komentar
  void _showReplyDialog(Comment parentComment) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Balas Komentar'),
          content: TextField(
            controller: replyController,
            decoration: const InputDecoration(hintText: 'Tulis balasan Anda di sini...'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                if (replyController.text.isNotEmpty) {
                  setState(() {
                    _replyToComment(parentComment, replyController.text);
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Balas'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Postingan'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.imageUrl.isNotEmpty)
                Center(
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 300,
                  ),
                )
              else
                const Center(child: Text('Gambar tidak tersedia')),
              const SizedBox(height: 16),
              Text(
                widget.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20, // Ukuran teks lebih kecil
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.formattedDate,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14, // Ukuran teks lebih kecil
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 16, // Ukuran teks lebih kecil
                ),
              ),
              const Divider(height: 32),
              ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  return _buildComment(_comments[index], 0);
                },
              ),
              const Divider(height: 32),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Tambahkan komentar...',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        if (_commentController.text.isNotEmpty) {
                          _addComment(_commentController.text);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
