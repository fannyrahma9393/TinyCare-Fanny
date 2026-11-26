import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/cached_resource.dart';
import '../services/parent_data_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/child_photo.dart';
import '../widgets/offline_banner.dart';
import '../l10n/app_strings.dart';

/// Daily Story detail for a child — matches web DailyStoryDetail.jsx.
/// Shows child header, date picker, story cards with mood/stats,
/// and admin create button.
class DailyStoryDetailPage extends StatefulWidget {
  const DailyStoryDetailPage({
    super.key,
    required this.childId,
    required this.date,
    this.child,
  });

  final int childId;
  final String date;
  final Map<String, dynamic>? child;

  @override
  State<DailyStoryDetailPage> createState() => _DailyStoryDetailPageState();
}

class _DailyStoryDetailPageState extends State<DailyStoryDetailPage>
    with ResourceBinding {
  final ParentDataRepository _repo = ParentDataRepository();

  /// Cache-first daily stories for this child.
  late final CachedResource<List<dynamic>> _res;
  List<dynamic> get _stories => _res.data ?? const [];

  Map<String, dynamic>? _child;
  late String _selectedDate;

  // A getter (not a `static final` field) so the labels follow the active
  // language instead of being frozen on first access.
  static Map<String, (String, String, Color, Color)> get _moodConfig => {
    'bahagia': (tr('Bahagia'), '😊', Color(0xFF16A34A), Color(0xFFF0FDF4)),
    'biasa': (tr('Biasa'), '😐', Color(0xFF6B7280), Color(0xFFF9FAFB)),
    'sedih': (tr('Sedih'), '😢', Color(0xFF3B82F6), Color(0xFFEFF6FF)),
    'sakit': (tr('Sakit'), '🤒', Color(0xFFDC2626), Color(0xFFFEF2F2)),
    'rewel': (tr('Rewel'), '😫', Color(0xFFF59E0B), Color(0xFFFFFBEB)),
  };

  @override
  void initState() {
    super.initState();
    _res = CachedResource<List<dynamic>>(onChanged: onResourceChanged);
    _selectedDate = widget.date;
    _child = widget.child;
    _loadData();
  }

  Future<void> _loadChild() async {
    try {
      final child = await _repo.loadChildDetailOnce(widget.childId);
      if (child == null) return;
      if (!mounted) return;
      setState(() => _child = child);
    } catch (_) {}
  }

  Future<void> _loadStories() => _repo.loadDailyStories(widget.childId, _res);

  Future<void> _loadData() async {
    if (_child == null) _loadChild();
    _loadStories();
  }

  void _onDateChanged(String date) {
    setState(() => _selectedDate = date);
    _loadStories();
  }

  @override
  Widget build(BuildContext context) {
    final childName = _child?['name'] ?? tr('Memuat...');
    final textColor = ThemeHelper.text(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ChildPhoto(child: _child, width: 32, radius: 8),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                childName,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (_child != null)
            IconButton(
              icon: const Icon(Icons.add_outlined),
              tooltip: tr('Buat Story'),
              onPressed: _showCreateStoryModal,
            ),
        ],
      ),
      body: Column(
        children: [
          // Date picker row (matching web)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: ThemeHelper.surface(context),
              border: Border(
                bottom: BorderSide(color: ThemeHelper.border(context)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16, color: ThemeHelper.textMuted(context)),
                const SizedBox(width: 8),
                Text(
                  tr('Tanggal: '),
                  style: TextStyle(
                      fontSize: 13, color: ThemeHelper.textMuted(context)),
                ),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ThemeHelper.bgAlt(context),
                      borderRadius: AppRadius.smAll,
                      border: Border.all(color: ThemeHelper.border(context)),
                    ),
                    child: Text(
                      _formatDateDisplay(_selectedDate),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          OfflineBanner(resource: _res, onRetry: _loadStories),

          // Content
          Expanded(
            child: _res.isLoading
                ? AppWidgets.loadingIndicator()
                : _res.error != null
                    ? AppWidgets.errorState(
                        message: tr(_res.error!),
                        onRetry: _loadStories,
                      )
                    : _stories.isEmpty
                        ? AppWidgets.emptyState(
                            icon: Icons.auto_stories,
                            title: tr('Belum ada Daily Story'),
                            subtitle: tr('Tidak ada cerita untuk tanggal {{date}}.',
                                {'date': _formatDateDisplay(_selectedDate)}),
                            action: _child != null
                                ? GestureDetector(
                                    onTap: _showCreateStoryModal,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: AppRadius.smAll,
                                      ),
                                      child: Text(
                                        tr('Buat Sekarang'),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  )
                                : null,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadStories,
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _stories.length,
                              itemBuilder: (context, index) =>
                                  _buildStoryCard(_stories[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(dynamic story) {
    final moodKey = story['mood'] ?? 'biasa';
    final (moodLabel, moodIcon, moodColor, moodBg) =
        _moodConfig[moodKey] ?? _moodConfig['biasa']!;
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ThemeHelper.surface(context),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: ThemeHelper.border(context)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: child photo + name + mood badge (matching web)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: ThemeHelper.border(context), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                // Mood icon in colored box
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: moodBg,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Center(
                    child: Text(moodIcon, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _child?['name'] ?? '-',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDateFull(story['date'] ?? _selectedDate),
                        style: TextStyle(
                          fontSize: 11,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: moodBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    moodLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: moodColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content: summary + stats grid (matching web)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary
                if (story['summary'] != null &&
                    story['summary'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      story['summary'],
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: ThemeHelper.textSecondary(context),
                      ),
                    ),
                  ),

                // Stats grid: Rating Makan | Jam Tidur | Mood (matching web 3-col)
                Row(
                  children: [
                    _buildStatCell(
                      tr('Rating Makan'),
                      '${story['meal_rating'] ?? '-'}',
                      AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCell(
                      tr('Jam Tidur'),
                      story['sleep_hours'] != null
                          ? '${story['sleep_hours']}j'
                          : '-',
                      AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCell(
                      tr('Mood'),
                      moodIcon,
                      moodColor,
                    ),
                  ],
                ),

                // Meal notes
                if (story['meal_notes'] != null &&
                    story['meal_notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ThemeHelper.warningBg(context),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Text(
                      story['meal_notes'],
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeHelper.textSecondary(context),
                      ),
                    ),
                  ),
                ],

                // Sleep notes
                if (story['sleep_notes'] != null &&
                    story['sleep_notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ThemeHelper.infoBg(context),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Text(
                      story['sleep_notes'],
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeHelper.textSecondary(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell(String label, String value, Color color) {
    final bgColor = ThemeHelper.bgAlt(context);
    final mutedColor = ThemeHelper.textMuted(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.smAll,
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(fontSize: 10, color: mutedColor),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_selectedDate) ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      final dateStr =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _onDateChanged(dateStr);
    }
  }

  void _showCreateStoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StoryCreateSheet(
        childId: widget.childId,
        date: _selectedDate,
        child: _child,
        onCreated: () {
          _loadStories();
        },
      ),
    );
  }

  String _formatDateDisplay(String date) {
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        final months = [
          tr('Januari'), tr('Februari'), tr('Maret'), tr('April'), tr('Mei'), tr('Juni'),
          tr('Juli'), tr('Agustus'), tr('September'), tr('Oktober'), tr('November'), tr('Desember'),
        ];
        final d = int.tryParse(parts[2]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[0]);
        if (d != null && m != null && y != null && m >= 1 && m <= 12) {
          return '$d ${months[m - 1]} $y';
        }
      }
    } catch (_) {}
    return date;
  }

  String _formatDateFull(String date) {
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        final months = [
          tr('Januari'), tr('Februari'), tr('Maret'), tr('April'), tr('Mei'), tr('Juni'),
          tr('Juli'), tr('Agustus'), tr('September'), tr('Oktober'), tr('November'), tr('Desember'),
        ];
        final d = int.tryParse(parts[2]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[0]);
        if (d != null && m != null && y != null && m >= 1 && m <= 12) {
          return '${_weekday(picked: DateTime(y, m, d))}, $d ${months[m - 1]} $y';
        }
      }
    } catch (_) {}
    return date;
  }

  String _weekday({required DateTime picked}) {
    final days = [
      tr('Senin'), tr('Selasa'), tr('Rabu'), tr('Kamis'), tr('Jumat'), tr('Sabtu'), tr('Minggu')
    ];
    return days[(picked.weekday - 1) % 7];
  }
}

/// Bottom sheet for creating a story (admin only) matching web modal
class _StoryCreateSheet extends StatefulWidget {
  final int childId;
  final String date;
  final Map<String, dynamic>? child;
  final VoidCallback onCreated;

  const _StoryCreateSheet({
    required this.childId,
    required this.date,
    this.child,
    required this.onCreated,
  });

  @override
  State<_StoryCreateSheet> createState() => _StoryCreateSheetState();
}

class _StoryCreateSheetState extends State<_StoryCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _summaryController = TextEditingController();
  final _mealRatingController = TextEditingController();
  final _mealNotesController = TextEditingController();
  final _sleepHoursController = TextEditingController();
  final _sleepNotesController = TextEditingController();
  final _adminNotesController = TextEditingController();
  String _mood = 'biasa';
  bool _isSubmitting = false;
  String? _error;
  final ApiService _api = ApiService();

  // A getter (not a `static final` field) so the labels follow the active
  // language instead of being frozen on first access.
  static Map<String, (String, String)> get _moodConfig => {
    'bahagia': (tr('Bahagia'), '😊'),
    'biasa': (tr('Biasa'), '😐'),
    'sedih': (tr('Sedih'), '😢'),
    'sakit': (tr('Sakit'), '🤒'),
    'rewel': (tr('Rewel'), '😫'),
  };

  @override
  void initState() {
    super.initState();
    _dateController.text = widget.date;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _summaryController.dispose();
    _mealRatingController.dispose();
    _mealNotesController.dispose();
    _sleepHoursController.dispose();
    _sleepNotesController.dispose();
    _adminNotesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final response = await _api.storeDailyStory(
        childId: widget.childId,
        date: _dateController.text.trim().isNotEmpty
            ? _dateController.text.trim()
            : null,
        summary: _summaryController.text.trim().isNotEmpty
            ? _summaryController.text.trim()
            : null,
        mood: _mood,
        mealRating: _mealRatingController.text.trim().isNotEmpty
            ? _mealRatingController.text.trim()
            : null,
        mealNotes: _mealNotesController.text.trim().isNotEmpty
            ? _mealNotesController.text.trim()
            : null,
        sleepHours: _sleepHoursController.text.trim().isNotEmpty
            ? _sleepHoursController.text.trim()
            : null,
        sleepNotes: _sleepNotesController.text.trim().isNotEmpty
            ? _sleepNotesController.text.trim()
            : null,
        adminNotes: _adminNotesController.text.trim().isNotEmpty
            ? _adminNotesController.text.trim()
            : null,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('Cerita berhasil dibuat.')),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
          );
          Navigator.pop(context);
          widget.onCreated();
        }
      } else {
        setState(() {
          _error = response['message'] ?? tr('Gagal menyimpan.');
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = tr('Gagal menyimpan. Silakan coba lagi.');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.text(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: ThemeHelper.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ThemeHelper.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  tr('Buat Daily Story'),
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      AppWidgets.errorAlert(_error!),
                      const SizedBox(height: 16),
                    ],

                    // Child info
                    if (widget.child != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ThemeHelper.bgAlt(context),
                          borderRadius: AppRadius.mdAll,
                        ),
                        child: Row(
                          children: [
                            ChildPhoto(
                                child: widget.child, width: 36, radius: 8),
                            const SizedBox(width: 10),
                            Text(
                              widget.child!['name'] ?? '',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Date
                    TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                          labelText: tr('Tanggal (YYYY-MM-DD)')),
                      keyboardType: TextInputType.datetime,
                    ),
                    const SizedBox(height: 16),

                    // Summary
                    TextFormField(
                      controller: _summaryController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: tr('Ringkasan Hari Ini'),
                        hintText: tr('Ceritakan aktivitas anak hari ini...'),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mood selector
                    Text(tr('Mood Anak'),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _moodConfig.entries.map((e) {
                        final selected = _mood == e.key;
                        return ChoiceChip(
                          label: Text(
                            '${e.value.$2} ${e.value.$1}',
                            style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? Colors.white
                                  : ThemeHelper.textSecondary(context),
                            ),
                          ),
                          selected: selected,
                          onSelected: (_) => setState(() => _mood = e.key),
                          selectedColor: AppColors.primary,
                          backgroundColor: ThemeHelper.surface(context),
                          side: BorderSide(
                              color: ThemeHelper.border(context)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Meal rating & sleep hours
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _mealRatingController,
                            decoration: InputDecoration(
                                labelText: tr('Rating Makan (1-5)')),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _sleepHoursController,
                            decoration:
                                InputDecoration(labelText: tr('Jam Tidur Siang')),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Meal notes
                    TextFormField(
                      controller: _mealNotesController,
                      decoration:
                          InputDecoration(labelText: tr('Catatan Makan')),
                    ),
                    const SizedBox(height: 16),

                    // Sleep notes
                    TextFormField(
                      controller: _sleepNotesController,
                      decoration:
                          InputDecoration(labelText: tr('Catatan Tidur')),
                    ),
                    const SizedBox(height: 16),

                    // Admin notes
                    TextFormField(
                      controller: _adminNotesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: tr('Catatan Admin (internal)'),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(tr('Batal')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleSave,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(tr('Simpan')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
