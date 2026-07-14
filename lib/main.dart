import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart'; 
import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final int? userId = prefs.getInt('user_id');

  runApp(MainApp(isLoggedIn: userId != null));
}

class MainApp extends StatelessWidget {
  final bool isLoggedIn;

  const MainApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Komiku',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: isLoggedIn ? const HomePage() : const LoginPage(),
    );
  }
}