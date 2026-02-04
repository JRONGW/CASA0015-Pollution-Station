import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../notifications/local_notifications_service.dart';
import '../widgets/glass_panel.dart';
import '../widgets/glass_style_button.dart';

const _reminderTimesKey = 'supplement_reminder_times';

class SupplementsScreen extends StatefulWidget {
  const SupplementsScreen({super.key});

  @override
  State<SupplementsScreen> createState() => _SupplementsScreenState();
}

class _SupplementsScreenState extends State<SupplementsScreen> {
  List<TimeOfDay> _reminderTimes = [];
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadReminders();
  }

  static String format24(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static TimeOfDay _fromMap(Map<String, dynamic> map) {
    return TimeOfDay(
      hour: map['hour'] as int,
      minute: map['minute'] as int,
    );
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_reminderTimesKey);
    if (!mounted) return;
    if (json != null && json.isNotEmpty) {
      try {
        final list = jsonDecode(json) as List<dynamic>;
        final loaded = list
            .map((e) => _fromMap(e as Map<String, dynamic>))
            .toList();
        setState(() => _reminderTimes = loaded);
      } catch (_) {}
    }
  }

  Future<void> _saveAndScheduleReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _reminderTimes
        .map((t) => {'hour': t.hour, 'minute': t.minute})
        .toList();
    await prefs.setString(_reminderTimesKey, jsonEncode(list));

    final times = _reminderTimes
        .map((t) => (hour: t.hour, minute: t.minute))
        .toList();
    await scheduleSupplementReminders(times);
  }

  static Widget _timePickerTheme(BuildContext context, Widget? child) {
    final grey = Colors.grey;
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.light(
          primary: grey[700]!,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: grey[800]!,
          onSurfaceVariant: grey[700]!,
        ),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: grey[800],
          displayColor: grey[800],
        ),
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
  }

  Future<void> _addReminder() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => _timePickerTheme(context, child),
    );
    if (time == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add reminder'),
        content: Text(
          'Add a daily supplement reminder at ${format24(time)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[800],
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              foregroundColor: Colors.grey[900],
              backgroundColor: Colors.grey[300],
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await requestNotificationPermission();

    if (_reminderTimes.length >= supplementReminderMaxCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $supplementReminderMaxCount reminders.'),
        ),
      );
      return;
    }
    setState(() => _reminderTimes = [..._reminderTimes, time]..sort(
          (a, b) {
            final ah = a.hour * 60 + a.minute;
            final bh = b.hour * 60 + b.minute;
            return ah.compareTo(bh);
          },
        ));
    await _saveAndScheduleReminders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder at ${format24(time)} added.')),
      );
    }
  }

  Future<void> _editReminder(int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTimes[index],
      builder: (context, child) => _timePickerTheme(context, child),
    );
    if (time != null && mounted) {
      setState(() {
        _reminderTimes = List<TimeOfDay>.from(_reminderTimes)
          ..[index] = time
          ..sort((a, b) {
            final ah = a.hour * 60 + a.minute;
            final bh = b.hour * 60 + b.minute;
            return ah.compareTo(bh);
          });
      });
      await _saveAndScheduleReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder updated to ${format24(time)}.')),
        );
      }
    }
  }

  Future<void> _removeReminder(int index) async {
    setState(() => _reminderTimes = List<TimeOfDay>.from(_reminderTimes)..removeAt(index));
    await _saveAndScheduleReminders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder removed.')),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Supplements & reminders',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/'),
        ),
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, _) {
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                const Text(
                  'Supplement buying links',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Discuss with your doctor before taking. Links are examples only.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                ..._links.map((link) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassStyleButton(
                        onPressed: () => _openUrl(link.url),
                        label: link.label,
                        icon: Icons.open_in_new,
                      ),
                    )),
                const SizedBox(height: 24),
                const Text(
                  'Supplement reminders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                GlassStyleButton(
                  onPressed: _addReminder,
                  label: 'Add reminder',
                  icon: Icons.add,
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      await scheduleTestReminderInSeconds(5);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Test notification in 5 seconds. Check sound.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.notifications_active, size: 18),
                    label: const Text('Test notification (in 5 sec)'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_reminderTimes.isEmpty)
                  GlassPanel(
                    child: Center(
                      child: Text(
                        'No reminders. Tap "Add reminder" to set a daily reminder.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                    ),
                  )
                else
                  ...List.generate(_reminderTimes.length, (index) {
                    final time = _reminderTimes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassPanel(
                        child: Row(
                          children: [
                            const Icon(Icons.alarm, color: Colors.black54),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _editReminder(index),
                                child: Text(
                                  'Reminder at ${format24(time)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.black54),
                              onPressed: () => _editReminder(index),
                              tooltip: 'Edit time',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.black54),
                              onPressed: () => _removeReminder(index),
                              tooltip: 'Remove reminder',
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  static const _links = [
    _Link('Vitamin D (e.g. iHerb)', 'https://www.iherb.com'),
    _Link('Omega-3 (e.g. Amazon)', 'https://www.amazon.com'),
    _Link('Antioxidants / NAC (e.g. local pharmacy)', 'https://www.boots.com'),
  ];
}

class _Link {
  const _Link(this.label, this.url);
  final String label;
  final String url;
}
