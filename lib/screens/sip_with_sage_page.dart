import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SipWithSagePage extends StatefulWidget {
  const SipWithSagePage({super.key});

  @override
  State<SipWithSagePage> createState() => _SipWithSagePageState();
}

class _SipWithSagePageState extends State<SipWithSagePage> {
  bool _isLoading = true;

  bool _hasBeer = false;
  bool _hasWine = false;
  bool _hasSpirit = false;

  int _dailyLimit = 0;
  int _usedToday = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        final lastDate = data['last_stamp_date'] as String?;
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

        int used = data['stamps_used_today'] ?? 0;
        if (lastDate != today) {
          used = 0;
        }

        setState(() {
          _hasBeer = data['has_beer'] ?? false;
          _hasWine = data['has_wine'] ?? false;
          _hasSpirit = data['has_spirit'] ?? false;
          _usedToday = used;
          _calculateTotalLimit();
        });
      } else {
        await Supabase.instance.client.from('profiles').insert({'id': userId});
      }
    } catch (e) {
      debugPrint("Profile Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateTotalLimit() {
    int limit = 0;
    if (_hasBeer) limit += 1;
    if (_hasWine) limit += 3;
    if (_hasSpirit) limit += 5;
    _dailyLimit = limit;
  }

  // 模擬購買 (請客)
  Future<void> _purchaseSubscription(String type, String title) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 1));

    try {
      Map<String, dynamic> updates = {};
      String drinkName = "";

      if (type == 'beer') {
        updates = {'has_beer': true};
        drinkName = "啤酒";
      }
      if (type == 'wine') {
        updates = {'has_wine': true};
        drinkName = "紅酒";
      }
      if (type == 'spirit') {
        updates = {'has_spirit': true};
        drinkName = "烈酒";
      }

      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('id', userId);

      await _fetchProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🍻 乾杯，智者喝下你送的$drinkName了！"),
            backgroundColor: const Color(0xFFA67C52),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Purchase Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: const Text("與智者小酌"),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFA67C52)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 頂部概況 (已移除背景圖)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E2723),
                      borderRadius: BorderRadius.circular(16),
                      // 🗑️ 原本的 image 屬性已移除，現在是純色背景
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "今日手繪郵票次數",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "$_usedToday / $_dailyLimit",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_dailyLimit == 0)
                          const Text("請智者喝一杯，他會為你繪製靈感郵票",
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12))
                        else
                          const Text(
                            "智者是右撇子，他是智者不是法師，就算你昨天沒用完，\n他也沒辦法長出第二隻右手把昨天的補上",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.amber, fontSize: 12),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(" 酒單 Menu",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037))),
                  ),
                  const SizedBox(height: 15),

                  // 1. 啤酒
                  _buildDrinkCard(
                    type: 'beer',
                    title: "請智者喝啤酒",
                    price: "\$120 / 月",
                    desc: "智者感受到來自靈魂的誠意。",
                    benefit: "手繪郵票 +1 / 日",
                    color: Colors.amber.shade100,
                    icon: Icons.sports_bar,
                    iconColor: Colors.orange,
                    isActive: _hasBeer,
                  ),

                  // 2. 紅酒
                  _buildDrinkCard(
                    type: 'wine',
                    title: "請智者喝紅酒",
                    price: "\$350 / 月",
                    desc: "智者認同來自靈魂的格調。\n(不僅如此，智者還會照三餐對你寒暄)",
                    benefit: "手繪郵票 +3 / 日",
                    color: Colors.red.shade50,
                    icon: Icons.wine_bar,
                    iconColor: const Color(0xFF880E4F),
                    isActive: _hasWine,
                  ),

                  // 3. 烈酒
                  _buildDrinkCard(
                    type: 'spirit',
                    title: "請智者喝烈酒",
                    price: "\$530 / 月",
                    desc: "智者讚賞來自靈魂的狂野！\n(除了照三餐寒暄，因為怕你酗酒，\n智者會再半夜跟凌晨關心你的肝...)",
                    benefit: "手繪郵票 +5 / 日",
                    color: Colors.blueGrey.shade50,
                    icon: Icons.local_fire_department,
                    iconColor: Colors.deepOrange,
                    isActive: _hasSpirit,
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "※ 這是模擬測試，不會真的扣款，請盡情請客。",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDrinkCard({
    required String type,
    required String title,
    required String price,
    required String desc,
    required String benefit,
    required Color color,
    required IconData icon,
    required Color iconColor,
    required bool isActive,
  }) {
    // 🎯 決定按鈕文字 (醉後感言)
    String buttonText = "請客 ($price)";
    if (isActive) {
      if (type == 'beer')
        buttonText = "智者有點飽";
      else if (type == 'wine')
        buttonText = "智者有點微醺";
      else if (type == 'spirit') buttonText = "大智者豈能酗酒成癮";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? iconColor : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
          ),
          subtitle: Text(
            isActive ? "已訂閱 (生效中)" : price,
            style: TextStyle(
              color: isActive ? Colors.green : const Color(0xFFA67C52),
              fontWeight: FontWeight.bold,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            const Divider(),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    desc,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 16, color: Color(0xFFA67C52)),
                const SizedBox(width: 8),
                Text(
                  benefit,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFFA67C52)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isActive ? null : () => _purchaseSubscription(type, title),
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
