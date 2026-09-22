import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Daily Reminder'),
            subtitle: const Text('Remind me to log my expenses'),
            value: false, // State placeholder
            onChanged: (val) {},
          ),
          SwitchListTile(
            title: const Text('Budget Warnings'),
            subtitle: const Text('Notify when nearing budget limits'),
            value: true,
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }
}
