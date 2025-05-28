import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = Locale('fr');

  void _setLocale(String code) {
    setState(() {
      _locale = Locale(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      supportedLocales: [Locale('fr'), Locale('en'), Locale('ar')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: LoginPage(onLanguageChange: _setLocale),
    );
  }
}

class LoginPage extends StatelessWidget {
  final void Function(String) onLanguageChange;

  LoginPage({required this.onLanguageChange});

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final ValueNotifier<bool> _obscurePassword = ValueNotifier(true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(getText(context, 'login_title'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(getText(context, 'login_instruction'), style: TextStyle(fontSize: 22)),
            SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: getText(context, 'username')),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _obscurePassword,
              builder: (context, obscure, _) => TextField(
                controller: _passwordController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: getText(context, 'password'),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => _obscurePassword.value = !obscure,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_usernameController.text == 'admin' && _passwordController.text == '1234') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MainNavigation(onLanguageChange: onLanguageChange),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(getText(context, 'invalid_credentials'))),
                  );
                }
              },
              child: Text(getText(context, 'login_button')),
            ),
          ],
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final void Function(String) onLanguageChange;
  final int startIndex;

  MainNavigation({required this.onLanguageChange, this.startIndex = 0});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;

  @override
  void initState() {
    _selectedIndex = widget.startIndex;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(),
      ScannerPage(),
      SettingsPage(
        onLanguageChange: widget.onLanguageChange,
      ),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: getText(context, 'nav_home')),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: getText(context, 'nav_scan')),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: getText(context, 'nav_settings')),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(getText(context, 'visitor_list'))),
      body: Center(child: Text(getText(context, 'empty_visitor_list'))),
    );
  }
}

class ScannerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(getText(context, 'scan_page'))),
      body: Center(child: Text(getText(context, 'scan_placeholder'))),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final void Function(String) onLanguageChange;

  SettingsPage({required this.onLanguageChange});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(getText(context, 'settings'))),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.home),
            title: Text(getText(context, 'nav_home')),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MainNavigation(onLanguageChange: onLanguageChange, startIndex: 0)),
            ),
          ),
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text(getText(context, 'nav_scan')),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MainNavigation(onLanguageChange: onLanguageChange, startIndex: 1)),
            ),
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text(getText(context, 'logout')),
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => LoginPage(onLanguageChange: onLanguageChange)),
              (_) => false,
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.language),
            title: Text(getText(context, 'language')),
            subtitle: Text(getText(context, 'choose_language')),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(getText(context, 'choose_language')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text("Français"),
                        onTap: () {
                          onLanguageChange("fr");
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: Text("English"),
                        onTap: () {
                          onLanguageChange("en");
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: Text("العربية"),
                        onTap: () {
                          onLanguageChange("ar");
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Traductions intégrées simple
String getText(BuildContext context, String key) {
  final translations = {
    'fr': {
      'login_title': 'Connexion',
      'login_instruction': "Agent de sécurité",
      'username': "Nom d'utilisateur",
      'password': "Mot de passe",
      'login_button': "Se connecter",
      'invalid_credentials': "Identifiants incorrects",
      'visitor_list': "Liste des visiteurs",
      'empty_visitor_list': "Aucun visiteur pour le moment.",
      'scan_page': "Scanner",
      'scan_placeholder': "Fonction de scan en cours de développement",
      'settings': "Paramètres",
      'logout': "Déconnexion",
      'language': "Langue",
      'choose_language': "Choisir la langue",
      'nav_home': "Accueil",
      'nav_scan': "Scan",
      'nav_settings': "Paramètres",
    },
    'en': {
      'login_title': 'Login',
      'login_instruction': "Security agent",
      'username': "Username",
      'password': "Password",
      'login_button': "Log in",
      'invalid_credentials': "Invalid credentials",
      'visitor_list': "Visitor list",
      'empty_visitor_list': "No visitors yet.",
      'scan_page': "Scanner",
      'scan_placeholder': "Scan function in development",
      'settings': "Settings",
      'logout': "Logout",
      'language': "Language",
      'choose_language': "Choose language",
      'nav_home': "Home",
      'nav_scan': "Scan",
      'nav_settings': "Settings",
    },
    'ar': {
      'login_title': 'تسجيل الدخول',
      'login_instruction': "حارس الأمن",
      'username': "اسم المستخدم",
      'password': "كلمة المرور",
      'login_button': "دخول",
      'invalid_credentials': "بيانات الدخول غير صحيحة",
      'visitor_list': "قائمة الزوار",
      'empty_visitor_list': "لا يوجد زوار حالياً.",
      'scan_page': "الماسح",
      'scan_placeholder': "ميزة المسح قيد التطوير",
      'settings': "الإعدادات",
      'logout': "تسجيل الخروج",
      'language': "اللغة",
      'choose_language': "اختر اللغة",
      'nav_home': "الرئيسية",
      'nav_scan': "مسح",
      'nav_settings': "إعدادات",
    },
  };
  final locale = Localizations.localeOf(context).languageCode;
  return translations[locale]?[key] ?? key;
}
