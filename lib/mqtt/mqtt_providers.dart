import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mqtt_service.dart';

/// Single MQTT service instance for the app. Notifies when connection or data changes.
final mqttServiceProvider = ChangeNotifierProvider<MqttService>((ref) {
  return MqttService();
});

/// MQTT broker config (host, port, topic filter). Editable from Connection screen.
final mqttConfigProvider = StateProvider<MqttConfig?>((ref) => null);
