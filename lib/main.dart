import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barbershopplg/firebase_options.dart';
import 'package:barbershopplg/screens/home_screen.dart';
import 'package:barbershopplg/screens/sign_in_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? theme = prefs.getString('theme');
    setState(() {
      if (theme == 'light') {
        _themeMode = ThemeMode.light;
      } else if (theme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    });
  }

  void _changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
      _saveTheme(themeMode);
    });
  }

  Future<void> _saveTheme(ThemeMode themeMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String theme = themeMode == ThemeMode.light ? 'light' :
    themeMode == ThemeMode.dark ? 'dark' : 'system';
    await prefs.setString('theme', theme);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Barbershop_plg',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      darkTheme: ThemeData.dark(), // Tema gelap
      themeMode: _themeMode, // Gunakan mode tema yang sesuai
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return HomeScreen(onThemeChanged: _changeTheme);
          } else {
            return const SignInScreen();
          }
        },
      ),
    );
  }
}
