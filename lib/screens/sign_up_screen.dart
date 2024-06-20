import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barbershopplg/screens/home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 32.0),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                final email = _emailController.text.trim();
                final password = _passwordController.text.trim();
                if (email.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields.')),
                  );
                  return;
                }
                try {
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: email,
                    password: password,
                  );
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => HomeScreen(onThemeChanged: (themeMode) {
                      // Implementasi logika perubahan tema di sini
                      // Contoh: Mengubah tema aplikasi berdasarkan themeMode
                      // if (themeMode == ThemeMode.light) {
                      //   // Implementasi tema terang
                      // } else {
                      //   // Implementasi tema gelap
                      // }
                    })),
                  );
                } on FirebaseAuthException catch (e) {
                  if (e.code == 'weak-password') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('The password provided is too weak.')),
                    );
                  } else if (e.code == 'email-already-in-use') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('The account already exists for that email.')),
                    );
                  } else if (e.code == 'invalid-email') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('The email address is not valid.')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('An error occurred: $e')),
                  );
                }
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
