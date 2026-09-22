import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masrooufi/core/di/injection.dart';
import 'package:masrooufi/core/security/security_service.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final SecurityService securityService = sl<SecurityService>();
  bool _isAppLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _isAppLockEnabled = securityService.isAppLockEnabled();
  }

  void _toggleAppLock(bool value) async {
    if (value) {
      final authenticated = await securityService.authenticateWithBiometrics();
      if (authenticated) {
        await securityService.setAppLockEnabled(true);
        setState(() {
          _isAppLockEnabled = true;
        });
      } else {
        if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric authentication failed or is unavailable. App Lock not enabled.')));
        }
      }
    } else {
      await securityService.setAppLockEnabled(false);
      setState(() {
        _isAppLockEnabled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable App Lock'),
            subtitle: const Text('Require biometrics (fingerprint/face) to open the app'),
            value: _isAppLockEnabled,
            onChanged: _toggleAppLock,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'App Lock protects your financial data. When enabled, you will be prompted to authenticate when returning to the application.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        ],
      ),
    );
  }
}
