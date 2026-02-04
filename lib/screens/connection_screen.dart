import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../mqtt/mqtt_providers.dart';
import '../mqtt/mqtt_service.dart';
import '../widgets/glass_panel.dart';
import '../widgets/glass_style_button.dart';

final selectedIndicatorsProvider =
    StateProvider<Set<String>>((ref) => {'PM2.5/PM10'});

const _availableIndicators = [
  'PM2.5/PM10',
  'NO2',
  'O3',
  'CO',
  'SO2',
  'VOCs',
  'EMF',
  'Radiation',
];

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  final _hostController = TextEditingController(text: '192.168.1.1');
  final _portController = TextEditingController(text: '1883');
  final _topicController = TextEditingController(text: 'sensors/#');
  bool _connecting = false;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _connectMqtt() async {
    final host = _hostController.text.trim();
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter broker host (e.g. IP address)')),
      );
      return;
    }
    final port = int.tryParse(_portController.text.trim()) ?? 1883;
    final topicFilter = _topicController.text.trim().isEmpty ? 'sensors/#' : _topicController.text.trim();
    setState(() => _connecting = true);
    final config = MqttConfig(
      host: host,
      port: port,
      topicFilter: topicFilter,
    );
    final service = ref.read(mqttServiceProvider);
    final ok = await service.connect(config);
    setState(() => _connecting = false);
    if (!mounted) return;
    if (ok) {
      ref.read(mqttConfigProvider.notifier).state = config;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to $host. Subscribed to "$topicFilter". Data will appear as messages arrive.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection failed. Check host, port, and network.')),
      );
    }
  }

  void _disconnectMqtt() {
    ref.read(mqttServiceProvider).disconnect();
    ref.read(mqttConfigProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedIndicatorsProvider);
    final mqtt = ref.watch(mqttServiceProvider);
    final isConnected = mqtt.isConnected;
    final discovered = mqtt.discoveredTopics.toList()..sort();
    final latestValues = mqtt.latestValues;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Connection & indicators',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MQTT over WiFi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _hostController,
                      decoration: const InputDecoration(
                        labelText: 'Broker host',
                        hintText: 'e.g. 192.168.1.100 or broker.local',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        hintText: '1883',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _topicController,
                      decoration: const InputDecoration(
                        labelText: 'Topic filter (subscribe)',
                        hintText: 'sensors/# or env/+/reading',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isConnected) ...[
                      GlassStyleButton(
                        onPressed: _disconnectMqtt,
                        label: 'Disconnect',
                        icon: Icons.link_off,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connected to ${mqtt.config?.displayHost ?? ""}. Listening for data.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade700,
                            ),
                      ),
                      if (discovered.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Available from MQTT (${discovered.length} topic(s)):',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: discovered.map((t) => Chip(
                            label: Text(
                              t,
                              style: const TextStyle(fontSize: 12),
                            ),
                            labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          )).toList(),
                        ),
                        if (latestValues.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Latest values: ${latestValues.entries.map((e) => '${e.key}=${e.value.toStringAsFixed(1)}').join(', ')}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.black54,
                                ),
                          ),
                        ],
                      ] else
                        Text(
                          'No messages yet. Publish to topics matching "${mqtt.config?.topicFilter ?? "sensors/#"}" to see sensors here.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.black54,
                              ),
                        ),
                    ] else ...[
                      GlassStyleButton(
                        onPressed: _connecting ? () {} : () => _connectMqtt(),
                        label: _connecting ? 'Connecting…' : 'Connect via MQTT',
                        icon: Icons.wifi,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter broker host (IP or hostname) and tap Connect. Sensors are discovered from topic names as messages arrive.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select pollution indicators',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ..._availableIndicators.map((indicator) {
                final isSelected = selected.contains(indicator);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassPanel(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: CheckboxListTile(
                      value: isSelected,
                      activeColor: Colors.black54,
                      onChanged: (value) {
                        final notifier = ref.read(selectedIndicatorsProvider.notifier);
                        final next = Set<String>.from(notifier.state);
                        if (value == true) {
                          next.add(indicator);
                        } else {
                          next.remove(indicator);
                        }
                        notifier.state = next;
                      },
                      title: Text(
                        indicator,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              GlassStyleButton(
                onPressed: () => context.go('/dashboard'),
                label: 'Continue to dashboard',
                icon: Icons.dashboard,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
