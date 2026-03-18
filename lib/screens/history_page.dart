import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import 'detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  List<dynamic> _entries = [];
  List<dynamic> _filteredEntries = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  int _selectedInkColor = 0xFF3E2723;

  @override
  void initState() {
    super.initState();
    _fetchEntries();
    _loadInkColor();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInkColor() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedInkColor = prefs.getInt('selected_ink') ?? 0xFF3E2723;
    });
  }

  void _filterEntries() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredEntries = _entries.where((entry) {
        if (_selectedDate != null) {
          final dateStr = entry['created_at'] ?? '';
          final entryDate = DateTime.tryParse(dateStr)?.toLocal();
          if (entryDate == null) return false;

          final isSameDay = entryDate.year == _selectedDate!.year &&
              entryDate.month == _selectedDate!.month &&
              entryDate.day == _selectedDate!.day;

          if (!isSameDay) return false;
        }
        if (query.isNotEmpty) {
          final displayTitle = _getDisplayTitle(entry).toLowerCase();
          return displayTitle.contains(query);
        }
        return true;
      }).toList();
    });
  }

  void _onSearchChanged() {
    _filterEntries();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
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

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _filterEntries();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
    _filterEntries();
  }

  String _getDisplayTitle(dynamic entry) {
    final userTitle = entry['user_title'] as String?;
    final aiResponse = entry['ai_response'] as String? ?? '';

    if (userTitle != null && userTitle.isNotEmpty) {
      return userTitle;
    } else {
      if (aiResponse.contains('【') && aiResponse.contains('】')) {
        final start = aiResponse.indexOf('【') + 1;
        final end = aiResponse.indexOf('】');
        if (end > start) {
          return aiResponse.substring(start, end);
        }
      }
    }
    return "無標題";
  }

  Future<void> refreshData() async {
    await _fetchEntries();
    await _loadInkColor();
  }

  Future<void> _fetchEntries() async {
    if (!mounted) return;

    if (Supabase.instance.client.auth.currentUser?.id == null) {
      if (mounted) setState(() => _entries = []);
      return;
    }

    if (_entries.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await Supabase.instance.client
          .from('entries')
          .select(
              'id, created_at, user_title, user_diary, ai_response, image_url, ink_color, stamps_data, font_id')
          .order('created_at', ascending: false);

      if (!mounted) return;

      final data = response as List<dynamic>;

      setState(() {
        _entries = data;
        _isLoading = false;
      });
      _filterEntries();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Fetch Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🎯 修正：改為透明，這樣 MainScreen 的背景色就會透出來！
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('時光書架')),
      body: Column(
        children: [
          // --- 搜尋與篩選區 ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: _selectedDate == null
                          ? '搜尋回憶...'
                          : '在 ${DateFormat('MM/dd').format(_selectedDate!)} 搜尋...',
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFFA67C52)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFA67C52)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _selectedDate == null ? _pickDate : _clearDateFilter,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _selectedDate == null
                          ? Colors.white
                          : const Color(0xFFA67C52),
                      shape: BoxShape.circle,
                      border: _selectedDate == null
                          ? Border.all(color: Colors.grey.shade200)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Icon(
                      _selectedDate == null
                          ? Icons.calendar_month
                          : Icons.calendar_today,
                      color: _selectedDate == null
                          ? const Color(0xFFA67C52)
                          : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: GestureDetector(
                onTap: _clearDateFilter,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA67C52).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.filter_list,
                          size: 14, color: Color(0xFFA67C52)),
                      const SizedBox(width: 4),
                      Text(
                        "篩選中：${DateFormat('yyyy/MM/dd').format(_selectedDate!)} (點此清除)",
                        style: const TextStyle(
                            color: Color(0xFFA67C52),
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // --- 網格列表區域 ---
          Expanded(
            child: _isLoading && _entries.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFA67C52)))
                : _filteredEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                _entries.isEmpty
                                    ? Icons.menu_book
                                    : Icons.date_range_outlined,
                                size: 60,
                                color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              _entries.isEmpty
                                  ? "書架是空的"
                                  : (_selectedDate != null
                                      ? "這一天沒有寫日記"
                                      : "找不到相關日記"),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _fetchEntries();
                          await _loadInkColor();
                        },
                        color: const Color(0xFFA67C52),
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: _filteredEntries.length + 2,
                          itemBuilder: (context, index) {
                            if (index >= _filteredEntries.length) {
                              return const SizedBox();
                            }

                            final entry = _filteredEntries[index];
                            final dateStr = entry['created_at'] ?? '';
                            final date = DateTime.tryParse(dateStr);
                            final formattedDate = date != null
                                ? DateFormat('yyyy/MM/dd')
                                    .format(date.toLocal())
                                : '';
                            final displayTitle = _getDisplayTitle(entry);

                            final int entryInkColor =
                                entry['ink_color'] ?? _selectedInkColor;
                            final imageUrl = entry['image_url'] as String?;

                            return GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetailPage(entry: entry),
                                  ),
                                );
                                _fetchEntries();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(12)),
                                        child: (imageUrl != null &&
                                                imageUrl.isNotEmpty)
                                            ? CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Container(
                                                  color: Colors.grey[100],
                                                  child: const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Color(
                                                                0xFFA67C52)),
                                                  ),
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Container(
                                                  color: Colors.grey[100],
                                                  child: const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey),
                                                ),
                                              )
                                            : Container(
                                                color: Colors.grey[100],
                                                child: const Icon(
                                                    Icons.auto_stories,
                                                    color: Colors.grey,
                                                    size: 40),
                                              ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0, vertical: 8.0),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                displayTitle,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Color(entryInkColor),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                formattedDate,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
