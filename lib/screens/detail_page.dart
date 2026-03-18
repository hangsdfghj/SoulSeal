import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/story_card.dart';

// 1. 蠟章資料結構
class WaxSealData {
  final double x;
  final double y;
  final int color;
  final String iconCode;
  final double angle;
  final String magic;

  WaxSealData(this.x, this.y, this.color, this.iconCode, this.angle,
      [this.magic = 'magic_none']);

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'color': color,
        'iconCode': iconCode,
        'angle': angle,
        'magic': magic,
      };

  factory WaxSealData.fromJson(Map<String, dynamic> json) {
    final String defaultIconCode = Icons.explore.codePoint.toString();
    return WaxSealData(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
      json['color'] as int,
      json['iconCode'] as String? ?? defaultIconCode,
      (json['angle'] as num).toDouble(),
      json['magic'] as String? ?? 'magic_none',
    );
  }
}

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> entry;
  final bool isNew;
  const DetailPage({super.key, required this.entry, this.isNew = false});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _contentKey = GlobalKey();
  final ScreenshotController _screenshotController = ScreenshotController();

  late TextEditingController _titleController;
  late TextEditingController _diaryController;

  bool _isStampMode = false;
  bool _isEraseMode = false;
  bool _isStampingProcessing = false;
  bool _isSharing = false;
  bool _isEditMode = false;

  List<WaxSealData> _stamps = [];
  WaxSealData? _animatingWax;

  int _selectedWaxColor = 0xFFB71C1C;
  IconData _selectedSealIcon = Icons.explore;
  int _selectedInkColor = 0xFF3E2723;
  String _selectedFontId = 'font_default';
  String _selectedMagicId = 'magic_none';
  int _themeColor = 0xFFFDFBF7;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.entry['user_title'] ?? '');
    _diaryController =
        TextEditingController(text: widget.entry['user_diary'] ?? '');
    _loadUserPreferences();
    _loadStampsFromEntry();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    _diaryController.dispose();
    super.dispose();
  }

  void _loadStampsFromEntry() {
    final dynamic rawData = widget.entry['stamps_data'];
    List<dynamic> stampsJson = [];
    if (rawData is String && rawData.isNotEmpty) {
      try {
        stampsJson = jsonDecode(rawData);
      } catch (e) {
        debugPrint("Error decoding stamps: $e");
      }
    } else if (rawData is List<dynamic>) {
      stampsJson = rawData;
    }
    if (stampsJson.isNotEmpty) {
      setState(() {
        _stamps = stampsJson
            .map((json) => WaxSealData.fromJson(json as Map<String, dynamic>))
            .toList();
      });
    }
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedWaxColor = prefs.getInt('selected_wax') ?? 0xFFB71C1C;
      String sealId = prefs.getString('selected_seal') ?? 'seal_default';
      _selectedSealIcon = _getIconFromId(sealId);
      if (widget.entry['ink_color'] != null) {
        _selectedInkColor = widget.entry['ink_color'];
      } else {
        _selectedInkColor = prefs.getInt('selected_ink') ?? 0xFF3E2723;
      }
      if (widget.entry['font_id'] != null && widget.entry['font_id'] != '') {
        _selectedFontId = widget.entry['font_id'];
      } else {
        _selectedFontId = prefs.getString('selected_font') ?? 'font_default';
      }
      _selectedMagicId = prefs.getString('selected_magic') ?? 'magic_none';
      _themeColor = prefs.getInt('theme_color') ?? 0xFFFDFBF7;
    });
  }

  IconData _getIconFromId(String id) {
    switch (id) {
      case 'seal_inner_compass':
        return Icons.compass_calibration;
      case 'seal_default':
        return Icons.explore;
      case 'seal_balance':
        return Icons.balance;
      case 'seal_time':
        return Icons.hourglass_empty;
      case 'seal_sword':
        return Icons.auto_awesome;
      case 'seal_key':
        return Icons.key;
      case 'seal_moon':
        return Icons.brightness_2;
      case 'seal_heart':
        return Icons.favorite;
      case 'seal_anchor':
        return Icons.anchor;
      case 'seal_cosmos':
        return Icons.star_border;
      case 'seal_feather':
        return Icons.brush;
      case 'seal_eye':
        return Icons.remove_red_eye_outlined;
      case 'seal_mountain':
        return Icons.landscape;
      case 'seal_flow':
        return Icons.waves;
      case 'seal_star_light':
        return Icons.star;
      case 'seal_tree':
        return Icons.park;
      default:
        return Icons.explore;
    }
  }

  TextStyle _getStyledText(double fontSize, FontWeight weight) {
    TextStyle baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: weight,
      color: Color(_selectedInkColor),
    );
    switch (_selectedFontId) {
      case 'font_serif':
        return GoogleFonts.notoSerifTc(textStyle: baseStyle);
      case 'font_hand':
        return GoogleFonts.kleeOne(textStyle: baseStyle);
      case 'font_calligraphy':
        return GoogleFonts.yujiSyuku(textStyle: baseStyle);
      case 'font_cute':
        return GoogleFonts.zenMaruGothic(textStyle: baseStyle);
      case 'font_pixel':
        return GoogleFonts.dotGothic16(textStyle: baseStyle);
      case 'font_marker':
        return GoogleFonts.hachiMaruPop(textStyle: baseStyle);
      case 'font_romance':
        return GoogleFonts.shipporiMincho(textStyle: baseStyle);
      default:
        return baseStyle;
    }
  }

  // ✅ 修正：只保留這一個 _getMagicColor 定義
  Color _getMagicColor(String magicId) {
    if (magicId == 'magic_gold_shine') return Colors.amber;
    if (magicId == 'magic_silver_shine') return const Color(0xFFB0BEC5);
    if (magicId == 'magic_bronze_shine') return const Color(0xFFCD7F32);
    return Colors.white;
  }

  Future<void> _playSound(String fileName) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      debugPrint("音效播放失敗: $e");
    }
  }

  Future<void> _updateEntry() async {
    final newTitle = _titleController.text.trim();
    final newDiary = _diaryController.text;
    if (newDiary.isEmpty) return;
    try {
      await Supabase.instance.client
          .from('entries')
          .update({'user_title': newTitle, 'user_diary': newDiary}).eq(
              'id', widget.entry['id']);
      widget.entry['user_title'] = newTitle;
      widget.entry['user_diary'] = newDiary;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("✅ 修正已保存"), backgroundColor: Color(0xFFA67C52)));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("保存失敗: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _shareDiary() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("🎨 正在繪製靈魂明信片..."), duration: Duration(seconds: 2)));

      String quote = "";
      final aiResponse = widget.entry['ai_response'] as String? ?? '';
      if (aiResponse.contains('---')) {
        final parts = aiResponse.split('---');
        if (parts.length > 1) quote = parts[1].trim();
      }
      final imageUrl = widget.entry['image_url'] as String? ?? "";
      final dateStr = widget.entry['created_at'] ?? '';
      final date = DateTime.tryParse(dateStr) ?? DateTime.now();
      final formattedDate = DateFormat('yyyy.MM.dd').format(date.toLocal());
      WaxSealData? representativeSeal;
      if (_stamps.isNotEmpty) representativeSeal = _stamps.last;

      final Uint8List imageBytes =
          await _screenshotController.captureFromWidget(
        _buildShareCard(quote, imageUrl, formattedDate, representativeSeal),
        delay: const Duration(milliseconds: 100),
        pixelRatio: 3.0,
      );

      final directory = await getTemporaryDirectory();
      final imagePath =
          await File('${directory.path}/soullog_share.png').create();
      await imagePath.writeAsBytes(imageBytes);
      await Share.shareXFiles([XFile(imagePath.path)],
          text: '來自 SoulSeal 的靈魂低語 ✨');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("分享失敗: $e")));
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Widget _buildShareCard(
      String quote, String imageUrl, String date, WaxSealData? seal) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: Color(_themeColor), borderRadius: BorderRadius.circular(0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 調整間距，讓圖騰不跑版
          const SizedBox(height: 24),

          if (seal != null)
            Transform.rotate(
              angle: seal.angle,
              child: _buildStaticWaxSealWidget(seal, 100.0, 75.0, 50.0),
            )
          else
            const SizedBox(height: 40),
          if (quote.isNotEmpty)
            Text(
              _formatPoeticQuote(quote),
              textAlign: TextAlign.center,
              style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3E2723))
                  .copyWith(height: 1.8),
            ),
          const SizedBox(height: 40),
          if (imageUrl.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain, // 使用 contain 確保郵票完整顯示
              ),
            ),
          const SizedBox(height: 25),
          Text(date,
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  letterSpacing: 2.0,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 10),
          Text("SoulSeal",
              style: TextStyle(
                  color: Color(_selectedInkColor).withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0)),
        ],
      ),
    );
  }

  // 靜態蠟章繪製 (截圖用)
  Widget _buildStaticWaxSealWidget(
      WaxSealData seal, double size, double innerSize, double iconSize) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              color: Color(seal.color),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(2, 4))
              ],
              border: Border.all(
                  color: Color(seal.color).withOpacity(0.8), width: 5)),
        ),
        Center(
            child: Container(
                width: innerSize,
                height: innerSize,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12, width: 1.5)),
                child: Center(
                    child: Icon(
                        IconData(int.parse(seal.iconCode),
                            fontFamily: 'MaterialIcons'),
                        color: Colors.black12,
                        size: iconSize)))),
      ],
    );
  }

  String _formatPoeticQuote(String text) {
    if (text.isEmpty) return "";
    String formatted = text
        .trim()
        .replaceAll('「', '')
        .replaceAll('」', '')
        .replaceAll('『', '')
        .replaceAll('』', '')
        .replaceAll('“', '')
        .replaceAll('”', '')
        .replaceAll('"', '')
        .replaceAll("'", "")
        .replaceAll('，', '\n')
        .replaceAll('。', '\n')
        .replaceAll('！', '\n')
        .replaceAll('？', '\n')
        .replaceAll('、', '\n');
    formatted = formatted.replaceAll(RegExp(r'\n+'), '\n');
    return formatted.trim();
  }

  void _performStamp(TapUpDetails details) async {
    if (!mounted) return;
    if (!_isStampMode ||
        _isStampingProcessing ||
        _contentKey.currentContext == null) return;
    setState(() {
      _isStampingProcessing = true;
    });

    final RenderBox box =
        _contentKey.currentContext!.findRenderObject() as RenderBox;
    final Offset localOffset = box.globalToLocal(details.globalPosition);
    final double finalX = localOffset.dx - 40;
    final double finalY = localOffset.dy - 40;

    await _playSound('wax_pour.mp3');

    if (!mounted) return;
    setState(() {
      _animatingWax = WaxSealData(finalX, finalY, _selectedWaxColor, "", 0);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("🕯️ 正在滴蠟..."),
          duration: Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating));
    }
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("⏳ 等待冷卻定型..."),
          duration: Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating));
    }
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    await _playSound('stamp_peel.mp3');
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✨ 完成！"),
          duration: Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFA67C52)));
    }

    setState(() {
      _animatingWax = null;
      _stamps.add(WaxSealData(
          finalX,
          finalY,
          _selectedWaxColor,
          _selectedSealIcon.codePoint.toString(),
          Random().nextDouble() * 0.5 - 0.25,
          _selectedMagicId));
      _isStampingProcessing = false;
      _isStampMode = false;
    });
    _saveStampsToSupabase();
  }

  void _removeStamp(WaxSealData stampToRemove) {
    setState(() {
      _stamps.removeWhere((stamp) => stamp == stampToRemove);
    });
    _saveStampsToSupabase();
  }

  Future<void> _saveStampsToSupabase() async {
    if (!mounted) return;
    final List<Map<String, dynamic>> stampsJsonList =
        _stamps.map((seal) => seal.toJson()).toList();
    final String stampsJsonString = jsonEncode(stampsJsonList);
    widget.entry['stamps_data'] = stampsJsonString;
    try {
      if (widget.entry['id'] == null) return;
      await Supabase.instance.client
          .from('entries')
          .update({'stamps_data': stampsJsonList}).eq('id', widget.entry['id']);
    } catch (e) {
      debugPrint("保存失敗: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiResponse = widget.entry['ai_response'] as String? ?? '';
    final imageUrl = widget.entry['image_url'] as String?;
    final userTitle = widget.entry['user_title'] as String? ?? '(無內容)';
    final userDiary = widget.entry['user_diary'] as String? ?? '(無內容)';
    final dateStr = widget.entry['created_at'] ?? '';
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();
    final formattedDate = DateFormat('yyyy/MM/dd HH:mm').format(date.toLocal());

    String story = aiResponse;
    String quote = "";
    if (aiResponse.contains('---')) {
      final parts = aiResponse.split('---');
      story = parts[0].trim();
      if (parts.length > 1) quote = parts[1].trim();
    }

    Widget? hintWidget;
    if (_isStampMode) {
      hintWidget = const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.touch_app, size: 50, color: Colors.black26),
        Text("點擊任意處蓋章",
            style:
                TextStyle(color: Colors.black26, fontWeight: FontWeight.bold))
      ]));
    } else if (_isEraseMode) {
      hintWidget = const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.back_hand, size: 50, color: Colors.black26),
        Text("點擊印章以擦除",
            style:
                TextStyle(color: Colors.black26, fontWeight: FontWeight.bold))
      ]));
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, widget.entry);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: _isEditMode
              ? TextField(
                  controller: _titleController,
                  style: _getStyledText(20, FontWeight.bold),
                  decoration: const InputDecoration(
                      border: InputBorder.none, hintText: '輸入標題'))
              : Text(
                  _titleController.text.isEmpty
                      ? '珍藏回憶'
                      : _titleController.text,
                  style: _getStyledText(20, FontWeight.bold)),
          actions: [
            if (!_isStampMode && !_isEraseMode && !_isSharing)
              IconButton(
                  icon: Icon(_isEditMode ? Icons.check : Icons.edit,
                      color: const Color(0xFFA67C52)),
                  onPressed: () {
                    if (_isEditMode) {
                      _updateEntry();
                    }
                    setState(() {
                      _isEditMode = !_isEditMode;
                    });
                  }),
            if (!_isEditMode) ...[
              IconButton(
                  icon: const Icon(Icons.ios_share, color: Color(0xFFA67C52)),
                  onPressed:
                      _isStampingProcessing || _isSharing ? null : _shareDiary),
              IconButton(
                  icon: Icon(_isStampMode ? Icons.cancel : Icons.verified,
                      color:
                          _isStampMode ? Colors.red : const Color(0xFFA67C52)),
                  onPressed: _isStampingProcessing
                      ? null
                      : () {
                          setState(() {
                            _isStampMode = !_isStampMode;
                            _isEraseMode = false;
                          });
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  _isStampMode ? "👆 請點擊畫面任意處蓋章" : "已退出蓋章模式"),
                              duration: const Duration(seconds: 1)));
                        }),
              IconButton(
                  icon: Icon(
                      _isEraseMode ? Icons.close : Icons.cleaning_services,
                      color: _isEraseMode ? Colors.red : Colors.grey[600]),
                  onPressed: _isStampingProcessing
                      ? null
                      : () {
                          setState(() {
                            _isEraseMode = !_isEraseMode;
                            _isStampMode = false;
                          });
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  _isEraseMode ? "🗑️ 點擊印章以擦除" : "已退出擦拭模式"),
                              duration: const Duration(seconds: 1)));
                        }),
            ],
          ],
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Container(
                key: _contentKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.isNew)
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.only(bottom: 20),
                              child: Text("✨ 您的靈魂旅程已記錄 ✨",
                                  style: TextStyle(
                                      color: Color(0xFFA67C52),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)))),
                    Center(
                        child: Text(formattedDate,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14))),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(Icons.edit_note,
                                size: 16, color: Color(0xFFA67C52)),
                            SizedBox(width: 8),
                            Text("你的筆記",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFA67C52),
                                    fontWeight: FontWeight.bold))
                          ]),
                          const SizedBox(height: 8),
                          TextField(
                              controller: _diaryController,
                              enabled: _isEditMode,
                              maxLines: null,
                              style: _getStyledText(15, FontWeight.normal)
                                  .copyWith(height: 1.6),
                              decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    StoryCard(
                        story: story, quote: quote, imageUrl: imageUrl ?? ""),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              Positioned.fill(
                child: Stack(
                  children: [
                    ..._stamps
                        .map((seal) => Positioned(
                              left: seal.x,
                              top: seal.y,
                              child: GestureDetector(
                                onTap: _isEraseMode
                                    ? () => _removeStamp(seal)
                                    : null,
                                behavior: HitTestBehavior.translucent,
                                child: Transform.rotate(
                                    angle: seal.angle,
                                    child: Opacity(
                                        opacity: _isEraseMode ? 0.6 : 1.0,
                                        child: _buildWaxSealWidget(seal))),
                              ),
                            ))
                        .toList(),
                    if (_animatingWax != null)
                      Positioned(
                          left: _animatingWax!.x,
                          top: _animatingWax!.y,
                          child: _buildLiquidWaxWidget(_animatingWax!)),
                    if (_isStampMode || _isEraseMode)
                      Positioned.fill(
                          child: IgnorePointer(
                              ignoring: _isEraseMode,
                              child: GestureDetector(
                                  onTapUp: _isStampMode ? _performStamp : null,
                                  child: Container(
                                      color: Colors.black.withOpacity(0.05),
                                      child: Stack(children: [
                                        if (hintWidget != null) hintWidget!
                                      ]))))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 蠟章繪製 (動態效果)
  Widget _buildWaxSealWidget(WaxSealData seal) {
    double size = 80.0;
    double iconSize = 40.0;
    return Stack(alignment: Alignment.center, children: [
      // 底層：蠟基底
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: Color(seal.color),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 5,
                  offset: const Offset(2, 4)),
              BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(-2, -2),
                  spreadRadius: 0)
            ],
            border: Border.all(
                color: Color(seal.color).withOpacity(0.8), width: 4)),
      ),
      // 中層：特效
      if (seal.magic.contains('shine'))
        ClipOval(
            child: SizedBox(
                width: size,
                height: size,
                child: _WaxShineEffect(color: _getMagicColor(seal.magic)))),
      if (seal.magic.contains('rainbow'))
        ClipOval(
            child: SizedBox(
                width: size, height: size, child: const _WaxRainbowEffect())),
      if (seal.magic.contains('void'))
        ClipOval(
            child: SizedBox(
                width: size, height: size, child: const _WaxVoidEffect())),
      if (seal.magic == 'magic_pulse')
        ClipOval(
            child: SizedBox(
                width: size, height: size, child: const _WaxPulseEffect())),
      // 頂層：圖案
      Center(
          child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12, width: 1)),
              child: Center(
                  child: Icon(
                      IconData(int.parse(seal.iconCode),
                          fontFamily: 'MaterialIcons'),
                      color: Colors.black12,
                      size: iconSize)))),
    ]);
  }

  Widget _buildLiquidWaxWidget(WaxSealData seal) {
    return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
            color: Color(seal.color),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(2, 2))
            ]));
  }
}

// --- 郵票裁切器 ---
class _ShareStampClipper extends CustomClipper<Path> {
  final double holeRadius;
  _ShareStampClipper({this.holeRadius = 8});
  @override
  Path getClip(Size size) {
    final path = Path();
    double w = size.width;
    double h = size.height;
    double d = holeRadius * 2;
    path.moveTo(0, 0);
    int countX = (w / d).floor();
    double gapX = (w - (countX * d)) / 2;
    path.lineTo(gapX, 0);
    for (int i = 0; i < countX; i++) {
      path.relativeLineTo(0, 0);
      path.relativeArcToPoint(Offset(d, 0),
          radius: Radius.circular(holeRadius), clockwise: false);
    }
    path.lineTo(w, 0);
    int countY = (h / d).floor();
    double gapY = (h - (countY * d)) / 2;
    path.lineTo(w, gapY);
    for (int i = 0; i < countY; i++) {
      path.relativeLineTo(0, 0);
      path.relativeArcToPoint(Offset(0, d),
          radius: Radius.circular(holeRadius), clockwise: false);
    }
    path.lineTo(w, h);
    path.lineTo(w - gapX, h);
    for (int i = 0; i < countX; i++) {
      path.relativeLineTo(0, 0);
      path.relativeArcToPoint(Offset(-d, 0),
          radius: Radius.circular(holeRadius), clockwise: false);
    }
    path.lineTo(0, h);
    path.lineTo(0, h - gapY);
    for (int i = 0; i < countY; i++) {
      path.relativeLineTo(0, 0);
      path.relativeArcToPoint(Offset(0, -d),
          radius: Radius.circular(holeRadius), clockwise: false);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

// --- 特效 Widgets ---
class _WaxShineEffect extends StatefulWidget {
  final Color color;
  const _WaxShineEffect({this.color = Colors.white});
  @override
  State<_WaxShineEffect> createState() => _WaxShineEffectState();
}

class _WaxShineEffectState extends State<_WaxShineEffect>
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
    return RotationTransition(
        turns: _controller,
        child: Container(
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
                    stops: const [
              0.0,
              0.5,
              1.0
            ]))));
  }
}

class _WaxPulseEffect extends StatefulWidget {
  const _WaxPulseEffect();
  @override
  State<_WaxPulseEffect> createState() => _WaxPulseEffectState();
}

class _WaxPulseEffectState extends State<_WaxPulseEffect>
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
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(_animation.value)));
        });
  }
}

class _WaxRainbowEffect extends StatefulWidget {
  const _WaxRainbowEffect();
  @override
  State<_WaxRainbowEffect> createState() => _WaxRainbowEffectState();
}

class _WaxRainbowEffectState extends State<_WaxRainbowEffect>
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
    return RotationTransition(
        turns: _controller,
        child: Container(
            decoration: BoxDecoration(
                gradient: SweepGradient(center: Alignment.center, colors: [
          Colors.red.withOpacity(0.6),
          Colors.orange.withOpacity(0.6),
          Colors.yellow.withOpacity(0.6),
          Colors.green.withOpacity(0.6),
          Colors.blue.withOpacity(0.6),
          Colors.purple.withOpacity(0.6),
          Colors.red.withOpacity(0.6)
        ]))));
  }
}

class _WaxVoidEffect extends StatefulWidget {
  const _WaxVoidEffect();
  @override
  State<_WaxVoidEffect> createState() => _WaxVoidEffectState();
}

class _WaxVoidEffectState extends State<_WaxVoidEffect>
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
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(_animation.value)
                  ], stops: const [
                    0.4,
                    1.0
                  ])));
        });
  }
}
