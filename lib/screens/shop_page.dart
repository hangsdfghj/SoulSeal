import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class ShopPage extends StatefulWidget {
  final Function(Color) onThemeChanged;
  const ShopPage({super.key, required this.onThemeChanged});

  @override
  State<ShopPage> createState() => ShopPageState();
}

class ShopPageState extends State<ShopPage> with TickerProviderStateMixin {
  int _coins = 0;
  List<String> _ownedItems = [
    'bg_default',
    'seal_default',
    'wax_red',
    'ink_default',
    'font_default',
    'magic_none',
  ];
  late TabController _tabController;

  // 🆕 追蹤每個分類的已選擇項目
  String? _selectedBg;
  String? _selectedFont;
  String? _selectedInk;
  String? _selectedSeal;
  String? _selectedWax;
  String? _selectedMagic;

  // ----------------------------------------------------------------
  // 🎯 專案最終商品列表定義 (START: 這裡只定義一次!)
  // ----------------------------------------------------------------

  // --- 1. 靈魂原色 (背景色) - 23 種 ---
  final List<Map<String, dynamic>> _bgProducts = [
    {
      'id': 'bg_default',
      'name': '初心米白',
      'price': 0,
      'color': 0xFFFDFBF7,
      'desc': '純粹的開始。'
    },
    {
      'id': 'bg_latte',
      'name': '午後拿鐵',
      'price': 20,
      'color': 0xFFEFEBE9,
      'desc': '像手沖咖啡般溫暖。'
    },
    {
      'id': 'bg_mint',
      'name': '薄荷微風',
      'price': 30,
      'color': 0xFFE0F2F1,
      'desc': '清新的思緒。'
    },
    {
      'id': 'bg_sky',
      'name': '天空湛藍',
      'price': 50,
      'color': 0xFFE3F2FD,
      'desc': '藍天般開闊，無限自由。'
    },
    {
      'id': 'bg_lavender',
      'name': '薰衣草夢',
      'price': 50,
      'color': 0xFFF3E5F5,
      'desc': '寧靜的紫色夢境。'
    },
    {
      'id': 'bg_peach',
      'name': '蜜桃粉',
      'price': 60,
      'color': 0xFFFFECB3,
      'desc': '甜美而溫柔。'
    },
    {
      'id': 'bg_rose_quartz',
      'name': '玫瑰晶',
      'price': 70,
      'color': 0xFFFCE4EC,
      'desc': '愛的能量，溫暖包容。'
    },
    {
      'id': 'bg_cloud',
      'name': '雲朵白',
      'price': 80,
      'color': 0xFFF5F5F5,
      'desc': '輕盈無暇，雲朵般柔軟。'
    },
    {
      'id': 'bg_sand',
      'name': '細沙淺黃',
      'price': 80,
      'color': 0xFFFFFDE7,
      'desc': '溫暖的沙灘記憶。'
    },
    {
      'id': 'bg_aurora',
      'name': '極光綠',
      'price': 100,
      'color': 0xFFE8F5E9,
      'desc': '大自然的治癒力。'
    },
    {
      'id': 'bg_mist_gray',
      'name': '薄霧灰',
      'price': 100,
      'color': 0xFFECEFF1,
      'desc': '低調的優雅，沉穩平靜。'
    },
    {
      'id': 'bg_lemonade',
      'name': '檸檬汽水',
      'price': 120,
      'color': 0xFFFFF9C4,
      'desc': '充滿活力，夏日的陽光。'
    },
    {
      'id': 'bg_bubblegum',
      'name': '泡泡糖',
      'price': 120,
      'color': 0xFFF8BBD0,
      'desc': '俏皮可愛，甜甜的回憶。'
    },
    {
      'id': 'bg_water_lily',
      'name': '睡蓮淺紫',
      'price': 150,
      'color': 0xFFE1BEE7,
      'desc': '清雅脫俗，靜謐的溫柔。'
    },
    {
      'id': 'bg_ocean_foam',
      'name': '海沫白',
      'price': 150,
      'color': 0xFFE0F7FA,
      'desc': '海浪拍岸，洗滌心靈。'
    },
    {
      'id': 'bg_matcha',
      'name': '日式抹茶',
      'price': 160,
      'color': 0xFFF1F8E9,
      'desc': '茶道的寧靜致遠。'
    },
    {
      'id': 'bg_linen',
      'name': '亞麻織物',
      'price': 160,
      'color': 0xFFFAF0E6,
      'desc': '樸實無華的質感。'
    },
    {
      'id': 'bg_sakura_snow',
      'name': '櫻吹雪',
      'price': 180,
      'color': 0xFFFFF0F5,
      'desc': '花瓣飄落的瞬間。'
    },
    {
      'id': 'bg_baby_blue',
      'name': '嬰兒粉藍',
      'price': 180,
      'color': 0xFFE1F5FE,
      'desc': '初生的純淨與希望。'
    },
    {
      'id': 'bg_honeydew',
      'name': '蜜瓜甜綠',
      'price': 180,
      'color': 0xFFF0F4C3,
      'desc': '清爽的夏日滋味。'
    },
    {
      'id': 'bg_periwinkle',
      'name': '長春花藍',
      'price': 200,
      'color': 0xFFE8EAF6,
      'desc': '介於藍與紫的夢幻。'
    },
    {
      'id': 'bg_old_lace',
      'name': '蕾絲舊白',
      'price': 200,
      'color': 0xFFFDF5E6,
      'desc': '復古的優雅記憶。'
    },
    {
      'id': 'bg_moonlight',
      'name': '月光微塵',
      'price': 250,
      'color': 0xFFFAFAFA,
      'desc': '極致的白，無塵之境。'
    },
  ];

  // --- 2. 歲月字跡 (Fonts) - 8 種 ---
  final List<Map<String, dynamic>> _fontProducts = [
    {
      'id': 'font_default',
      'name': '系統黑體',
      'price': 0,
      'font': null,
      'desc': '清晰易讀，數位原聲。'
    },
    {
      'id': 'font_serif',
      'name': '經典明體',
      'price': 80,
      'font': GoogleFonts.notoSerifTc,
      'desc': '書卷氣息，優雅閱讀。'
    },
    {
      'id': 'font_hand',
      'name': '行雲流水',
      'price': 120,
      'font': GoogleFonts.kleeOne,
      'desc': '溫暖的手寫感。'
    },
    {
      'id': 'font_calligraphy',
      'name': '古風雅韻',
      'price': 150,
      'font': GoogleFonts.yujiSyuku,
      'desc': '古典書法韻味。'
    },
    {
      'id': 'font_cute',
      'name': '溫柔小薇',
      'price': 150,
      'font': GoogleFonts.zenMaruGothic,
      'desc': '圓潤可愛的日常。'
    },
    {
      'id': 'font_pixel',
      'name': '數位懷舊',
      'price': 180,
      'font': GoogleFonts.dotGothic16,
      'desc': '8-bit 的復古記憶。'
    },
    {
      'id': 'font_marker',
      'name': '童趣蠟筆',
      'price': 180,
      'font': GoogleFonts.hachiMaruPop,
      'desc': '像孩子般的純真筆觸。'
    },
    {
      'id': 'font_romance',
      'name': '大正浪漫',
      'price': 200,
      'font': GoogleFonts.shipporiMincho,
      'desc': '如舊小說般的文學氣質。'
    },
  ];

  // --- 3. 夢幻墨水 (Ink Colors) - 20 種 ---
  final List<Map<String, dynamic>> _inkProducts = [
    {
      'id': 'ink_default',
      'name': '古典深褐',
      'price': 0,
      'color': 0xFF3E2723,
      'desc': '羊皮紙上的經典，沉穩。'
    },
    {
      'id': 'ink_black',
      'name': '午夜極黑',
      'price': 20,
      'color': 0xFF212121,
      'desc': '最純粹的黑。'
    },
    {
      'id': 'ink_blue',
      'name': '普魯士藍',
      'price': 50,
      'color': 0xFF1A237E,
      'desc': '深邃，智慧的流淌。'
    },
    {
      'id': 'ink_green',
      'name': '松林墨綠',
      'price': 50,
      'color': 0xFF1B5E20,
      'desc': '森林氣息，自然的生機。'
    },
    {
      'id': 'ink_red',
      'name': '勃艮第紅',
      'price': 80,
      'color': 0xFF880E4F,
      'desc': '如紅酒般優雅，熱情。'
    },
    {
      'id': 'ink_purple',
      'name': '皇室紫',
      'price': 80,
      'color': 0xFF4A148C,
      'desc': '高貴的象徵，神秘。'
    },
    {
      'id': 'ink_teal',
      'name': '孔雀藍綠',
      'price': 100,
      'color': 0xFF006064,
      'desc': '獨特品味，靜謐的魅力。'
    },
    {
      'id': 'ink_sepia',
      'name': '歲月棕色',
      'price': 120,
      'color': 0xFF795548,
      'desc': '舊照片的溫度，懷舊。'
    },
    {
      'id': 'ink_lavender',
      'name': '薰衣草紫',
      'price': 120,
      'color': 0xFF7B1FA2,
      'desc': '溫柔的紫色，夢幻浪漫。'
    },
    {
      'id': 'ink_sky_blue',
      'name': '晴空淺藍',
      'price': 100,
      'color': 0xFF81D4FA,
      'desc': '像天空一樣清澈。'
    },
    {
      'id': 'ink_gold_ochre',
      'name': '大地土',
      'price': 150,
      'color': 0xFFC59140,
      'desc': '泥土的芬芳，古老堅韌。'
    },
    {
      'id': 'ink_emerald',
      'name': '翠綠色',
      'price': 150,
      'color': 0xFF00C853,
      'desc': '生命的活力，充滿希望。'
    },
    {
      'id': 'ink_coral',
      'name': '珊瑚紅',
      'price': 160,
      'color': 0xFFFF7043,
      'desc': '海底的熱情與活力。'
    },
    {
      'id': 'ink_slate_grey',
      'name': '岩石灰',
      'price': 160,
      'color': 0xFF455A64,
      'desc': '堅定不移的意志。'
    },
    {
      'id': 'ink_mustard',
      'name': '芥末黃',
      'price': 180,
      'color': 0xFFF9A825,
      'desc': '復古的時尚感。'
    },
    {
      'id': 'ink_olive_drab',
      'name': '軍綠色',
      'price': 180,
      'color': 0xFF33691E,
      'desc': '野性的呼喚。'
    },
    {
      'id': 'ink_indigo',
      'name': '靛青色',
      'price': 200,
      'color': 0xFF283593,
      'desc': '傳統染織的工藝美。'
    },
    {
      'id': 'ink_maroon',
      'name': '栗紅色',
      'price': 200,
      'color': 0xFFB71C1C,
      'desc': '成熟穩重的氣質。'
    },
    {
      'id': 'ink_steel_blue',
      'name': '鋼鐵藍',
      'price': 220,
      'color': 0xFF4682B4,
      'desc': '冷靜而強大的力量。'
    },
    {
      'id': 'ink_charcoal',
      'name': '木炭灰',
      'price': 250,
      'color': 0xFF37474F,
      'desc': '素描筆觸的質感。'
    },
  ];

  // --- 4. 家族圖騰 (Seal Patterns) - 15 種 ---
  final List<Map<String, dynamic>> _sealProducts = [
    {
      'id': 'seal_default',
      'name': '旅人羅盤',
      'price': 0,
      'icon': Icons.explore,
      'desc': '指引方向，探索未知。'
    },
    {
      'id': 'seal_balance',
      'name': '平衡天秤',
      'price': 50,
      'icon': Icons.balance,
      'desc': '內心的寧靜，公正無私。'
    },
    {
      'id': 'seal_time',
      'name': '時光沙漏',
      'price': 80,
      'icon': Icons.hourglass_empty,
      'desc': '珍惜當下，記錄回憶。'
    },
    {
      'id': 'seal_sword',
      'name': '信念火花',
      'price': 100,
      'icon': Icons.auto_awesome,
      'desc': '信念火花，無畏的光芒。'
    },
    {
      'id': 'seal_key',
      'name': '命運之鑰',
      'price': 100,
      'icon': Icons.key,
      'desc': '開啟心扉，掌握未來。'
    },
    {
      'id': 'seal_moon',
      'name': '新月之眼',
      'price': 120,
      'icon': Icons.brightness_2,
      'desc': '寧靜的守望，夜晚密語。'
    },
    {
      'id': 'seal_heart',
      'name': '純真之心',
      'price': 120,
      'icon': Icons.favorite,
      'desc': '純粹的情感，愛的標誌。'
    },
    {
      'id': 'seal_anchor',
      'name': '堅定之錨',
      'price': 140,
      'icon': Icons.anchor,
      'desc': '穩定與依靠，永不漂泊。'
    },
    {
      'id': 'seal_cosmos',
      'name': '星辰軌跡',
      'price': 150,
      'icon': Icons.star_border,
      'desc': '宇宙的秩序，命運的引導。'
    },
    {
      'id': 'seal_feather',
      'name': '天鵝羽毛',
      'price': 150,
      'icon': Icons.brush,
      'desc': '輕盈與自由，心之所向。'
    },
    {
      'id': 'seal_eye',
      'name': '覺醒之眼',
      'price': 150,
      'icon': Icons.remove_red_eye_outlined,
      'desc': '洞察真相，靈性覺醒。'
    },
    {
      'id': 'seal_mountain',
      'name': '山峰輪廓',
      'price': 160,
      'icon': Icons.landscape,
      'desc': '挑戰巔峰，成就自我。'
    },
    {
      'id': 'seal_flow',
      'name': '靈魂之潮',
      'price': 180,
      'icon': Icons.waves,
      'desc': '順應生命的流動與直覺。'
    },
    {
      'id': 'seal_star_light',
      'name': '希望之星',
      'price': 180,
      'icon': Icons.star,
      'desc': '閃耀的夢想，指引前路。'
    },
    {
      'id': 'seal_tree',
      'name': '生命之樹',
      'price': 200,
      'icon': Icons.park,
      'desc': '生長與連結，生命奇蹟。'
    },
  ];

  // --- 5. 秘制蠟色 (Wax Colors) ---
  final List<Map<String, dynamic>> _waxProducts = [
    {
      'id': 'wax_red',
      'name': '經典酒紅',
      'price': 0,
      'color': 0xFFB71C1C,
      'desc': '正統封印，熱情莊重。'
    },
    {
      'id': 'wax_gold',
      'name': '皇家流金',
      'price': 60,
      'color': 0xFFFFD700,
      'desc': '奢華的象徵，閃耀榮光。'
    },
    {
      'id': 'wax_silver',
      'name': '月光銀霜',
      'price': 80,
      'color': 0xFFBDBDBD,
      'desc': '高冷而純潔，月色清輝。'
    },
    {
      'id': 'wax_black',
      'name': '黑曜石',
      'price': 100,
      'color': 0xFF212121,
      'desc': '深沉的秘密，神秘力量。'
    },
    {
      'id': 'wax_blue',
      'name': '深海湛藍',
      'price': 60,
      'color': 0xFF0D47A1,
      'desc': '冷靜與理智，深邃智慧。'
    },
    {
      'id': 'wax_teal',
      'name': '孔雀石綠',
      'price': 120,
      'color': 0xFF00695C,
      'desc': '珍稀寶石，獨特光澤。'
    },
    {
      'id': 'wax_green',
      'name': '森林墨綠',
      'price': 60,
      'color': 0xFF1B5E20,
      'desc': '生機盎然，自然的氣息。'
    },
    {
      'id': 'wax_purple',
      'name': '神秘紫羅蘭',
      'price': 80,
      'color': 0xFF4A148C,
      'desc': '高貴優雅，神秘的魅力。'
    },
    {
      'id': 'wax_copper',
      'name': '古銅輝煌',
      'price': 100,
      'color': 0xFFB74106,
      'desc': '歲月沉澱，復古華麗。'
    },
    {
      'id': 'wax_pearl',
      'name': '珍珠貝白',
      'price': 120,
      'color': 0xFFF5F5DC,
      'desc': '溫潤光澤，純潔而典雅。'
    },
    {
      'id': 'wax_rose_gold',
      'name': '玫瑰金',
      'price': 150,
      'color': 0xFFB76E79,
      'desc': '時尚與浪漫，永恆的愛。'
    },
    {
      'id': 'wax_emerald',
      'name': '祖母綠',
      'price': 150,
      'color': 0xFF006A4E,
      'desc': '高雅與財富，翠綠希望。'
    },
    {
      'id': 'wax_sakura',
      'name': '櫻花粉',
      'price': 160,
      'color': 0xFFF48FB1,
      'desc': '春日的浪漫氣息。'
    },
    {
      'id': 'wax_orange',
      'name': '琥珀橙',
      'price': 160,
      'color': 0xFFFF6F00,
      'desc': '凝固的陽光與時間。'
    },
    {
      'id': 'wax_sky',
      'name': '天青石',
      'price': 180,
      'color': 0xFF42A5F5,
      'desc': '雨過天青的色澤。'
    },
    {
      'id': 'wax_slate',
      'name': '板岩灰',
      'price': 180,
      'color': 0xFF546E7A,
      'desc': '堅硬與永恆的誓言。'
    },
    {
      'id': 'wax_bronze',
      'name': '青銅時代',
      'price': 200,
      'color': 0xFF827717,
      'desc': '歷史的厚重與光輝。'
    },
    {
      'id': 'wax_olive',
      'name': '橄欖綠',
      'price': 200,
      'color': 0xFF558B2F,
      'desc': '和平與智慧的象徵。'
    },
    {
      'id': 'wax_lilac',
      'name': '丁香紫',
      'price': 220,
      'color': 0xFFBA68C8,
      'desc': '淡淡的思念與愁緒。'
    },
    {
      'id': 'wax_white',
      'name': '雪花白',
      'price': 250,
      'color': 0xFFFAFAFA,
      'desc': '純白無瑕的信箋。'
    },
  ];

  // --- 6. 古老魔法 (Magic Effects) ---
  final List<Map<String, dynamic>> _magicProducts = [
    {
      'id': 'magic_none',
      'name': '魔力枯竭',
      'price': 0,
      'effect': 'none',
      'desc': '普通的物理狀態。'
    },
    {
      'id': 'magic_shine',
      'name': '星光流動',
      'price': 250,
      'effect': 'shine',
      'desc': '純淨的白光緩緩流動。'
    },
    {
      'id': 'magic_pulse',
      'name': '靈魂呼吸',
      'price': 300,
      'effect': 'pulse',
      'desc': '忽明忽暗，彷彿有生命。'
    },
    {
      'id': 'magic_gold_shine',
      'name': '帝王金光',
      'price': 500,
      'effect': 'shine_gold',
      'desc': '象徵權力與財富的輝煌。'
    },
    {
      'id': 'magic_silver_shine',
      'name': '月夜銀光',
      'price': 400,
      'effect': 'shine_silver',
      'desc': '冷冽而高貴的鋒芒。'
    },
    {
      'id': 'magic_bronze_shine',
      'name': '古銅輝光',
      'price': 350,
      'effect': 'shine_bronze',
      'desc': '歷經歲月磨礪的光澤。'
    },
    {
      'id': 'magic_rainbow',
      'name': '幻彩稜鏡',
      'price': 600,
      'effect': 'rainbow',
      'desc': '折射出七彩的夢幻光暈。'
    },
    {
      'id': 'magic_void',
      'name': '虛空迷霧',
      'price': 600,
      'effect': 'void',
      'desc': '深邃的暗影在周圍流動。'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    refreshCoins();
    _loadSelectedItems(); // 🆕 載入已選擇項目
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 🆕 載入已選擇項目
  Future<void> _loadSelectedItems() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedBg = prefs.getString('theme_color_selected_id') ?? 'bg_default';
      _selectedFont = prefs.getString('selected_font') ?? 'font_default';
      _selectedInk = prefs.getString('selected_ink_id') ?? 'ink_default';
      _selectedSeal = prefs.getString('selected_seal') ?? 'seal_default';
      _selectedWax = prefs.getString('selected_wax_id') ?? 'wax_red';
      _selectedMagic = prefs.getString('selected_magic') ?? 'magic_none';
    });
  }

  Future<void> refreshCoins() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _coins = prefs.getInt('coins') ?? 0;
      _ownedItems = prefs.getStringList('owned_items') ??
          [
            'bg_default',
            'seal_default',
            'wax_red',
            'ink_default',
            'font_default',
            'magic_none'
          ];
    });
  }

  Future<void> _addTestCoins() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt('coins') ?? 0;
    await prefs.setInt('coins', current + 10000);
    refreshCoins();
    _showMsg("🤑 測試密技：獲得 10,000 旅幣！財富自由啦！");
  }

  Future<void> _handleItem(Map<String, dynamic> item, String type) async {
    final prefs = await SharedPreferences.getInstance();
    String id = item['id']?.toString() ?? '';
    int price = item['price'] as int? ?? 0;
    bool isOwned = _ownedItems.contains(id);

    if (isOwned) {
      if (type == 'bg') {
        await prefs.setInt('theme_color', item['color'] as int? ?? 0xFFFDFBF7);
        await prefs.setString('theme_color_selected_id', id); // 🆕
        widget.onThemeChanged(Color(item['color'] as int? ?? 0xFFFDFBF7));
        setState(() => _selectedBg = id); // 🆕
        _showMsg("✨ 背景已更換為「${item['name'] ?? ''}」");
      } else if (type == 'seal') {
        await prefs.setString('selected_seal', id);
        setState(() => _selectedSeal = id); // 🆕
        widget.onThemeChanged(Color(prefs.getInt('theme_color') ?? 0xFFFDFBF7));
        _showMsg("🛡️ 已選擇圖騰：「${item['name'] ?? ''}」");
      } else if (type == 'wax') {
        await prefs.setInt('selected_wax', item['color'] as int? ?? 0xFFB71C1C);
        await prefs.setString('selected_wax_id', id); // 🆕
        setState(() => _selectedWax = id); // 🆕
        widget.onThemeChanged(Color(prefs.getInt('theme_color') ?? 0xFFFDFBF7));
        _showMsg("🕯️ 已選擇蠟色：「${item['name'] ?? ''}」");
      } else if (type == 'ink') {
        await prefs.setInt('selected_ink', item['color'] as int? ?? 0xFF3E2723);
        await prefs.setString('selected_ink_id', id); // 🆕
        setState(() => _selectedInk = id); // 🆕
        widget.onThemeChanged(Color(prefs.getInt('theme_color') ?? 0xFFFDFBF7));
        _showMsg("✒️ 已沾取墨水：「${item['name'] ?? ''}」");
      } else if (type == 'font') {
        await prefs.setString('selected_font', id);
        setState(() => _selectedFont = id); // 🆕
        widget.onThemeChanged(Color(prefs.getInt('theme_color') ?? 0xFFFDFBF7));
        _showMsg("✍️ 已更換筆跡：「${item['name'] ?? ''}」");
      } else if (type == 'magic') {
        await prefs.setString('selected_magic', id);
        setState(() => _selectedMagic = id); // 🆕
        widget.onThemeChanged(Color(prefs.getInt('theme_color') ?? 0xFFFDFBF7));
        _showMsg("✨ 已注入魔法：「${item['name'] ?? ''}」");
      }
    } else {
      if (_coins >= price) {
        await prefs.setInt('coins', _coins - price);
        _ownedItems.add(id);
        await prefs.setStringList('owned_items', _ownedItems);
        refreshCoins();
        _showMsg("🎉 購買成功！獲得「${item['name'] ?? ''}」，消耗 $price 旅幣");
      } else {
        _showMsg("💸 旅幣不足");
      }
    }
  }

  void _showMsg(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> currentProducts;
    String currentType;

    switch (_tabController.index) {
      case 0:
        currentProducts = _bgProducts;
        currentType = 'bg';
        break;
      case 1:
        currentProducts = _fontProducts;
        currentType = 'font';
        break;
      case 2:
        currentProducts = _inkProducts;
        currentType = 'ink';
        break;
      case 3:
        currentProducts = _sealProducts;
        currentType = 'seal';
        break;
      case 4:
        currentProducts = _waxProducts;
        currentType = 'wax';
        break;
      case 5:
        currentProducts = _magicProducts;
        currentType = 'magic';
        break;
      default:
        currentProducts = _bgProducts;
        currentType = 'bg';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('旅途雜貨舖'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0.0, 0.85, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: const Color(0xFFA67C52),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFA67C52),
                labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                tabs: const [
                  Tab(text: "靈魂原色", icon: Icon(Icons.palette)),
                  Tab(text: "歲月字跡", icon: Icon(Icons.text_fields)),
                  Tab(text: "夢幻墨水", icon: Icon(Icons.create)),
                  Tab(text: "家族圖騰", icon: Icon(Icons.verified)),
                  Tab(text: "秘制蠟色", icon: Icon(Icons.water_drop)),
                  Tab(text: "古老魔法", icon: Icon(Icons.auto_fix_high)),
                ],
                onTap: (index) {
                  setState(() {});
                },
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: GestureDetector(
                onTap: _addTestCoins,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA67C52).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFA67C52).withOpacity(0.3)),
                  ),
                  child: Text(
                    "💰 $_coins",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFA67C52),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGrid(_bgProducts, 'bg'),
          _buildGrid(_fontProducts, 'font'),
          _buildGrid(_inkProducts, 'ink'),
          _buildGrid(_sealProducts, 'seal'),
          _buildGrid(_waxProducts, 'wax'),
          _buildGrid(_magicProducts, 'magic'),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> products, String type) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final item = products[index];
        bool isOwned = _ownedItems.contains(item['id']);

        // 🆕 判斷是否已選擇
        bool isSelected = false;
        if (type == 'bg' && item['id'] == _selectedBg) isSelected = true;
        if (type == 'font' && item['id'] == _selectedFont) isSelected = true;
        if (type == 'ink' && item['id'] == _selectedInk) isSelected = true;
        if (type == 'seal' && item['id'] == _selectedSeal) isSelected = true;
        if (type == 'wax' && item['id'] == _selectedWax) isSelected = true;
        if (type == 'magic' && item['id'] == _selectedMagic) isSelected = true;

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    color: Colors.grey[50],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(child: _buildPreview(item, type)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? '商品',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(
                      height: 38,
                      child: Text(
                        item['desc'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () => _handleItem(item, type),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? const Color(0xFFA67C52) // 🆕 選中時按鈕變色
                              : (isOwned
                                  ? Colors.grey[200]
                                  : const Color(0xFFA67C52)),
                          foregroundColor: isSelected
                              ? Colors.white
                              : (isOwned ? Colors.black54 : Colors.white),
                          elevation: 0,
                        ),
                        child: Text(
                          isSelected
                              ? "✓ 已選擇" // 🆕 選中時顯示打勾
                              : (isOwned ? "選擇" : "${item['price']} 💰"),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreview(Map<String, dynamic> item, String type) {
    if (type == 'bg') {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Color(item['color']),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
      );
    } else if (type == 'seal') {
      return Icon(item['icon'], size: 50, color: const Color(0xFFA67C52));
    } else if (type == 'wax') {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Color(item['color']),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Color(item['color']).withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: const Icon(Icons.water_drop, color: Colors.white54, size: 20),
      );
    } else if (type == 'ink') {
      return Icon(Icons.create, size: 50, color: Color(item['color']));
    } else if (type == 'font') {
      final TextStyle style = item['font'] != null
          ? (item['font'] as Function)(
              textStyle:
                  const TextStyle(fontSize: 24, color: Color(0xFFA67C52)))
          : const TextStyle(fontSize: 24, color: Color(0xFFA67C52));
      return Text("永恆", style: style);
    } else if (type == 'magic') {
      Color shineColor = Colors.white;
      if (item['id'] == 'magic_gold_shine') shineColor = Colors.amber;
      if (item['id'] == 'magic_silver_shine')
        shineColor = const Color(0xFFB0BEC5);
      if (item['id'] == 'magic_bronze_shine')
        shineColor = const Color(0xFFCD7F32);

      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFB71C1C),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB71C1C), width: 3),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)
              ],
            ),
          ),
          if (item['id'] == 'magic_shine')
            const _PreviewWaxShine(color: Colors.white),
          if (item['id'] == 'magic_gold_shine')
            _PreviewWaxShine(color: Colors.amber),
          if (item['id'] == 'magic_silver_shine')
            _PreviewWaxShine(color: const Color(0xFFB0BEC5)),
          if (item['id'] == 'magic_bronze_shine')
            _PreviewWaxShine(color: const Color(0xFFCD7F32)),
          if (item['id'] == 'magic_pulse') const _PreviewWaxPulse(),
          if (item['id'] == 'magic_rainbow') const _PreviewWaxRainbow(),
          if (item['id'] == 'magic_void') const _PreviewWaxVoid(),
          const Icon(Icons.verified, color: Colors.black12, size: 30),
        ],
      );
    }
    return const SizedBox();
  }
}

// --- 商店預覽用的特效 Widget (保持不變) ---

class _PreviewWaxShine extends StatefulWidget {
  final Color color;
  const _PreviewWaxShine({this.color = Colors.white});
  @override
  State<_PreviewWaxShine> createState() => _PreviewWaxShineState();
}

class _PreviewWaxShineState extends State<_PreviewWaxShine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 3), vsync: this)
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: RotationTransition(
        turns: _controller,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: SweepGradient(
              center: Alignment.center,
              startAngle: 0.0,
              endAngle: 6.28,
              colors: [
                widget.color.withOpacity(0.0),
                widget.color.withOpacity(0.7),
                widget.color.withOpacity(0.0)
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewWaxPulse extends StatefulWidget {
  const _PreviewWaxPulse();
  @override
  State<_PreviewWaxPulse> createState() => _PreviewWaxPulseState();
}

class _PreviewWaxPulseState extends State<_PreviewWaxPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 2), vsync: this)
          ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 0.6).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(_animation.value * 0.5),
          ),
        );
      },
    );
  }
}

class _PreviewWaxRainbow extends StatefulWidget {
  const _PreviewWaxRainbow();
  @override
  State<_PreviewWaxRainbow> createState() => _PreviewWaxRainbowState();
}

class _PreviewWaxRainbowState extends State<_PreviewWaxRainbow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 5), vsync: this)
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: RotationTransition(
        turns: _controller,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: SweepGradient(
              center: Alignment.center,
              colors: [
                Colors.red.withOpacity(0.3),
                Colors.orange.withOpacity(0.3),
                Colors.yellow.withOpacity(0.3),
                Colors.green.withOpacity(0.3),
                Colors.blue.withOpacity(0.3),
                Colors.purple.withOpacity(0.3),
                Colors.red.withOpacity(0.3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewWaxVoid extends StatefulWidget {
  const _PreviewWaxVoid();
  @override
  State<_PreviewWaxVoid> createState() => _PreviewWaxVoidState();
}

class _PreviewWaxVoidState extends State<_PreviewWaxVoid>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 3), vsync: this)
          ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.2, end: 0.6).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(_animation.value)
              ],
              stops: const [0.4, 1.0],
            ),
          ),
        );
      },
    );
  }
}
