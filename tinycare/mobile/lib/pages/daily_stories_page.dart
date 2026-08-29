import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';

class DailyStoriesPage extends StatefulWidget {
  const DailyStoriesPage({super.key});

  @override
  State<DailyStoriesPage> createState() => _DailyStoriesPageState();
}

class _DailyStoriesPageState extends State<DailyStoriesPage> {
  final ApiService _api = ApiService();
  List<dynamic> _children = [];
  List<dynamic> _stories = [];
  int? _selectedChildId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final children = await _api.getChildren();
      _children = children;
      if (children.isNotEmpty) {
        _selectedChildId = children[0]['id'];
        await _loadStories(_selectedChildId!);
      } else {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Gagal memuat data.'; _isLoading = false; });
    }
  }

  Future<void> _loadStories(int childId) async {
    try {
      final stories = await _api.getDailyStories(childId);
      setState(() { _stories = stories; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Gagal memuat cerita.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Hari Ini di Daycare')),
      floatingActionButton: (isAdmin && _children.isNotEmpty) ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context,
            MaterialPageRoute(builder: (_) => _StoryFormPage(children: _children, selectedChildId: _selectedChildId)));
          if (result == true && _selectedChildId != null) _loadStories(_selectedChildId!);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ) : null,
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(message: _error!, onRetry: () {
                  setState(() { _isLoading = true; _error = null; });
                  _loadData();
                })
              : _children.isEmpty
                  ? AppWidgets.emptyState(icon: Icons.auto_stories, title: 'Belum ada data anak')
                  : RefreshIndicator(
                      onRefresh: () async {
                        if (_selectedChildId != null) await _loadStories(_selectedChildId!);
                      },
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_children.length > 1)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: ThemeHelper.surface(context),
                                  borderRadius: AppRadius.mdAll,
                                  border: Border.all(color: ThemeHelper.border(context)),
                                ),
                                child: DropdownButton<int>(
                                  value: _selectedChildId,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  hint: const Text('Pilih Anak'),
                                  items: _children.map<DropdownMenuItem<int>>((c) =>
                                    DropdownMenuItem(value: c['id'], child: Text(c['name'] ?? '-'))
                                  ).toList(),
                                  onChanged: (id) {
                                    if (id != null) {
                                      setState(() { _selectedChildId = id; _isLoading = true; _error = null; });
                                      _loadStories(id);
                                    }
                                  },
                                ),
                              ),

                            if (_stories.isEmpty)
                              AppWidgets.emptyState(
                                icon: Icons.auto_stories,
                                title: 'Belum ada cerita hari ini',
                                subtitle: isAdmin ? 'Tekan tombol + untuk menambah cerita.' : null,
                              )
                            else
                              ..._stories.map((story) => _buildStoryCard(story)),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildStoryCard(dynamic story) {
    final moodIcons = {
      'bahagia': '😊', 'biasa': '😐', 'sedih': '😢', 'sakit': '🤒', 'rewel': '😫',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeHelper.surface(context),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: ThemeHelper.border(context)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.primaryLighter, borderRadius: AppRadius.smAll),
                child: Center(
                  child: Text(
                    (story['child']?['name'] ?? '?')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(story['child']?['name'] ?? '-',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: ThemeHelper.text(context))),
                    Text(story['date'] ?? '-', style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context))),
                  ],
                ),
              ),
              Text(moodIcons[story['mood']] ?? '😐', style: const TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 16),
          if (story['summary'] != null) ...[
            Text(story['summary'],
                style: TextStyle(fontSize: 14, height: 1.6, color: ThemeHelper.text(context))),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              _buildInfoChip('Makan', '${story['meal_rate'] ?? story['meal_rating'] ?? '-'}', Icons.restaurant),
              const SizedBox(width: 8),
              _buildInfoChip('Tidur', '${story['sleep_hours'] ?? '-'} jam', Icons.bedtime),
            ],
          ),
          if (story['meal_notes'] != null) ...[
            const SizedBox(height: 10),
            Text('🍽️ ${story['meal_notes']}', style: TextStyle(color: ThemeHelper.textSecondary(context), fontSize: 12)),
          ],
          if (story['sleep_notes'] != null) ...[
            const SizedBox(height: 4),
            Text('😴 ${story['sleep_notes']}', style: TextStyle(color: ThemeHelper.textSecondary(context), fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: ThemeHelper.bgAlt(context), borderRadius: AppRadius.smAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ThemeHelper.textMuted(context)),
          const SizedBox(width: 6),
          Text('$label: $value',
              style: TextStyle(fontSize: 12, color: ThemeHelper.textSecondary(context), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ==================== Story Form (Admin) ====================
class _StoryFormPage extends StatefulWidget {
  final List<dynamic> children;
  final int? selectedChildId;
  const _StoryFormPage({required this.children, this.selectedChildId});

  @override
  State<_StoryFormPage> createState() => _StoryFormPageState();
}

class _StoryFormPageState extends State<_StoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _summaryController = TextEditingController();
  final _mealRatingController = TextEditingController();
  final _mealNotesController = TextEditingController();
  final _sleepHoursController = TextEditingController();
  final _sleepNotesController = TextEditingController();
  String _mood = 'biasa';
  int? _selectedChildId;
  bool _isSubmitting = false;
  String? _error;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.selectedChildId;
    _dateController.text = ApiService.today(); // Default = today
  }

  @override
  void dispose() {
    _dateController.dispose();
    _summaryController.dispose();
    _mealRatingController.dispose();
    _mealNotesController.dispose();
    _sleepHoursController.dispose();
    _sleepNotesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedChildId == null) {
      setState(() { _error = 'Pilih anak terlebih dahulu.'; });
      return;
    }

    setState(() { _isSubmitting = true; _error = null; });

    try {
      final response = await _api.storeDailyStory(
        childId: _selectedChildId!,
        date: _dateController.text.trim().isNotEmpty ? _dateController.text.trim() : null,
        summary: _summaryController.text.trim().isNotEmpty ? _summaryController.text.trim() : null,
        mood: _mood,
        mealRating: _mealRatingController.text.trim().isNotEmpty ? _mealRatingController.text.trim() : null,
        mealNotes: _mealNotesController.text.trim().isNotEmpty ? _mealNotesController.text.trim() : null,
        sleepHours: _sleepHoursController.text.trim().isNotEmpty ? _sleepHoursController.text.trim() : null,
        sleepNotes: _sleepNotesController.text.trim().isNotEmpty ? _sleepNotesController.text.trim() : null,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cerita hari ini ditambahkan.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() { _error = response['message'] ?? 'Gagal menyimpan.'; _isSubmitting = false; });
      }
    } catch (e) {
      setState(() { _error = 'Gagal menyimpan. Silakan coba lagi.'; _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Cerita Hari Ini')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                AppWidgets.errorAlert(_error!),
                const SizedBox(height: 16),
              ],

              // Child selector
              DropdownButtonFormField<int>(
                initialValue: _selectedChildId,
                decoration: const InputDecoration(labelText: 'Anak *'),
                items: widget.children.map<DropdownMenuItem<int>>((c) =>
                  DropdownMenuItem(value: c['id'], child: Text(c['name'] ?? '-'))
                ).toList(),
                onChanged: (v) => setState(() => _selectedChildId = v),
                validator: (v) => v == null ? 'Pilih anak' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Tanggal', hintText: 'YYYY-MM-DD (default: hari ini)'),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _summaryController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Ringkasan Kegiatan', alignLabelWithHint: true),
              ),
              const SizedBox(height: 16),

              // Mood selector
              Text('Mood', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  _buildMoodChip('bahagia', '😊 Bahagia'),
                  _buildMoodChip('biasa', '😐 Biasa'),
                  _buildMoodChip('sedih', '😢 Sedih'),
                  _buildMoodChip('sakit', '🤒 Sakit'),
                  _buildMoodChip('rewel', '😫 Rewel'),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _mealRatingController,
                decoration: const InputDecoration(labelText: 'Rating Makan (1-5)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _mealNotesController,
                decoration: const InputDecoration(labelText: 'Catatan Makan'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _sleepHoursController,
                decoration: const InputDecoration(labelText: 'Jam Tidur'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _sleepNotesController,
                decoration: const InputDecoration(labelText: 'Catatan Tidur'),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSave,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan Cerita', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodChip(String value, String label) {
    final selected = _mood == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : ThemeHelper.textSecondary(context))),
      selected: selected,
      onSelected: (_) => setState(() => _mood = value),
      selectedColor: AppColors.primary,
      backgroundColor: ThemeHelper.surface(context),
      side: BorderSide(color: ThemeHelper.border(context)),
    );
  }
}
