import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/welcome_page.dart';
import 'pages/login.dart';
import 'pages/signup.dart';
import 'pages/home_page.dart';
import 'pages/subjects_page.dart';
import 'pages/analysis_page.dart';
import 'utils/app_metrics.dart';
import 'utils/network_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable memory monitoring in debug mode
  // assert(() {
  //   debugPrintRebuildDirtyWidgets = true;
  //   return true;
  // }());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECMA App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BF6D),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // Optimize text rendering
        textTheme: Typography.material2021().black.apply(
          fontFamily: 'Poppins',
        ),
      ),
      // Enable route caching
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
