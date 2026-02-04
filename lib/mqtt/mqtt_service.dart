import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// Decode MQTT payload bytes to UTF-8 string.
String _payloadBytesToString(dynamic message) {
  if (message == null) return '';
  if (message is String) return message;
  final bytes = message is List<int> ? message : message as List<int>?;
  if (bytes == null || bytes.isEmpty) return '';
  try {
    return utf8.decode(bytes);
  } catch (_) {
    return '';
  }
}

/// MQTT connection config (broker over WiFi).
class MqttConfig {
  const MqttConfig({
    required this.host,
    this.port = 1883,
    this.username,
    this.password,
    this.topicFilter = 'sensors/#',
  });

  final String host;
  final int port;
  final String? username;
  final String? password;
  /// Subscribe to this topic (e.g. "sensors/#" to get sensors/PM25, sensors/NO2, ...).
  final String topicFilter;

  String get displayHost => host.isEmpty ? 'Not set' : '$host:$port';
}

/// One sensor value from MQTT: topic (e.g. "sensors/PM25") and parsed value.
class MqttSensorReading {
  const MqttSensorReading({
    required this.topic,
    required this.sensorKey,
    this.value,
    this.rawPayload,
  });

  final String topic;
  /// Last part of topic or normalized name (e.g. "PM25" from "sensors/PM25").
  final String sensorKey;
  final double? value;
  final String? rawPayload;
}

/// Service that connects to an MQTT broker over WiFi, subscribes to a topic filter,
/// and exposes discovered sensors and their latest values from payloads.
class MqttService extends ChangeNotifier {
  MqttService() : _client = null;

  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _subscription;
  MqttConfig? _config;

  /// Current config (host, port, topic filter).
  MqttConfig? get config => _config;

  /// Whether the client is connected.
  bool get isConnected =>
      _client != null &&
      _client!.connectionStatus?.state == MqttConnectionState.connected;

  /// All topic names that have received at least one message (discovered sensors).
  final Set<String> discoveredTopics = {};

  /// Latest value per topic. Key = full topic string (e.g. "sensors/PM25").
  final Map<String, MqttSensorReading> latestByTopic = {};

  /// Normalized sensor key -> latest value (e.g. "PM25" -> 24.5).
  /// Good for dashboard: map indicator names to values.
  Map<String, double> get latestValues {
    final map = <String, double>{};
    for (final r in latestByTopic.values) {
      if (r.value != null) map[r.sensorKey] = r.value!;
    }
    return map;
  }

  /// Connect to broker and subscribe to [config.topicFilter].
  /// Discovered sensors and values are updated via [discoveredTopics] and [latestByTopic].
  Future<bool> connect(MqttConfig config) async {
    await disconnect();

    _config = config;
    final clientId = 'env_pollution_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient.withPort(config.host, clientId, config.port);
    _client!.logging(on: kDebugMode, logPayloads: kDebugMode);
    _client!.keepAlivePeriod = 60;
    _client!.connectTimeoutPeriod = 10;
    _client!.autoReconnect = false;

    try {
      final conn = await _client!.connect(config.username, config.password);
      if (conn?.state != MqttConnectionState.connected) {
        await disconnect();
        return false;
      }

      _client!.subscribe(config.topicFilter, MqttQos.atLeastOnce);
      _subscription = _client!.updates?.listen(_onMessages);
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('MQTT connect error: $e');
      await disconnect();
      notifyListeners();
      return false;
    }
  }

  void _onMessages(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final msg in messages) {
      final rec = msg.payload;
      if (rec is! MqttPublishMessage) continue;
      final topic = msg.topic;
      final payloadStr = _payloadBytesToString(rec.payload.message);
      _processMessage(topic, payloadStr);
    }
  }

  void _processMessage(String topic, String payloadStr) {
    discoveredTopics.add(topic);
    final sensorKey = _topicToSensorKey(topic);
    final value = _parsePayloadValue(payloadStr);
    latestByTopic[topic] = MqttSensorReading(
      topic: topic,
      sensorKey: sensorKey,
      value: value,
      rawPayload: payloadStr.isEmpty ? null : payloadStr,
    );
    notifyListeners();
  }

  /// Last part of topic, or topic with slashes replaced (e.g. "sensors/PM25" -> "PM25").
  static String _topicToSensorKey(String topic) {
    final parts = topic.split('/');
    if (parts.length > 1) return parts.last;
    return topic.replaceAll('/', '_');
  }

  /// Try to parse a numeric value from payload (JSON or plain number).
  static double? _parsePayloadValue(String payload) {
    if (payload.isEmpty) return null;
    final trimmed = payload.trim();
    final asNum = double.tryParse(trimmed);
    if (asNum != null) return asNum;
    try {
      final map = jsonDecode(trimmed) as Map<String, dynamic>;
      if (map['value'] != null) return (map['value'] as num).toDouble();
      if (map['v'] != null) return (map['v'] as num).toDouble();
      for (final key in ['value', 'v', 'reading', 'data']) {
        if (map[key] is num) return (map[key] as num).toDouble();
      }
      final nums = map.values.whereType<num>().toList();
      if (nums.isNotEmpty) return nums.first.toDouble();
    } catch (_) {}
    return null;
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    _client?.disconnect();
    _client = null;
    _config = null;
    discoveredTopics.clear();
    latestByTopic.clear();
    notifyListeners();
  }
}
