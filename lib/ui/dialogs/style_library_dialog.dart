import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/style_model.dart';
import '../../services/style_service.dart';

class StyleLibraryDialog extends StatefulWidget {
  final String currentStyleText;
  final ValueChanged<String> onStyleSelected;

  const StyleLibraryDialog({
    super.key,
    required this.currentStyleText,
    required this.onStyleSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentStyleText,
    required ValueChanged<String> onStyleSelected,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StyleLibraryDialog(
        currentStyleText: currentStyleText,
        onStyleSelected: onStyleSelected,
      ),
    );
  }

  @override
  State<StyleLibraryDialog> createState() => _StyleLibraryDialogState();
}

class _StyleLibraryDialogState extends State<StyleLibraryDialog> {
  final TextEditingController _searchController = TextEditingController();
  final StyleService _styleService = StyleService.instance;
  int _selectedTab = 0; // 0: Geçmiş (History), 1: Kütüphane (Presets), 2: Favoriler
  String _selectedCategory = 'Tümü';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _styleService.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _styleService.removeListener(_onServiceUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _showSaveCurrentDialog() {
    final titleCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E28) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.bookmark_add_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Tarza İsim Ver & Sabitle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu müzik tarzını sık kullanılanlara eklemek için bir başlık belirleyin:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Ör: Gece Sürüşü Synthwave',
                labelText: 'Tarz Başlığı',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final title = titleCtrl.text.trim();
              _styleService.saveCustomStyle(
                prompt: widget.currentStyleText,
                title: title.isNotEmpty ? title : 'Özel Tarz',
              );
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"$title" tarzı favorilere kaydedildi!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF16161E) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF2C2C3C) : const Color(0xFFE2E8F0);
    final query = _searchController.text.trim().toLowerCase();

    // Prepare lists based on tab and filter
    List<StyleItem> items = [];
    if (_selectedTab == 0) {
      // History (Auto + saved)
      items = _styleService.history;
    } else if (_selectedTab == 1) {
      // Preset Library
      items = _styleService.presets;
      if (_selectedCategory != 'Tümü') {
        items = items.where((p) => p.category == _selectedCategory).toList();
      }
    } else {
      // Favorites
      items = _styleService.history.where((h) => h.isFavorite).toList();
    }

    if (query.isNotEmpty) {
      items = items.where((item) {
        return item.title.toLowerCase().contains(query) ||
            item.prompt.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query);
      }).toList();
    }

    final categories = ['Tümü', 'Rock', 'Pop', 'Elektronik', 'Geleneksel & Rock', 'Akustik', 'Sinematik', 'Hip-Hop', 'R&B & Caz'];

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 520,
          maxHeight: 640,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Search styles + Close Button (Matching Suno layout in screenshot)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF22222E) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search styles (Müzik tarzlarında ara...)',
                          hintStyle: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          suffixIcon: query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Segmented Tabs: Geçmiş (History) | Kütüphane (Presets) | Favoriler
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF22222E) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildTabButton(
                      index: 0,
                      label: 'Geçmiş (${_styleService.history.length})',
                      icon: Icons.history_rounded,
                      isDark: isDark,
                    ),
                    _buildTabButton(
                      index: 1,
                      label: 'Kütüphane (${_styleService.presets.length})',
                      icon: Icons.library_music_rounded,
                      isDark: isDark,
                    ),
                    _buildTabButton(
                      index: 2,
                      label: 'Favoriler',
                      icon: Icons.star_rounded,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              // Category Filter Pills (Only visible in Library tab)
              if (_selectedTab == 1) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 30,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      final isCatSelected = _selectedCategory == cat;
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCatSelected
                                ? AppColors.primary
                                : (isDark ? const Color(0xFF22222E) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isCatSelected ? FontWeight.bold : FontWeight.normal,
                              color: isCatSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Info Subtitle for Auto-History
              if (_selectedTab == 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Şarkı ürettikçe tarzlar otomatik olarak buraya eklenir.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Scrollable Style Items List
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedTab == 0
                                  ? Icons.history_rounded
                                  : (_selectedTab == 1 ? Icons.music_note_rounded : Icons.star_border_rounded),
                              size: 40,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _selectedTab == 0
                                  ? 'Henüz tarz geçmişi yok'
                                  : (_selectedTab == 1 ? 'Eşleşen tarz bulunamadı' : 'Henüz favori tarz eklenmedi'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedTab == 0
                                  ? 'Stüdyoda şarkı ürettiğinizde tarzlar kaydet demeye gerek kalmadan otomatik birikir.'
                                  : 'Farklı bir arama terimi deneyin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildStyleRow(
                            item: item,
                            isDark: isDark,
                            cardBg: cardBg,
                            borderColor: borderColor,
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),

              // Bottom Bar: Save Current Style (if user has active text)
              if (widget.currentStyleText.trim().isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mevcut: "${widget.currentStyleText.length > 25 ? '${widget.currentStyleText.substring(0, 24)}...' : widget.currentStyleText}"',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.bookmark_add_rounded, size: 14, color: AppColors.primary),
                        label: const Text(
                          'Sabitle & Kaydet',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        onPressed: _showSaveCurrentDialog,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? const Color(0xFF323242) : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppColors.primary : (isDark ? Colors.white54 : Colors.black54),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                        : (isDark ? Colors.white54 : Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyleRow({
    required StyleItem item,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onStyleSelected(item.prompt);
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Music Note Avatar (Matching Suno circular icon)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF282836) : const Color(0xFFE2E8F0),
                ),
                child: Icon(
                  item.isPreset ? Icons.library_music_rounded : Icons.music_note_rounded,
                  size: 16,
                  color: item.isFavorite ? AppColors.primary : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
              const SizedBox(width: 12),

              // Title, Prompt Snippet & Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        if (item.category.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2C3C) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.category,
                              style: TextStyle(
                                fontSize: 9,
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (!item.isPreset)
                          Text(
                            item.timeAgo,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.3,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Actions: Favorite + Trash (for History items)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!item.isPreset) ...[
                    IconButton(
                      icon: Icon(
                        item.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 17,
                        color: item.isFavorite ? AppColors.primary : (isDark ? Colors.white30 : Colors.black26),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      onPressed: () => _styleService.toggleFavorite(item.id),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      onPressed: () => _styleService.deleteStyle(item.id),
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      onPressed: () {
                        widget.onStyleSelected(item.prompt);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
