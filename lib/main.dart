import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/settings_page.dart';
import 'pages/scan_page.dart';
import 'pages/qr_code_page.dart';
import 'utils/translations.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();            // Initialise Hive
  await Hive.openBox('visiteurs');    // Ouvre la boîte de visiteurs
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('fr');
  bool _isLoggedIn = false;
  String _currentPage = 'home';

  void _changeLanguage(String code) {
    setState(() {
      _locale = Locale(code);
    });
  }

//LogOut
void _logout() {
  setState(() {
    _isLoggedIn = false;
    _currentPage = 'home';
  });
}



//Fin Logout


  void _onLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _navigateTo(String page) {
    setState(() {
      _currentPage = page;
    });
  }

Widget _getPage() {
  switch (_currentPage) {
    case 'scan':
      return const ScanPage();
    case 'settings':
  return SettingsPage(
    onLogout: _logout,
    onLanguageChange: _changeLanguage,
    onNavigate: _navigateTo,
  );

      case 'qr':
      return const QRCodePage();
    case 'home':
    default:
      return HomePage(key: UniqueKey()); // RECONSTRUIT forcé
  }
}


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/qr_scan': (context) => const QRCodePage(), // ✅ Route ajoutée pour le scan avec visiteur
      },
      locale: _locale,
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
          secondary: Colors.blueAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 4,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue.shade100),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue.shade100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
      ),
      home: _isLoggedIn
          ? Builder(
              builder: (context) => Scaffold(
                body: _getPage(),
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: _currentPage == 'home'
                      ? 0
                      : _currentPage == 'scan'
                          ? 1
                          : _currentPage == 'qr'
                              ? 2
                              : 3,
                  onTap: (index) {
                    if (index == 0) _navigateTo('home');
                    if (index == 1) _navigateTo('scan');
                    if (index == 2) _navigateTo('qr');
                    if (index == 3) _navigateTo('settings');
                  },
                  selectedItemColor: Colors.blue,
                  unselectedItemColor: Colors.grey[700],
                  items: [
                    BottomNavigationBarItem(
                        icon: Icon(Icons.home), label: getText(context, 'nav_home')),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.qr_code_scanner), label: getText(context, 'nav_scan')),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.qr_code), label: getText(context, 'qr_code')),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.settings), label: getText(context, 'settings')),
                  ],
                ),
              ),
            )
          : LoginPage(onLoginSuccess: _onLoginSuccess),
    );
  }
}
