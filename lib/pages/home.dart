import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register.dart';
import 'login.dart';
import 'scanner_page.dart';
import 'bubble_sheet_generator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;

  void _checkAuthAndNavigate(BuildContext context, Widget page) {
    if (_auth.currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to access this feature'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _auth.currentUser != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ECMA'),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _auth.signOut();
                if (!mounted) return;
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Successfully logged out'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  MediaQuery.of(context).platformBrightness == Brightness.light
                      ? "assets/icons/ecmalogo.png"
                      : "assets/icons/ecmalogo.png",
                  height: 146,
                ),
                const SizedBox(height: 16.0),
                const Text(
                  "Welcome to Ecma",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  "Automated Test Scoring at your fingertips",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 164.0),
                if (!isLoggedIn) ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF00BF6D),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 48),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text("Sign In"),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 48),
                      shape: const StadiumBorder(),
                      backgroundColor: const Color(0xFFFE9901),
                    ),
                    child: const Text("Sign Up"),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () => _checkAuthAndNavigate(context, const ScannerPage()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      "Start Scanning",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () => _checkAuthAndNavigate(context, const BubbleSheetGenerator()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      "Create Answer Sheet",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
