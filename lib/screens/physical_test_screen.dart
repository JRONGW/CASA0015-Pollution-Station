import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/glass_panel.dart';
import '../widgets/glass_style_button.dart';

class PhysicalTestScreen extends StatelessWidget {
  const PhysicalTestScreen({super.key});

  Future<void> _openUrl(BuildContext context, String url, String label) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $label')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const tests = [
      _Test(
        type: 'Hair mineral / heavy metals',
        description: 'Hair analysis for long-term exposure to metals (e.g. lead, mercury).',
        exampleUrl: 'https://www.google.com/search?q=hair+mineral+test+uk',
        icon: Icons.face_retouching_natural,
      ),
      _Test(
        type: 'Urine (metals / metabolites)',
        description: 'Urine tests for recent exposure or metabolite markers.',
        exampleUrl: 'https://www.google.com/search?q=urine+heavy+metals+test',
        icon: Icons.science,
      ),
      _Test(
        type: 'Blood (metals, vitamins, markers)',
        description: 'Blood tests for metals, vitamin D, inflammation markers, etc.',
        exampleUrl: 'https://www.google.com/search?q=blood+test+heavy+metals',
        icon: Icons.bloodtype,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Physical tests',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const Text(
              'Personal physical tests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Links to search for providers. Always use a qualified lab or clinic.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ...tests.map((test) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(test.icon, color: Colors.black54),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                test.type,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          test.description,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        GlassStyleButton(
                          onPressed: () => _openUrl(
                            context,
                            test.exampleUrl,
                            test.type,
                          ),
                          label: 'Search for providers',
                          icon: Icons.open_in_new,
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _Test {
  const _Test({
    required this.type,
    required this.description,
    required this.exampleUrl,
    required this.icon,
  });
  final String type;
  final String description;
  final String exampleUrl;
  final IconData icon;
}
