import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use'),
        backgroundColor: Colors.blue,
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              labelColor: Colors.blue,
              tabs: [
                Tab(text: 'Basics'),
                Tab(text: 'Scanning'),
                Tab(text: 'Tips'),
                Tab(text: 'Settings'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _BasicInstructionsTab(),
                  _ScanningGuideTab(),
                  _TipsTab(),
                  _SettingsGuideTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BasicInstructionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        _InstructionCard(
          title: 'Getting Started',
          content: '''
1. Create or select an answer key
2. Configure scanner settings if needed
3. Prepare your answer sheets
4. Ensure good lighting conditions
''',
        ),
        SizedBox(height: 16),
        _InstructionCard(
          title: 'Answer Sheet Requirements',
          content: '''
• Use standard paper sizes (A4 or Letter)
• Keep sheets clean and unwrinkled
• Ensure all bubbles are within margins
• Use dark pencil or pen for marking
''',
        ),
        SizedBox(height: 16),
        _InstructionCard(
          title: 'Proper Bubble Marking',
          content: '''
✓ Fill bubbles completely
✓ Make dark, solid marks
✓ Stay within the bubble boundaries
✗ Don't use check marks
✗ Avoid partial filling
✗ Don't make stray marks
''',
        ),
      ],
    );
  }
}

class _ScanningGuideTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        _InstructionCard(
          title: 'Camera Position',
          content: '''
• Hold camera parallel to sheet
• Keep 8-12 inches distance
• Ensure all corners are visible
• Avoid shadows on the sheet
''',
        ),
        SizedBox(height: 16),
        _InstructionCard(
          title: 'Lighting Tips',
          content: '''
• Use even, bright lighting
• Avoid direct glare
• Natural light works best
• Avoid casting shadows
''',
        ),
        SizedBox(height: 16),
        _InstructionCard(
          title: 'Scanning Process',
          content: '''
1. Wait for sheet detection (green outline)
2. Hold steady when scanning
3. Review results immediately
4. Save or retake if needed
''',
        ),
      ],
    );
  }
}

class _TipsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        _InstructionCard(
          title: 'Best Practices',
          content: '''
• Scan in batches of 20-30 sheets
• Review results periodically
• Export analysis after each session
• Keep original sheets until verified
''',
        ),
        SizedBox(height: 16),
        _InstructionCard(
          title: 'Troubleshooting',
          content: '''
If sheet not detected:
• Check lighting conditions
• Adjust distance
• Clean camera lens
• Check sheet condition

If bubbles not recognized:
• Check marking darkness
• Verify bubble size settings
• Ensure proper alignment
• Clean/flatten sheet
''',
        ),
        SizedBox(height: 16),
        _InstructionCard(
          title: 'Quality Assurance',
          content: '''
• Verify first few scans manually
• Check item analysis regularly
• Monitor error patterns
• Keep backup of scan results
''',
        ),
      ],
    );
  }
}

class _SettingsGuideTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        _InstructionCard(
          title: 'Scanner Settings',
          content: '''
Bubble Size:
• Larger: Better for hand-marked sheets
• Smaller: Better for printed sheets

Threshold:
• Higher: More strict detection
• Lower: More lenient detection

Edge Detection:
• Higher: Better in good lighting
• Lower: Better in poor lighting
''',
        ),
        SizedBox(height: 16),
        _InstructionCard(
          title: 'Advanced Options',
          content: '''
Auto-Save:
• Enable for batch processing
• Disable for manual review

Contrast Enhancement:
• Enable for poor lighting
• Disable for optimal conditions

Sheet Area Limits:
• Adjust for non-standard sizes
• Helps with angle detection
''',
        ),
      ],
    );
  }
}

class _InstructionCard extends StatelessWidget {
  final String title;
  final String content;

  const _InstructionCard({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
