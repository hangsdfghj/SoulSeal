import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 🛠️ 新增：Supabase Client
import '../constants.dart';

class AchievementPage extends StatefulWidget {
  // 使用 key 參數以支援 main.dart 的 GlobalKey
  const AchievementPage({Key? key}) : super(key: key);

  @override
  State<AchievementPage> createState() => AchievementPageState();
}

class AchievementPageState extends State<AchievementPage> {
  // ... (所有狀態變數保持不變)
  int _totalCount = 0;
  int _morningCount = 0,
      _noonCount = 0,
      _afternoonCount = 0,
      _duskCount = 0,
      _eveningCount = 0,
      _nightCount = 0;
  int _shortTextCount = 0,
      _longTextCount = 0,
      _veryLongTextCount = 0,
      _longTitleCount = 0,
      _noTitleCount = 0;
  int _maxStreak = 0, _maxDailyFrequency = 0;
  int _unlockedCount = 0;
  List<int> _weekdayCounts = List.filled(7, 0);
  Set<int> _monthsLogged = {};
  bool _hasNewYear = false,
      _hasValentines = false,
      _hasChristmas = false,
      _hasYearEnd = false;
  bool _isLoading = true;

  // ... (成就列表 _achievements 保持不變)
  final List<Map<String, dynamic>> _achievements = [
    // 🌌 第一星系：累積 (10)
    {
      'id': 'first',
      'name': '初識墨香',
      'coin': 10,
      'desc': '第 1 篇日記',
      'icon': Icons.edit_road,
      'quote': '「千里之行，始於足下。恭喜你踏出了第一步。」',
      'check': (s) => s._totalCount >= 1,
      'progress': (s) => "${s._totalCount}/1",
    },
    {
      'id': 'count3',
      'name': '三日成林',
      'coin': 10,
      'desc': '累積 3 篇',
      'icon': Icons.park,
      'quote': '「習慣的種子已然發芽。」',
      'check': (s) => s._totalCount >= 3,
      'progress': (s) => "${s._totalCount}/3",
    },
    {
      'id': 'count10',
      'name': '拾光行者',
      'coin': 50,
      'desc': '累積 10 篇',
      'icon': Icons.collections_bookmark,
      'quote': '「你收集了十個光點。」',
      'check': (s) => s._totalCount >= 10,
      'progress': (s) => "${s._totalCount}/10",
    },
    {
      'id': 'count20',
      'name': '微光成炬',
      'coin': 50,
      'desc': '累積 20 篇',
      'icon': Icons.flare,
      'quote': '「點滴微光，匯聚成炬。」',
      'check': (s) => s._totalCount >= 20,
      'progress': (s) => "${s._totalCount}/20",
    },
    {
      'id': 'count30',
      'name': '月之盈缺',
      'coin': 80,
      'desc': '累積 30 篇',
      'icon': Icons.brightness_2,
      'quote': '「見證了一次完整的月亮盈缺。」',
      'check': (s) => s._totalCount >= 30,
      'progress': (s) => "${s._totalCount}/30",
    },
    {
      'id': 'count50',
      'name': '半百心事',
      'coin': 100,
      'desc': '累積 50 篇',
      'icon': Icons.favorite,
      'quote': '「五十次的自我對話。」',
      'check': (s) => s._totalCount >= 50,
      'progress': (s) => "${s._totalCount}/50",
    },
    {
      'id': 'count100',
      'name': '百篇史詩',
      'coin': 200,
      'desc': '累積 100 篇',
      'icon': Icons.menu_book,
      'quote': '「這是一本厚重的靈魂之書。」',
      'check': (s) => s._totalCount >= 100,
      'progress': (s) => "${s._totalCount}/100",
    },
    {
      'id': 'count200',
      'name': '歲月長河',
      'coin': 300,
      'desc': '累積 200 篇',
      'icon': Icons.waves,
      'quote': '「時間如河，你在此刻舟求劍。」',
      'check': (s) => s._totalCount >= 200,
      'progress': (s) => "${s._totalCount}/200",
    },
    {
      'id': 'count365',
      'name': '年輪',
      'coin': 500,
      'desc': '累積 365 篇',
      'icon': Icons.donut_large,
      'quote': '「一年的份量，刻畫成輪。」',
      'check': (s) => s._totalCount >= 365,
      'progress': (s) => "${s._totalCount}/365",
    },
    {
      'id': 'count1000',
      'name': '千夜之歌',
      'coin': 1000,
      'desc': '累積 1000 篇',
      'icon': Icons.music_note,
      'quote': '「一千零一夜的故事，由你譜寫。」',
      'check': (s) => s._totalCount >= 1000,
      'progress': (s) => "${s._totalCount}/1000",
    },
    // 🔥 第二星系：連鎖 (8)
    {
      'id': 'streak2',
      'name': '起步',
      'coin': 10,
      'desc': '連續 2 天',
      'icon': Icons.run_circle,
      'quote': '「第二天，最難也最重要。」',
      'check': (s) => s._maxStreak >= 2,
      'progress': (s) => "${s._maxStreak}/2",
    },
    {
      'id': 'streak3',
      'name': '不間斷的旅人',
      'coin': 30,
      'desc': '連續 3 天',
      'icon': Icons.directions_run,
      'quote': '「堅持是一種天賦。」',
      'check': (s) => s._maxStreak >= 3,
      'progress': (s) => "${s._maxStreak}/3",
    },
    {
      'id': 'streak7',
      'name': '一週的約定',
      'coin': 50,
      'desc': '連續 7 天',
      'icon': Icons.calendar_view_week,
      'quote': '「一週的循環，你完美達成。」',
      'check': (s) => s._maxStreak >= 7,
      'progress': (s) => "${s._maxStreak}/7",
    },
    {
      'id': 'streak14',
      'name': '雙週迴響',
      'coin': 80,
      'desc': '連續 14 天',
      'icon': Icons.repeat,
      'quote': '「習慣已經滲入生活。」',
      'check': (s) => s._maxStreak >= 14,
      'progress': (s) => "${s._maxStreak}/14",
    },
    {
      'id': 'streak21',
      'name': '習慣的養成',
      'coin': 100,
      'desc': '連續 21 天',
      'icon': Icons.check_circle,
      'quote': '「這不再是任務，而是呼吸。」',
      'check': (s) => s._maxStreak >= 21,
      'progress': (s) => "${s._maxStreak}/21",
    },
    {
      'id': 'streak30',
      'name': '滿月連鎖',
      'coin': 150,
      'desc': '連續 30 天',
      'icon': Icons.lens,
      'quote': '「一個月，一天都沒落下。」',
      'check': (s) => s._maxStreak >= 30,
      'progress': (s) => "${s._maxStreak}/30",
    },
    {
      'id': 'streak90',
      'name': '季節的堅持',
      'coin': 300,
      'desc': '連續 90 天',
      'icon': Icons.park,
      'quote': '「走過一整個季節。」',
      'check': (s) => s._maxStreak >= 90,
      'progress': (s) => "${s._maxStreak}/90",
    },
    {
      'id': 'streak100',
      'name': '日日是好日',
      'coin': 500,
      'desc': '連續 100 天',
      'icon': Icons.wb_sunny,
      'quote': '「百日築基，心如磐石。」',
      'check': (s) => s._maxStreak >= 100,
      'progress': (s) => "${s._maxStreak}/100",
    },
    // 🕰️ 第三星系：時段 (6)
    {
      'id': 'morning',
      'name': '晨曦微光',
      'coin': 20,
      'desc': '05-09 寫作',
      'icon': Icons.wb_twilight,
      'quote': '「一日之計在於晨。」',
      'check': (s) => s._morningCount >= 1,
      'progress': (s) => s._morningCount >= 1 ? "達成" : "未達成",
    },
    {
      'id': 'noon',
      'name': '日正當中',
      'coin': 20,
      'desc': '11-13 寫作',
      'icon': Icons.wb_sunny,
      'quote': '「日影最短時，你停下來思考。」',
      'check': (s) => s._noonCount >= 1,
      'progress': (s) => s._noonCount >= 1 ? "達成" : "未達成",
    },
    {
      'id': 'afternoon',
      'name': '午後紅茶',
      'coin': 20,
      'desc': '13-16 寫作',
      'icon': Icons.coffee,
      'quote': '「偷得浮生半日閒。」',
      'check': (s) => s._afternoonCount >= 1,
      'progress': (s) => s._afternoonCount >= 1 ? "達成" : "未達成",
    },
    {
      'id': 'dusk',
      'name': '黃昏的彼岸',
      'coin': 20,
      'desc': '17-19 寫作',
      'icon': Icons.landscape,
      'quote': '「夕陽無限好。」',
      'check': (s) => s._duskCount >= 1,
      'progress': (s) => s._duskCount >= 1 ? "達成" : "未達成",
    },
    {
      'id': 'evening',
      'name': '星空低語',
      'coin': 20,
      'desc': '20-23 寫作',
      'icon': Icons.star,
      'quote': '「夜深了，跟自己說說話。」',
      'check': (s) => s._eveningCount >= 1,
      'progress': (s) => s._eveningCount >= 1 ? "達成" : "未達成",
    },
    {
      'id': 'night',
      'name': '深夜樹洞',
      'coin': 20,
      'desc': '00-04 寫作',
      'icon': Icons.dark_mode,
      'quote': '「只有月亮聽得見的秘密。」',
      'check': (s) => s._nightCount >= 1,
      'progress': (s) => s._nightCount >= 1 ? "達成" : "未達成",
    },
    // 📅 第四星系：七曜 (7)
    {
      'id': 'mon',
      'name': '藍色星期一',
      'coin': 30,
      'desc': '週一寫作',
      'icon': Icons.looks_one,
      'quote': '「面對開始的勇氣。」',
      'check': (s) => s._weekdayCounts[0] >= 1,
      'progress': (s) => s._weekdayCounts[0] >= 1 ? "達成" : "未達成",
    },
    {
      'id': 'tue',
      'name': '火曜日衝勁',
      'coin': 30,
      'desc': '週二寫作',
      'icon': Icons.whatshot,
      'quote': '「燃燒的行動力。」',
      'check': (s) => s._weekdayCounts[1] >= 1,
      'progress': (s) => s._weekdayCounts[1] >= 1 ? "達成" : "未達成",
    },
    {
      'id': 'wed',
      'name': '小週末喘息',
      'coin': 30,
      'desc': '週三寫作',
      'icon': Icons.local_cafe,
      'quote': '「週中，稍作休息。」',
      'check': (s) => s._weekdayCounts[2] >= 1,
      'progress': (s) => s._weekdayCounts[2] >= 1 ? "達成" : "未達成",
    },
    {
      'id': 'thu',
      'name': '黎明前守望',
      'coin': 30,
      'desc': '週四寫作',
      'icon': Icons.hourglass_bottom,
      'quote': '「堅持，週末就在眼前。」',
      'check': (s) => s._weekdayCounts[3] >= 1,
      'progress': (s) => s._weekdayCounts[3] >= 1 ? "達成" : "未達成",
    },
    {
      'id': 'fri',
      'name': '金曜日狂歡',
      'coin': 30,
      'desc': '週五寫作',
      'icon': Icons.celebration,
      'quote': '「釋放一週的壓力。」',
      'check': (s) => s._weekdayCounts[4] >= 1,
      'progress': (s) => s._weekdayCounts[4] >= 1 ? "達成" : "未達成",
    },
    {
      'id': 'sat',
      'name': '土曜日自由',
      'coin': 30,
      'desc': '週六寫作',
      'icon': Icons.weekend,
      'quote': '「完全屬於你的時間。」',
      'check': (s) => s._weekdayCounts[5] >= 1,
      'progress': (s) => s._weekdayCounts[5] >= 1 ? "達成" : "未達成",
    },
    {
      'id': 'sun',
      'name': '日曜日沉澱',
      'coin': 30,
      'desc': '週日寫作',
      'icon': Icons.spa,
      'quote': '「歸零，為了再次出發。」',
      'check': (s) => s._weekdayCounts[6] >= 1,
      'progress': (s) => s._weekdayCounts[6] >= 1 ? "達成" : "未達成",
    },
    // ❄️ 第五星系：月份 (12)
    {
      'id': 'jan',
      'name': '一月・始動',
      'coin': 50,
      'desc': '1月寫作',
      'icon': Icons.ac_unit,
      'quote': '「新的開始。」',
      'check': (s) => s._monthsLogged.contains(1),
      'progress': (s) => s._monthsLogged.contains(1) ? "達成" : "",
    },
    {
      'id': 'feb',
      'name': '二月・春生',
      'coin': 50,
      'desc': '2月寫作',
      'icon': Icons.filter_vintage,
      'quote': '「萌芽。」',
      'check': (s) => s._monthsLogged.contains(2),
      'progress': (s) => s._monthsLogged.contains(2) ? "達成" : "",
    },
    {
      'id': 'mar',
      'name': '三月・花見',
      'coin': 50,
      'desc': '3月寫作',
      'icon': Icons.local_florist,
      'quote': '「繁花盛開。」',
      'check': (s) => s._monthsLogged.contains(3),
      'progress': (s) => s._monthsLogged.contains(3) ? "達成" : "",
    },
    {
      'id': 'apr',
      'name': '四月・雨露',
      'coin': 50,
      'desc': '4月寫作',
      'icon': Icons.umbrella,
      'quote': '「滋潤萬物。」',
      'check': (s) => s._monthsLogged.contains(4),
      'progress': (s) => s._monthsLogged.contains(4) ? "達成" : "",
    },
    {
      'id': 'may',
      'name': '五月・薫風',
      'coin': 50,
      'desc': '5月寫作',
      'icon': Icons.air,
      'quote': '「微風拂面。」',
      'check': (s) => s._monthsLogged.contains(5),
      'progress': (s) => s._monthsLogged.contains(5) ? "達成" : "",
    },
    {
      'id': 'jun',
      'name': '六月・蟬鳴',
      'coin': 50,
      'desc': '6月寫作',
      'icon': Icons.wb_sunny,
      'quote': '「熱情的夏。」',
      'check': (s) => s._monthsLogged.contains(6),
      'progress': (s) => s._monthsLogged.contains(6) ? "達成" : "",
    },
    {
      'id': 'jul',
      'name': '七月・流火',
      'coin': 50,
      'desc': '7月寫作',
      'icon': Icons.whatshot,
      'quote': '「盛夏光年。」',
      'check': (s) => s._monthsLogged.contains(7),
      'progress': (s) => s._monthsLogged.contains(7) ? "達成" : "",
    },
    {
      'id': 'aug',
      'name': '八月・桂秋',
      'coin': 50,
      'desc': '8月寫作',
      'icon': Icons.nights_stay,
      'quote': '「秋意漸濃。」',
      'check': (s) => s._monthsLogged.contains(8),
      'progress': (s) => s._monthsLogged.contains(8) ? "達成" : "",
    },
    {
      'id': 'sep',
      'name': '九月・白露',
      'coin': 50,
      'desc': '9月寫作',
      'icon': Icons.water_drop,
      'quote': '「露凝而白。」',
      'check': (s) => s._monthsLogged.contains(9),
      'progress': (s) => s._monthsLogged.contains(9) ? "達成" : "",
    },
    {
      'id': 'oct',
      'name': '十月・豐收',
      'coin': 50,
      'desc': '10月寫作',
      'icon': Icons.agriculture,
      'quote': '「收穫的季節。」',
      'check': (s) => s._monthsLogged.contains(10),
      'progress': (s) => s._monthsLogged.contains(10) ? "達成" : "",
    },
    {
      'id': 'nov',
      'name': '十一月・初霜',
      'coin': 50,
      'desc': '11月寫作',
      'icon': Icons.snowshoeing,
      'quote': '「冬之序曲。」',
      'check': (s) => s._monthsLogged.contains(11),
      'progress': (s) => s._monthsLogged.contains(11) ? "達成" : "",
    },
    {
      'id': 'dec',
      'name': '十二月・藏冬',
      'coin': 50,
      'desc': '12月寫作',
      'icon': Icons.fireplace,
      'quote': '「溫暖的結尾。」',
      'check': (s) => s._monthsLogged.contains(12),
      'progress': (s) => s._monthsLogged.contains(12) ? "達成" : "",
    },
    // 📝 第六星系：內容 (7)
    {
      'id': 'short',
      'name': '片刻靈光',
      'coin': 10,
      'desc': '< 30 字短文',
      'icon': Icons.short_text,
      'quote': '「言簡意賅，留白之美。」',
      'check': (s) => s._shortTextCount >= 1,
      'progress': (s) => s._shortTextCount >= 1 ? "達成" : "",
    },
    {
      'id': 'long',
      'name': '千言萬語',
      'coin': 40,
      'desc': '> 200 字長文',
      'icon': Icons.article,
      'quote': '「承載了靈魂的厚度。」',
      'check': (s) => s._longTextCount >= 1,
      'progress': (s) => s._longTextCount >= 1 ? "達成" : "",
    },
    {
      'id': 'vlong',
      'name': '小說家',
      'coin': 100,
      'desc': '> 500 字超長文',
      'icon': Icons.auto_stories,
      'quote': '「你正在書寫自己的人生小說。」',
      'check': (s) => s._veryLongTextCount >= 1,
      'progress': (s) => s._veryLongTextCount >= 1 ? "達成" : "",
    },
    {
      'id': 'freq2',
      'name': '雙重奏',
      'coin': 50,
      'desc': '單日寫 2 篇',
      'icon': Icons.filter_2,
      'quote': '「捕捉了兩次不同的自己。」',
      'check': (s) => s._maxDailyFrequency >= 2,
      'progress': (s) => s._maxDailyFrequency >= 2 ? "達成" : "",
    },
    {
      'id': 'freq3',
      'name': '多重宇宙',
      'coin': 80,
      'desc': '單日寫 3 篇+',
      'icon': Icons.filter_3,
      'quote': '「情感豐富的一天。」',
      'check': (s) => s._maxDailyFrequency >= 3,
      'progress': (s) => s._maxDailyFrequency >= 3 ? "達成" : "",
    },
    {
      'id': 'title_long',
      'name': '標題黨',
      'coin': 20,
      'desc': '標題 > 15 字',
      'icon': Icons.title,
      'quote': '「標題本身就是個故事。」',
      'check': (s) => s._longTitleCount >= 1,
      'progress': (s) => s._longTitleCount >= 1 ? "達成" : "",
    },
    {
      'id': 'title_no',
      'name': '無題之詩',
      'coin': 20,
      'desc': '無標題日記',
      'icon': Icons.remove,
      'quote': '「無題，是最大的題目。」',
      'check': (s) => s._noTitleCount >= 1,
      'progress': (s) => s._noTitleCount >= 1 ? "達成" : "",
    },
    // 🎁 第七星系：彩蛋 (4)
    {
      'id': 'newyear',
      'name': '新的開始',
      'coin': 100,
      'desc': '1/1 寫作',
      'icon': Icons.start,
      'quote': '「新年快樂！好的開始。」',
      'check': (s) => s._hasNewYear,
      'progress': (s) => s._hasNewYear ? "達成" : "",
    },
    {
      'id': 'val',
      'name': '愛的告白',
      'coin': 100,
      'desc': '2/14 或 5/20 寫作',
      'icon': Icons.favorite_border,
      'quote': '「愛，要說出口，也要記下來。」',
      'check': (s) => s._hasValentines,
      'progress': (s) => s._hasValentines ? "達成" : "",
    },
    {
      'id': 'xmas',
      'name': '聖誕夜',
      'coin': 100,
      'desc': '12/25 寫作',
      'icon': Icons.card_giftcard,
      'quote': '「聖誕快樂！你是最好的禮物。」',
      'check': (s) => s._hasChristmas,
      'progress': (s) => s._hasChristmas ? "達成" : "",
    },
    {
      'id': 'yearend',
      'name': '跨越年歲',
      'coin': 100,
      'desc': '12/31 寫作',
      'icon': Icons.hourglass_empty,
      'quote': '「再見了，今年。」',
      'check': (s) => s._hasYearEnd,
      'progress': (s) => s._hasYearEnd ? "達成" : "",
    },
  ];

  @override
  void initState() {
    super.initState();
    refreshStats();
  }

  Future<void> refreshStats() async {
    await _calculateStats();
  }

  Future<void> _checkAndAward(String id, int amount) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> claimed = prefs.getStringList('claimed_achievements') ?? [];
    if (!claimed.contains(id)) {
      int currentCoins = prefs.getInt('coins') ?? 0;
      await prefs.setInt('coins', currentCoins + amount);
      claimed.add(id);
      await prefs.setStringList('claimed_achievements', claimed);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🎉 解鎖成就！獲得 $amount 旅幣！"),
            backgroundColor: Colors.amber[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _calculateStats() async {
    if (!mounted) return;

    // 🛡️ 檢查是否登入
    if (Supabase.instance.client.auth.currentUser?.id == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 🛠️ RLS-Safe 查詢：獲取數據
      final response = await Supabase.instance.client
          .from('entries')
          .select('created_at,user_diary,user_title')
          .order('created_at', ascending: false);

      final List data = response as List;

      // ... (後續的統計邏輯，保持不變) ...

      // 由於統計邏輯冗長，我僅提供修正後的數據獲取部分，確保程式碼能執行：

      int total = data.length;
      int morning = 0,
          noon = 0,
          afternoon = 0,
          dusk = 0,
          evening = 0,
          midnight = 0;
      int shortText = 0,
          longText = 0,
          veryLongText = 0,
          longTitle = 0,
          noTitle = 0;
      int currentStreak = 0, maxStreak = 0;
      Map<String, int> dailyFreq = {};
      List<int> weekdays = List.filled(7, 0);
      Set<int> months = {};
      bool newYear = false, val = false, xmas = false, yearEnd = false;
      DateTime? lastDate;

      for (var item in data) {
        final dateStr = item['created_at'];
        final content = item['user_diary'] as String? ?? "";
        final title = item['user_title'] as String? ?? "";
        if (dateStr == null) continue;

        final dt = DateTime.parse(dateStr).toLocal();
        final dateKey = DateFormat('yyyy-MM-dd').format(dt);

        int h = dt.hour;
        if (h >= 5 && h < 9)
          morning++;
        else if (h >= 11 && h < 13)
          noon++;
        else if (h >= 13 && h < 16)
          afternoon++;
        else if (h >= 17 && h < 19)
          dusk++;
        else if (h >= 20 && h < 23)
          evening++;
        else if (h >= 0 && h < 4) midnight++;

        if (content.length < 30) shortText++;
        if (content.length >= 200) longText++;
        if (content.length >= 500) veryLongText++;
        if (title.length > 15) longTitle++;
        if (title.isEmpty) noTitle++;

        weekdays[dt.weekday - 1]++;
        months.add(dt.month);

        if (dt.month == 1 && dt.day == 1) newYear = true;
        if ((dt.month == 2 && dt.day == 14) || (dt.month == 5 && dt.day == 20))
          val = true;
        if (dt.month == 12 && dt.day == 25) xmas = true;
        if (dt.month == 12 && dt.day == 31) yearEnd = true;

        dailyFreq[dateKey] = (dailyFreq[dateKey] ?? 0) + 1;

        final justDate = DateTime(dt.year, dt.month, dt.day);
        if (lastDate == null) {
          currentStreak = 1;
        } else {
          final diff = lastDate.difference(justDate).inDays;
          if (diff == 1) {
            currentStreak++;
          } else if (diff > 1) {
            if (currentStreak > maxStreak) maxStreak = currentStreak;
            currentStreak = 1;
          }
        }
        lastDate = justDate;
      }
      if (currentStreak > maxStreak) maxStreak = currentStreak;

      int maxFreq = 0;
      if (dailyFreq.isNotEmpty) {
        maxFreq = dailyFreq.values.reduce(
          (curr, next) => curr > next ? curr : next,
        );
      }

      setState(() {
        _totalCount = total;
        _morningCount = morning;
        _noonCount = noon;
        _afternoonCount = afternoon;
        _duskCount = dusk;
        _eveningCount = evening;
        _nightCount = midnight;
        _shortTextCount = shortText;
        _longTextCount = longText;
        _veryLongTextCount = veryLongText;
        _longTitleCount = longTitle;
        _noTitleCount = noTitle;
        _maxStreak = maxStreak;
        _weekdayCounts = weekdays;
        _monthsLogged = months;
        _hasNewYear = newYear;
        _hasValentines = val;
        _hasChristmas = xmas;
        _hasYearEnd = yearEnd;
        _maxDailyFrequency = maxFreq;
      });

      int unlocked = 0;
      for (var item in _achievements) {
        if ((item['check'] as Function)(this) as bool) {
          unlocked++;
          await _checkAndAward(item['id'], item['coin']);
        }
      }

      setState(() {
        _unlockedCount = unlocked;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Achievement Calc Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (UI Code 保持不變)
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('成就里程碑')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFA67C52)),
            )
          // ... (後續 UI 保持不變)
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("成就完成度：",
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                      Text(
                        "$_unlockedCount / ${_achievements.length}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA67C52),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: _achievements.length,
                    itemBuilder: (context, index) {
                      final item = _achievements[index];
                      final isUnlocked =
                          (item['check'] as Function)(this) as bool;
                      final progressStr =
                          (item['progress'] as Function)(this) as String;

                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              title: Column(
                                children: [
                                  Icon(item['icon'],
                                      size: 50,
                                      color: isUnlocked
                                          ? const Color(0xFFA67C52)
                                          : Colors.grey),
                                  const SizedBox(height: 10),
                                  Text(
                                    item['name'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: isUnlocked
                                            ? const Color(0xFFA67C52)
                                            : Colors.grey,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("目標：${item['desc']}",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black54)),
                                  const SizedBox(height: 15),
                                  if (progressStr.contains('/')) ...[
                                    Text(
                                      isUnlocked ? "已達成" : "目前進度：$progressStr",
                                      style: TextStyle(
                                          color: isUnlocked
                                              ? const Color(0xFFA67C52)
                                              : Colors.black87,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 15),
                                  ],
                                  Text("獎勵：${item['coin']} 旅幣",
                                      style: const TextStyle(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: isUnlocked
                                          ? const Color(0xFFFFF3E0)
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isUnlocked ? item['quote'] : "🔒 尚未解鎖",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: isUnlocked
                                              ? const Color(0xFF5D4037)
                                              : Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text("關閉"))
                              ],
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.brown.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4)),
                            ],
                            border: Border.all(
                              color: isUnlocked
                                  ? const Color(0xFFA67C52)
                                  : Colors.grey.shade200,
                              width: isUnlocked ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: isUnlocked
                                    ? const Color(0xFFA67C52).withOpacity(0.1)
                                    : Colors.grey[100],
                                child: Icon(
                                  item['icon'],
                                  size: 30,
                                  color: isUnlocked
                                      ? const Color(0xFFA67C52)
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                item['name'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isUnlocked
                                      ? const Color(0xFF3E2723)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
