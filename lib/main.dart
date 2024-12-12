import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/login.dart';
import 'utils/app_metrics.dart';
import 'utils/network_config.dart';

// Network configuration
const String? activeNetwork = null;  

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize network metrics
  await AppMetrics().initialize(activeNetwork);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!AppMetrics().isValid) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Network Connection Error'),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'ECMA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
