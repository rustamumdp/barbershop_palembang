import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barbershopplg/screens/home_screen.dart';
import 'package:barbershopplg/screens/sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: Stack(  // <-- Ukuran bg
        children: [
          Positioned.fill(  // <-- ukuran bg
            child: Image.asset(
              'assets/background.jpg', // Ganti dengan path gambar Anda
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 32.0),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      filled: true, // Menambahkan latar belakang solid pada TextField
                      fillColor: Colors.white70, // Warna latar belakang TextField
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      filled: true, // Menambahkan latar belakang solid pada TextField
                      fillColor: Colors.white70, // Warna latar belakang TextField
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () async {
                      final email = _emailController.text.trim();
                      final password = _passwordController.text;
        
                      // Validasi email
                      if (email.isEmpty || !isValidEmail(email)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid email'),
                          ),
                        );
                        return;
                      }
        
                      // Validasi password
                      if (password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your password'),
                          ),
                        );
                        return;
                      }
        
                      try {
                        // Lakukan sign in dengan email dan password
                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                          email: email,
                          password: password,
                        );
        
                        // Jika berhasil sign in, navigasi ke halaman beranda
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                        );
                      } on FirebaseAuthException catch (error) {
                        print('Error code: ${error.code}');
                        if (error.code == 'user-not-found') {
                          // Jika email tidak terdaftar, tampilkan pesan kesalahan
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No user found with that email')),
                          );
                        } else if (error.code == 'wrong-password') {
                          // Jika password salah, tampilkan pesan kesalahan
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Wrong password. Please try again.')),
                          );
                        } else {
                          // Jika terjadi kesalahan lain, tampilkan pesan kesalahan umum
                          setState(() {
                            _errorMessage = error.message ?? 'An error occurred';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_errorMessage),
                            ),
                          );
                        }
                      } catch (error) {
                        // Tangani kesalahan lain yang tidak terkait dengan otentikasi
                        setState(() {
                          _errorMessage = error.toString();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_errorMessage),
                          ),
                        );
                      }
                    },
                    child: const Text('Sign In'),
                  ),
                  const SizedBox(height: 32.0),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5), // Ubah warna dan opasitas sesuai kebutuhan
                      padding: const EdgeInsets.all(12), // Tambahkan padding agar tombol terlihat lebih baik
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Ubah sesuai kebutuhan
                      ),
                    ),
                    child: const Text(
                    'Belum punya akun? Sign up',
                    style: TextStyle(
                      color: Colors.pink, // Ubah warna teks sesuai kebutuhan
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk memeriksa validitas email
  bool isValidEmail(String email) {
    String emailRegex =
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$";
    RegExp regex = RegExp(emailRegex);
    return regex.hasMatch(email);
  }
}