import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/glass_panel.dart';

class SuggestionsScreen extends StatelessWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const tips = [
      _Tip(
        title: 'Air quality',
        items: [
          'Check AQI before outdoor exercise; avoid heavy exertion when AQI > 100.',
          'Use HEPA filters at home and in the car when possible.',
          'Ventilate during low-pollution times (e.g. early morning).',
        ],
        icon: Icons.air,
      ),
      _Tip(
        title: 'Indoor air',
        items: [
          'Reduce VOCs: choose low-VOC paints and avoid strong chemicals when possible.',
          'Control humidity to limit mould; consider a dehumidifier in damp areas.',
          'Avoid smoking and vaping indoors.',
        ],
        icon: Icons.home,
      ),
      _Tip(
        title: 'Personal exposure',
        items: [
          'Wear a well-fitted N95/KN95 on high-pollution or dusty days.',
          'Wash hands after being outdoors in polluted areas.',
          'Consider supplements (see Supplements section) after discussing with a doctor.',
        ],
        icon: Icons.person,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Pollution harm reduction',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: tips.length,
          itemBuilder: (context, index) {
            final tip = tips[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassPanel(
                padding: EdgeInsets.zero,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: Icon(tip.icon, color: Colors.black54),
                    title: Text(
                      tip.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: tip.items
                              .map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ', style: TextStyle(color: Colors.black54)),
                                        Expanded(
                                          child: Text(
                                            e,
                                            style: const TextStyle(color: Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Tip {
  const _Tip({
    required this.title,
    required this.items,
    required this.icon,
  });
  final String title;
  final List<String> items;
  final IconData icon;
}
