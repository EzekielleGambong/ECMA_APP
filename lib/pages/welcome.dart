import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecma/pages/analysisList.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_defaults.dart';
import 'subject_list.dart';
import "student_list.dart";
import "login.dart";

class WelcomePage extends StatefulWidget {
  const WelcomePage({
    super.key, 
  });

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _firestore = FirebaseFirestore.instance;
  final _fireAuth = FirebaseAuth.instance;
  String username = '';

  Future<void> userDetails() async {
    final userid = _fireAuth.currentUser!.uid;
    try {
      DocumentSnapshot documentSnapshot = await _firestore.collection('users').doc(userid).get();
      if (documentSnapshot.exists) {
        Map<String, dynamic>? userData = documentSnapshot.data() as Map<String, dynamic>?;
        if (userData != null) {
          setState(() {
            username = userData['username'];
          });
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    userDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              Padding(
                padding: const EdgeInsets.all(AppDefaults.padding),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Professor. ',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      Text(
                        username,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Image.asset(
                  'assets/images/hero_section.png',
                  height: 350,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.all(AppDefaults.padding),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SubjectList()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF00BF6D),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(200, 48),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text("SUBJECTS"),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => StudentList()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFFE9901),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(200, 48),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text("STUDENTS"),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => analysisList()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color.fromARGB(255, 55, 32, 187),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(200, 48),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text("ANALYSIS"),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.0),
                      child: ElevatedButton(
                        onPressed: () {
                          _fireAuth.signOut();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color.fromARGB(255, 255, 0, 0),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(200, 48),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text("LOGOUT"),
                      ),
                    ),
                    const SizedBox(height: 48.0),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}