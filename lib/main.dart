import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'constants.dart';

import 'screens/diary_page.dart';
import 'screens/history_page.dart';
import 'screens/achievement_page.dart';
import 'screens/shop_page.dart';
import 'screens/login_page.dart';
import 'screens/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  runApp(const SoulLogApp());
}

class SoulLogApp extends StatefulWidget {
  const SoulLogApp({super.key});

  @override
  State<SoulLogApp> createState() => _SoulLogAppState();
}

class _SoulLogAppState extends State<SoulLogApp> with WidgetsBindingObserver {
  Color _bgColor = const Color(0xFFFDFBF7);

  DateTime? _startTime;
  Timer? _autoSaveTimer; // 🆕 自動存檔計時器

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTheme();
    _startTime = DateTime.now();

    // 🆕 每 30 秒自動結算一次時間，讓數據保持更新
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _accumulateTime();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel(); // 記得關閉計時器
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _accumulateTime(); // 切換到背景時也存一次
    } else if (state == AppLifecycleState.resumed) {
      _startTime = DateTime.now();
    }
  }

  // 結算時間邏輯 (修正版)
  Future<void> _accumulateTime() async {
    if (_startTime == null) return;

    final now = DateTime.now();
    final diff = now.difference(_startTime!).inSeconds;

    if (diff > 0) {
      final prefs = await SharedPreferences.getInstance();
      final currentTotal = prefs.getInt('total_usage_seconds') ?? 0;
      await prefs.setInt('total_usage_seconds', currentTotal + diff);

      // 關鍵：結算完後，重置開始時間為現在，避免重複計算
      _startTime = now;
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('theme_color');
    setState(() {
      if (colorValue != null) _bgColor = Color(colorValue);
    });
  }

  void updateTheme(Color color) {
    setState(() {
      _bgColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoulSeal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFA67C52),
        scaffoldBackgroundColor: _bgColor,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Color(0xFF5D4037)),
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
            fontSize: 20,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFFA67C52),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
      ),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFFA67C52))));
          }

          final session = snapshot.data?.session;

          if (session != null) {
            return MainScreen(onThemeChanged: updateTheme);
          }

          return const LoginPage();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Function(Color) onThemeChanged;
  const MainScreen({
    super.key,
    required this.onThemeChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<HistoryPageState> _historyKey = GlobalKey();
  final GlobalKey<AchievementPageState> _achievementKey = GlobalKey();
  final GlobalKey<ShopPageState> _shopKey = GlobalKey();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DiaryPage(
        onSaved: () {
          _historyKey.currentState?.refreshData();
          _achievementKey.currentState?.refreshStats();
          _shopKey.currentState?.refreshCoins();
        },
      ),
      HistoryPage(key: _historyKey),
      AchievementPage(key: _achievementKey),
      ShopPage(key: _shopKey, onThemeChanged: widget.onThemeChanged),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 2) _achievementKey.currentState?.refreshStats();
          if (index == 3) _shopKey.currentState?.refreshCoins();
          // 切換到 Profile 時，因為是 StatelessWidget，
          // 如果要即時刷新時間，建議把 ProfilePage 也改成 GlobalKey 控制，
          // 不過目前 ProfilePage 每次 build 都會讀取 Prefs，
          // 只要切換頁面就會觸發 build，所以數據會更新。
        },
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: '撰寫'),
          BottomNavigationBarItem(
              icon: Icon(Icons.collections_bookmark), label: '書架'),
          BottomNavigationBarItem(icon: Icon(Icons.military_tech), label: '成就'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: '商店'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '契約'),
        ],
      ),
    );
  }
}
