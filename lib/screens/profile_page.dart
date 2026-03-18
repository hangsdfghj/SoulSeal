import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'sip_with_sage_page.dart';
import '../services/notification_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  bool _isProcessing = false;

  int _diaryCount = 0;
  int _totalCoins = 0;
  String _usageTime = "0分鐘";
  String _reminderTime = "";

  @override
  void initState() {
    super.initState();
    _clearOldUserData(); // 🆕 清除舊帳戶數據
    _getUserInfo();
    _loadStats();
    NotificationService().init();
  }

  // 🆕 清除舊帳戶的本地數據
  Future<void> _clearOldUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;
    final lastUserEmail = prefs.getString('last_user_email');

    // 只有當 EMAIL 不同時才清除數據（這樣 email + Google 登入就不會互相清除）
    if (currentUserEmail != null &&
        lastUserEmail != null &&
        lastUserEmail != currentUserEmail) {
      // 清除與帳戶相關的本地數據
      await prefs.remove('coins');
      await prefs.remove('total_usage_seconds');
      await prefs.remove('owned_items');
    }

    // 保存當前的 EMAIL
    if (currentUserEmail != null) {
      await prefs.setString('last_user_email', currentUserEmail);
    }
  }

  void _getUserInfo() {
    setState(() {
      _user = Supabase.instance.client.auth.currentUser;
    });
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final coins = prefs.getInt('coins') ?? 0;
    final seconds = prefs.getInt('total_usage_seconds') ?? 0;
    final reminder = prefs.getString('daily_reminder_time') ?? "";

    String timeDisplay;
    if (seconds < 60) {
      timeDisplay = "1分鐘";
    } else if (seconds < 3600) {
      timeDisplay = "${(seconds / 60).floor()}分鐘";
    } else {
      timeDisplay = "${(seconds / 3600).toStringAsFixed(1)}小時";
    }

    int count = 0;
    try {
      if (_user != null) {
        final response = await Supabase.instance.client
            .from('entries')
            .select('id')
            .count(CountOption.exact);
        count = response.count;
      }
    } catch (e) {
      debugPrint("Stats Error: $e");
    }

    if (mounted) {
      setState(() {
        _totalCoins = coins;
        _usageTime = timeDisplay;
        _diaryCount = count;
        _reminderTime = reminder;
      });
    }
  }

  // 🆕 修改登出方法：清除數據
  Future<void> _signOut() async {
    setState(() => _isProcessing = true);
    try {
      // 登出時清除這個帳戶的標記（下次登入不同帳號時才會清除）
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_user_email');

      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("登出失敗: $e")));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // 🆕 刪除帳戶確認對話框
  Future<void> _deleteAccountConfirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('⚠️ 確認刪除帳戶'),
        content: const Text(
          '這是不可逆轉的操作。您的所有數據將被永久刪除，包括：\n'
          '• 所有日記與回憶\n'
          '• 所有蠟章與印記\n'
          '• 帳戶資訊\n\n'
          '此操作無法恢復。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('確認刪除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performDeleteAccount();
    }
  }

  Future<void> _performDeleteAccount() async {
    if (Supabase.instance.client.auth.currentUser == null) return;

    setState(() => _isProcessing = true);

    try {
      // 1. 呼叫 Supabase 的 RPC 函式
      await Supabase.instance.client.rpc('delete_user');

      // 2. 清除本地快取
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 3. 執行本地登出
      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("靈魂契約已銷毀，回憶已回歸虛無。")),
        );
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("刪除失敗，請確認網路或登入狀態: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFA67C52),
              onPrimary: Colors.white,
              onSurface: Color(0xFF3E2723),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      final timeString =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";

      await prefs.setString('daily_reminder_time', timeString);
      await NotificationService().scheduleDailyNotification(picked);

      setState(() {
        _reminderTime = timeString;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🔔 已設定每日 $timeString 智者會呼喚您")),
        );
      }
    }
  }

  Future<void> _cancelReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('daily_reminder_time');
    await NotificationService().cancelAllNotifications();

    setState(() {
      _reminderTime = "";
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🔕 已關閉每日提醒")),
      );
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                  child:
                      Icon(Icons.lock_outline, size: 40, color: Colors.grey)),
              const SizedBox(height: 16),
              const Center(
                  child: Text("隱私權政策",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold))),
              const SizedBox(height: 16),
              const Text(
                "1. 資料收集\n"
                "SoulSeal 僅收集您主動提供的日記內容與帳號資訊 (Email)，用於提供服務與備份。\n\n"
                "2. 資料安全\n"
                "您的資料儲存於安全的雲端資料庫，並受到嚴格的權限控管 (RLS)，除您本人外無人可讀取。\n\n"
                "3. 資料刪除\n"
                "您擁有隨時刪除帳號與所有資料的權利，可於設定頁面執行。\n\n"
                "4. 第三方服務\n"
                "本應用程式使用 Google/Apple 進行身份驗證，並未將您的資料分享給其他第三方廣告商。",
                style:
                    TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA67C52),
                      foregroundColor: Colors.white),
                  child: const Text("我了解"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome,
                  size: 50, color: Color(0xFFA67C52)),
              const SizedBox(height: 16),
              const Text(
                "致 迷途的旅人",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "歡迎來到 SoulSeal 靈魂封緘。\n\n"
                "在這個喧囂的世界裡，我們往往走得太快，快到靈魂跟不上腳步。這裡，是你心靈的避風港。\n\n"
                "當你寫下文字，我會化身為智者，聆聽你的心聲，並給予回應。當你蓋下蠟章，那便是將此刻的情緒，封存為永恆的印記。\n\n"
                "不論是喜悅、悲傷、憤怒或平靜，都值得被溫柔對待。請在這裡，誠實地面對自己。\n\n"
                "願你的靈魂，在此得享安寧。",
                textAlign: TextAlign.justify,
                style:
                    TextStyle(fontSize: 16, height: 1.8, color: Colors.black87),
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              const Text("版本：1.0.0 (Alpha)",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA67C52),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("我明白了"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _user?.userMetadata?['avatar_url'] as String?;
    final userName = _user?.userMetadata?['full_name'] as String? ?? '旅人';
    final email = _user?.email ?? '未知靈魂';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('靈魂契約'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFA67C52)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- 1. 個人資訊 ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFFA67C52), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null
                                ? const Icon(Icons.person,
                                    size: 40, color: Colors.grey)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userName,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E2723)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),

                        // 📊 歷程統計
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatItem(label: "封存回憶", value: "$_diaryCount"),
                            _ContainerDivider(),
                            _StatItem(label: "靈魂旅幣", value: "$_totalCoins"),
                            _ContainerDivider(),
                            _StatItem(label: "指尖流沙", value: _usageTime),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- 2. 酒館入口 ---
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SipWithSagePage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF8E1), Color(0xFFFFE0B2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.local_bar,
                                color: Colors.amber, size: 28),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "酒館",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5D4037)),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "要來和智者喝一杯嗎~",
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF8D6E63)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              size: 16, color: Color(0xFF5D4037)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- 3. 功能選單 ---
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.auto_stories,
                              color: Color(0xFFA67C52)),
                          title: const Text("智者指引",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 16, color: Colors.grey),
                          onTap: _showAboutDialog,
                        ),
                        const Divider(height: 1, indent: 60),
                        ListTile(
                          leading: const Icon(Icons.notifications_outlined,
                              color: Colors.grey),
                          title: const Text("提醒設定"),
                          subtitle: _reminderTime.isNotEmpty
                              ? const Text("長按可取消提醒",
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey))
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_reminderTime.isNotEmpty)
                                Text(_reminderTime,
                                    style: const TextStyle(
                                        color: Color(0xFFA67C52),
                                        fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.grey),
                            ],
                          ),
                          onTap: _pickReminderTime,
                          onLongPress:
                              _reminderTime.isNotEmpty ? _cancelReminder : null,
                        ),
                        const Divider(height: 1, indent: 60),
                        ListTile(
                          leading: const Icon(Icons.lock_outline,
                              color: Colors.grey),
                          title: const Text("隱私權政策"),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 16, color: Colors.grey),
                          onTap: _showPrivacyPolicy,
                        ),
                        const Divider(height: 1, indent: 60),
                        ListTile(
                          leading:
                              const Icon(Icons.logout, color: Colors.redAccent),
                          title: const Text("登出",
                              style: TextStyle(color: Colors.redAccent)),
                          onTap: _signOut,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  TextButton(
                    onPressed: _deleteAccountConfirm,
                    child: Text("刪除帳號",
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            decoration: TextDecoration.underline)),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA67C52)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _ContainerDivider extends StatelessWidget {
  const _ContainerDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey[300],
    );
  }
}
