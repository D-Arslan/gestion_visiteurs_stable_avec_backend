import 'package:flutter/material.dart';
import '../utils/translations.dart';

class SettingsPage extends StatelessWidget {
  final VoidCallback onLogout;
  final void Function(String) onLanguageChange;
  final void Function(String) onNavigate; // 🔁 Ajout

  const SettingsPage({
    required this.onLogout,
    required this.onLanguageChange,
    required this.onNavigate, // 🔁 Ajout
    Key? key,
  }) : super(key: key);

  @override
Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(getText(context, 'settings'))),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.home),
            title: Text(getText(context, 'nav_home')),
            onTap: () => onNavigate('home'),
          ),
          ListTile(
            leading: Icon(Icons.qr_code_scanner),
            title: Text(getText(context, 'nav_scan')),
            onTap: () => onNavigate('scan'),
          ),
          ListTile(
            leading: Icon(Icons.qr_code),
            title: Text(getText(context, 'qr_code')),
            onTap: () => onNavigate('qr'),
          ),
          ListTile(
            leading: Icon(Icons.language),
            title: Text(getText(context, 'language')),
            subtitle: Text(getText(context, 'choose_language')),
            onTap: () => _showLanguageDialog(context),
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text(getText(context, 'logout')),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(getText(context, 'choose_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Français'),
              onTap: () {
                onLanguageChange('fr');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('English'),
              onTap: () {
                onLanguageChange('en');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('العربية'),
              onTap: () {
                onLanguageChange('ar');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
