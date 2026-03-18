import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // 用於日期格式化
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../widgets/soul_loading.dart';
import '../widgets/story_card.dart';
import 'detail_page.dart';

class DiaryPage extends StatefulWidget {
  final VoidCallback? onSaved;
  final String? borderImage;
  const DiaryPage({super.key, this.onSaved, this.borderImage});

  @override
  State<DiaryPage> createState() => DiaryPageState();
}

class DiaryPageState extends State<DiaryPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _diaryController = TextEditingController();
  bool _isProcessing = false;
  String _statusMessage = "";

  // 🗑️ 已移除手動 VIP 開關
  // bool isVipUser = false;

  final List<String> defaultStamps = [
    'https://images.unsplash.com/photo-1518176258769-f227c798150e?auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1465146344425-f00d5f5c8f07?auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1477346611705-65d1883cee1e?auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1493246507139-91e8fad9978e?auto=format&fit=crop&w=500&q=80',
  ];

  Future<String> _uploadImageToSupabase(String openAiImageUrl) async {
    try {
      final imageResponse = await http.get(Uri.parse(openAiImageUrl));
      if (imageResponse.statusCode != 200) throw Exception("下載圖片失敗");
      final Uint8List imageBytes = imageResponse.bodyBytes;
      final fileName = "stamp_${DateTime.now().millisecondsSinceEpoch}.png";
      final uploadUrl =
          Uri.parse('$supabaseUrl/storage/v1/object/stamps/$fileName');
      final uploadResponse = await http.post(
        uploadUrl,
        headers: {
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'image/png',
        },
        body: imageBytes,
      );
      if (uploadResponse.statusCode != 200) throw Exception("上傳圖片失敗");
      return '$supabaseUrl/storage/v1/object/public/stamps/$fileName';
    } catch (e) {
      return openAiImageUrl;
    }
  }

  Future<void> _generateAndSave() async {
    final diaryText = _diaryController.text;
    final userTitle = _titleController.text.trim();
    if (diaryText.trim().isEmpty) return;
    FocusScope.of(context).unfocus();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("請先登入，才能保存您的日記。"), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = "正在確認靈魂契約..."; // 更新狀態訊息
    });

    // 🆕 1. 檢查 VIP 資格與額度
    bool canUseAiStamp = false;
    int currentUsed = 0;

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (profile != null) {
        final hasBeer = profile['has_beer'] ?? false;
        final hasWine = profile['has_wine'] ?? false;
        final hasSpirit = profile['has_spirit'] ?? false;

        // 計算總額度
        int limit = 0;
        if (hasBeer) limit += 1;
        if (hasWine) limit += 3;
        if (hasSpirit) limit += 5;

        final lastDate = profile['last_stamp_date'] as String?;
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

        // 跨日判斷
        if (lastDate == today) {
          currentUsed = profile['stamps_used_today'] ?? 0;
        } else {
          currentUsed = 0; // 新的一天，歸零
        }

        // 判斷是否還有額度
        if (limit > 0 && currentUsed < limit) {
          canUseAiStamp = true;
        }
      }
    } catch (e) {
      debugPrint("Profile check failed: $e");
    }

    setState(() {
      _statusMessage = "智者正在體會你的心聲...";
    });

    try {
      // 0. 讀取設定
      final prefs = await SharedPreferences.getInstance();
      final int currentInkColor = prefs.getInt('selected_ink') ?? 0xFF3E2723;
      final String currentFontId =
          prefs.getString('selected_font') ?? 'font_default';

      // 2. GPT 生成 (保持不變)
      final systemPrompt = StringBuffer();
      systemPrompt.writeln("你是一位「洞察世事的理性智者」。");
      systemPrompt.writeln("【任務】將日記轉化為隱喻故事，並構思一張「郵票畫面」。");
      systemPrompt.writeln(
          "【格式規則】請嚴格遵守「三段式輸出」，每段之間用 '---' 分隔：\n故事內容\n---\n低語(金句)\n---\n郵票英文指令");

      final textResponse = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiApiKey',
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {"role": "system", "content": systemPrompt.toString()},
            {"role": "user", "content": diaryText},
          ],
          "temperature": 0.7,
        }),
      );

      if (!mounted) return;
      if (textResponse.statusCode != 200) throw Exception("GPT Error");

      // 根據 VIP 狀態顯示不同訊息
      setState(() => _statusMessage =
          canUseAiStamp ? "智者正在為你繪製靈感郵票..." : "智者正在從藏冊挑選經典郵票...");

      final data = jsonDecode(utf8.decode(textResponse.bodyBytes));
      final fullText = data['choices'][0]['message']['content'] as String;

      String story = "";
      String quote = "";
      String imagePrompt = "";

      final parts = fullText.split('---');
      if (parts.isNotEmpty) {
        story = parts[0]
            .trim()
            .replaceAll(RegExp(r'^[\d\.]+\s*'), '')
            .replaceAll(RegExp(r'^(故事|內容)[：:]\s*'), '');
      }
      if (parts.length >= 2) {
        quote = parts[1]
            .trim()
            .replaceAll(RegExp(r'^[\d\.]+\s*'), '')
            .replaceAll('【智者低語】', '')
            .replaceAll('【低語】', '')
            .replaceAll('智者低語：', '')
            .replaceAll('低語：', '')
            .replaceAll('金句：', '')
            .trim();
      }
      if (parts.length >= 3) {
        imagePrompt =
            "A mute, text-free artistic illustration framed by a white perforated postage stamp border on a white background. Subject: ${parts[2].trim()}. Style: Vintage vector art, detailed. NO TEXT.";
      } else {
        imagePrompt =
            "A mute, text-free artistic illustration framed by a white perforated postage stamp border. Abstract art representing hope. Vector art. NO TEXT.";
      }

      final cleanTextToSave = "$story\n---\n$quote";

      // 3. 圖片生成分流 (根據真實 VIP 狀態)
      String finalImageUrl = "";

      if (canUseAiStamp) {
        // --- VIP 路線：使用 DALL-E 3 ---
        String tempImageUrl = "";
        if (imagePrompt.isNotEmpty) {
          final imageResponse = await http.post(
            Uri.parse('https://api.openai.com/v1/images/generations'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $openAiApiKey',
            },
            body: jsonEncode({
              "model": "dall-e-3",
              "prompt": imagePrompt,
              "n": 1,
              "size": "1024x1024",
              "quality": "standard",
              "style": "vivid",
            }),
          );
          if (!mounted) return;
          if (imageResponse.statusCode == 200) {
            tempImageUrl = jsonDecode(imageResponse.body)['data'][0]['url'];
          }
        }

        setState(() => _statusMessage = "正在封存這段回憶...");

        if (tempImageUrl.isNotEmpty) {
          finalImageUrl = await _uploadImageToSupabase(tempImageUrl);

          // 🆕 關鍵：生成成功後，扣除額度
          try {
            await Supabase.instance.client.from('profiles').update({
              'stamps_used_today': currentUsed + 1,
              'last_stamp_date':
                  DateFormat('yyyy-MM-dd').format(DateTime.now()),
            }).eq('id', userId);
          } catch (e) {
            debugPrint("Usage update failed: $e");
          }
        } else {
          // 萬一 DALL-E 生成失敗，回退到預設圖，但不扣額度
          finalImageUrl = defaultStamps[Random().nextInt(defaultStamps.length)];
        }
      } else {
        // --- 普通路線：使用預設圖 ---
        await Future.delayed(const Duration(seconds: 2));
        setState(() => _statusMessage = "正在封存這段回憶...");
        finalImageUrl = defaultStamps[Random().nextInt(defaultStamps.length)];
      }

      // 4. 存檔
      final Map<String, dynamic> savedEntry = await _saveToSupabase(
        userTitle,
        diaryText,
        cleanTextToSave,
        finalImageUrl,
        currentInkColor,
        currentFontId,
      );

      int current = prefs.getInt('coins') ?? 0;
      await prefs.setInt('coins', current + 1);

      setState(() {
        _isProcessing = false;
        _statusMessage = "";
      });

      if (mounted) {
        _diaryController.clear();
        _titleController.clear();

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(entry: savedEntry, isNew: true),
          ),
        );

        widget.onSaved?.call();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("錯誤: $e")));
    }
  }

  Future<Map<String, dynamic>> _saveToSupabase(
    String title,
    String diary,
    String text,
    String imgUrl,
    int inkColor,
    String fontId,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from('entries')
          .insert({
            // user_id 由 DB 自動填入
            'user_title': title,
            'user_diary': diary,
            'ai_response': text,
            'image_url': imgUrl,
            'ink_color': inkColor,
            'font_id': fontId,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint("❌ Supabase 存檔錯誤: $e");
      throw Exception("存檔失敗: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('靈魂封緘')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isProcessing
            ? SoulLoadingWidget(message: _statusMessage)
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '今天，想給這段回憶什麼標題？',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFFA67C52),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _titleController,
                      maxLines: 1,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                      decoration: const InputDecoration(
                        hintText: '例如：考到駕照的一天',
                        prefixIcon: Icon(Icons.title, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '寫下你的心情...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFFA67C52),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _diaryController,
                      maxLines: 8,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Color(0xFF4A4A4A),
                      ),
                      decoration: const InputDecoration(hintText: '發生了什麼事...'),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _generateAndSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA67C52),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome),
                            SizedBox(width: 10),
                            Text(
                              '回憶封緘',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 🗑️ 已移除手動測試開關
                  ],
                ),
              ),
      ),
    );
  }
}
