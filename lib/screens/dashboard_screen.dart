import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'connection_screen.dart';
import '../mqtt/mqtt_providers.dart';
import '../widgets/glass_panel.dart';

/// Try to get MQTT value for a display indicator name (e.g. "PM2.5/PM10" -> try "PM25", "PM10", "PM2.5/PM10").
double? mqttValueForIndicator(Map<String, double> latestValues, String indicator) {
  if (latestValues.containsKey(indicator)) return latestValues[indicator];
  final normalized = indicator.replaceAll('.', '').replaceAll('/', '');
  if (latestValues.containsKey(normalized)) return latestValues[normalized];
  for (final entry in latestValues.entries) {
    if (indicator.contains(entry.key) || entry.key.contains(normalized)) return entry.value;
  }
  return null;
}

/// Tips for pollution harm reduction, each tagged with the indicators they apply to.
const _harmReductionTips = [
  _HarmReductionTip(
    title: 'Air quality',
    indicators: ['PM2.5/PM10', 'NO2', 'O3', 'CO', 'SO2'],
    items: [
      'Check AQI before outdoor exercise; avoid heavy exertion when AQI > 100.',
      'Use HEPA filters at home and in the car when possible.',
      'Ventilate during low-pollution times (e.g. early morning).',
    ],
    icon: Icons.air,
  ),
  _HarmReductionTip(
    title: 'Indoor air',
    indicators: ['VOCs', 'CO'],
    items: [
      'Reduce VOCs: choose low-VOC paints and avoid strong chemicals when possible.',
      'Control humidity to limit mould; consider a dehumidifier in damp areas.',
      'Avoid smoking and vaping indoors.',
    ],
    icon: Icons.home,
  ),
  _HarmReductionTip(
    title: 'Personal exposure',
    indicators: ['PM2.5/PM10', 'NO2', 'O3', 'CO', 'SO2', 'VOCs','EMF','Radiation'],
    items: [
      'Wear a well-fitted N95/KN95 on high-pollution or dusty days.',
      'Wash hands after being outdoors in polluted areas.',
      'Consider supplements (see Supplements section) after discussing with a doctor.',
    ],
    icon: Icons.person,
  ),
];

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedIndicatorsProvider);
    final mqtt = ref.watch(mqttServiceProvider);
    final mqttValues = mqtt.latestValues;
    final tipsForSelected = _harmReductionTips
        .where((tip) => tip.indicators.any((ind) => selected.contains(ind)))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontFamily: 'Garamond', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Live readings',
                style: TextStyle(
                  fontFamily: 'Garamond',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              ...selected.map((indicator) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                indicator,
                                style: const TextStyle(
                                  fontFamily: 'Garamond',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                mqttValueForIndicator(mqttValues, indicator)
                                    ?.toStringAsFixed(1) ?? '—',
                                style: const TextStyle(
                                  fontFamily: 'Garamond',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2F3E46),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )),

              const SizedBox(height: 24),
              const Text(
                'Historical Trends',
                style: TextStyle(
                  fontFamily: 'Garamond',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: const Center(
                      child: Text(
                        "Chart Data Visualization",
                        style: TextStyle(fontFamily: 'Garamond', color: Colors.black45),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Pollution harm reduction',
                style: TextStyle(
                  fontFamily: 'Garamond',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Solutions for your selected indicators',
                style: TextStyle(
                  fontFamily: 'Garamond',
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              if (tipsForSelected.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassPanel(
                    child: Text(
                      'Select indicators on the Connection & indicators screen to see relevant tips.',
                      style: TextStyle(
                        fontFamily: 'Garamond',
                        color: Colors.black54,
                      ),
                    ),
                  ),
                )
              else
                ...tipsForSelected.map((tip) => Padding(
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
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _HarmReductionTip {
  const _HarmReductionTip({
    required this.title,
    required this.indicators,
    required this.items,
    required this.icon,
  });
  final String title;
  final List<String> indicators;
  final List<String> items;
  final IconData icon;
}
