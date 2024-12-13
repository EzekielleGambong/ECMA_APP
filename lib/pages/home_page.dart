import 'package:flutter/material.dart';
import 'bubble_sheet_generator.dart';
import 'subjects_page.dart';
import 'analysis_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ECMA Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/welcome');
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        children: [
          _buildMenuCard(
            context,
            'Scan Answer Sheet',
            Icons.document_scanner,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BubbleSheetGenerator(),
              ),
            ),
          ),
          _buildMenuCard(
            context,
            'Answer Keys',
            Icons.key,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubjectsPage(),
              ),
            ),
          ),
          _buildMenuCard(
            context,
            'Analysis',
            Icons.analytics,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AnalysisPage(),
              ),
            ),
          ),
          _buildMenuCard(
            context,
            'Subjects',
            Icons.book,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubjectsPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
