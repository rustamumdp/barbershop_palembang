import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart'; // Import package location
import 'package:flutter/foundation.dart' show kIsWeb;

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _postTextController = TextEditingController();
  String? _imageUrl;
  XFile? _image;
  final User? user = FirebaseAuth.instance.currentUser;
  LocationData? _locationData;

  Future<void> _getImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _image = image;
      });

      // Upload image and get URL if not on web
      if (!kIsWeb) {
        String? imageUrl = await _uploadImage(image);
        setState(() {
          _imageUrl = imageUrl;
        });
      } else {
        setState(() {
          _imageUrl = image.path;
        });
      }
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('post_images').child('${DateTime.now().toIso8601String()}.jpg');
      await ref.putFile(File(image.path));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _getLocation() async {
    Location location = Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    final locationData = await location.getLocation();
    setState(() {
      _locationData = locationData;
    });
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Postingan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _getImageFromCamera,
              child: Container(
                height: 200,
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: _image != null
                    ? kIsWeb
                    ? Image.network(
                  _imageUrl!,
                  fit: BoxFit.cover,
                )
                    : Image.file(
                  File(_image!.path),
                  fit: BoxFit.cover,
                )
                    : Icon(
                  Icons.camera_alt,
                  size: 100,
                  color: Colors.grey[400],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _postTextController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Tulis postingan Anda di sini...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_postTextController.text.isNotEmpty && _image != null && _locationData != null) {
                  _imageUrl ??= await _uploadImage(_image!);
                  if (_imageUrl != null) {
                    FirebaseFirestore.instance.collection('posts').add({
                      'text': _postTextController.text,
                      'image_url': _imageUrl,
                      'timestamp': Timestamp.now(),
                      'username': user?.email ?? 'Anonim', // Gunakan email atau pengenal lainnya
                      'userId': user?.uid, // Simpan ID pengguna untuk referensi
                      'location': GeoPoint(_locationData!.latitude!, _locationData!.longitude!), // Simpan lokasi
                    }).then((_) {
                      Navigator.pop(context);
                    }).catchError((error) {
                      print('Error saving post: $error');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal menyimpan postingan. Silakan coba lagi.'),
                        ),
                      );
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal mengunggah gambar. Silakan coba lagi.'),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Silakan tulis postingan, pilih gambar, dan pastikan lokasi tersedia.'),
                    ),
                  );
                }
              },
              child: const Text('Posting'),
            ),
          ],
        ),
      ),
    );
  }
}
