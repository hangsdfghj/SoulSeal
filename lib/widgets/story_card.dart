import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoryCard extends StatelessWidget {
  final String story;
  final String quote;
  final String imageUrl;

  const StoryCard({
    super.key,
    required this.story,
    required this.quote,
    required this.imageUrl,
  });

  // 🎯 修正：處理斷句並隱藏所有標點和引號
  String _formatQuoteForDisplay(String text) {
    if (text.isEmpty) return "";

    // 1. 將主要標點替換為換行符號 \n
    String withBreaks = text
        .replaceAll('，', ',\n')
        .replaceAll('。', '.\n')
        .replaceAll('！', '!\n')
        .replaceAll('？', '?\n');

    // 2. 移除所有標點符號、引號和非必要符號 (使用 Unicode 逃脫碼，解決編譯衝突)
    // 移除目標：.,!?;:：。，！？、 " ' 『』「」 “ ”
    String cleaned = withBreaks.replaceAll(
        RegExp(r'''[.,!?;:：。，！？、"'\u201C\u201D\u300C\u300D\u300E\u300F]'''),
        '');

    // 3. 處理多餘的換行
    cleaned = cleaned.replaceAll(RegExp(r'\n+'), '\n');

    return cleaned.trim();
  }

  @override
  Widget build(BuildContext context) {
    final String finalQuote = _formatQuoteForDisplay(quote);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 智者的回響
          const Text(
            '智者的回響',
            style: TextStyle(
              color: Color(0xFFA67C52),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // 2. 故事內容
          Text(
            story,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF5D4037),
              height: 1.8,
            ),
            textAlign: TextAlign.justify,
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFFEEE0C9)),
          const SizedBox(height: 20),

          // 3. 郵票顯示 (置中區塊)
          Center(
            child: Column(
              children: [
                // 郵票圖
                if (imageUrl.isNotEmpty) ...[
                  Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFA67C52)),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 4. 耳語 / 金句
                const Text(
                  '耳語',
                  style: TextStyle(
                    color: Color(0xFFA67C52),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  finalQuote,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
