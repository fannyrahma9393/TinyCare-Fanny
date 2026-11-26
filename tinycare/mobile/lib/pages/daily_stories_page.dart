import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/cached_resource.dart';
import '../services/parent_data_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/child_photo.dart';
import '../widgets/offline_banner.dart';
import 'daily_story_detail_page.dart';
import '../l10n/app_strings.dart';

/// Daily Stories — first screen shows child card grid (matching web
/// DailyStories.jsx). Clicking a child navigates to the story detail page.
class DailyStoriesPage extends StatefulWidget {
  const DailyStoriesPage({super.key});

  @override
  State<DailyStoriesPage> createState() => _DailyStoriesPageState();
}

class _DailyStoriesPageState extends State<DailyStoriesPage>
    with ResourceBinding {
  final ParentDataRepository _repo = ParentDataRepository();

  /// Cache-first children list used to pick whose story to read.
  late final CachedResource<List<dynamic>> _res;
  List<dynamic> get _children => _res.data ?? const [];

  @override
  void initState() {
    super.initState();
    _res = CachedResource<List<dynamic>>(onChanged: onResourceChanged);
    _loadChildren();
  }

  Future<void> _loadChildren() => _repo.loadChildren(_res);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? tr('Daily Stories') : tr('Hari Ini di Daycare')),
        actions: [
          if (isAdmin && _children.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add_outlined),
              tooltip: tr('Buat Story'),
              onPressed: () => _showCreateStoryDialog(),
            ),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(resource: _res, onRetry: _loadChildren),
          Expanded(
            child: _res.isLoading
                ? AppWidgets.loadingIndicator()
                : _res.error != null
                    ? AppWidgets.errorState(
                        message: tr(_res.error!),
                        onRetry: _loadChildren,
                      )
                    : _children.isEmpty
                        ? AppWidgets.emptyState(
                            icon: Icons.auto_stories,
                            title: tr('Belum ada data anak'),
                            subtitle:
                                tr('Tambahkan data anak terlebih dahulu untuk melihat Daily Stories.'),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadChildren,
                            color: AppColors.primary,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                          // Page header subtitle
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              tr('Pilih anak untuk melihat cerita hariannya'),
                              style: TextStyle(
                                fontSize: 13,
                                color: mutedColor,
                              ),
                            ),
                          ),

                          // Child card grid (matching web)
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.77,
                              ),
                              itemCount: _children.length,
                              itemBuilder: (context, index) {
                                final child = _children[index];
                                final isActive =
                                    child['status'] == 'active';
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DailyStoryDetailPage(
                                          childId: child['id'],
                                          date: ApiService.today(),
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 18),
                                    decoration: BoxDecoration(
                                      color: ThemeHelper.surface(context),
                                      borderRadius: AppRadius.lgAll,
                                      border: Border.all(
                                          color:
                                              ThemeHelper.border(context)),
                                      boxShadow: AppColors.cardShadow,
                                    ),
                                    child: Column(
                                      children: [
                                        Center(
                                          child: ChildPhoto(
                                            child: child,
                                            width: 88,
                                            radius: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          child['name'] ?? '-',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? ThemeHelper.successBg(
                                                    context)
                                                : ThemeHelper.bgAlt(
                                                    context),
                                            borderRadius:
                                                BorderRadius.circular(99),
                                          ),
                                          child: Text(
                                            isActive ? tr('Aktif') : tr('Nonaktif'),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isActive
                                                  ? AppColors.success
                                                  : mutedColor,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              tr('Lihat Cerita'),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.chevron_right,
                                              size: 14,
                                              color: AppColors.primary,
                                            ),
                                          ],
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
                    ),
          ),
        ],
      ),
    );
  }

  void _showCreateStoryDialog() {
    // Navigate to the story creation form with child list
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AdminStoryCreatePage(children: _children),
      ),
    ).then((result) {
      // Refresh when coming back (in case a story was created)
    });
  }
}

/// Admin-only page to create a daily story — simplified version matching web
/// DailyStoryDetail.jsx create modal.
class _AdminStoryCreatePage extends StatefulWidget {
  final List<dynamic> children;
  const _AdminStoryCreatePage({required this.children});

  @override
  State<_AdminStoryCreatePage> createState() => _AdminStoryCreatePageState();
}

class _AdminStoryCreatePageState extends State<_AdminStoryCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _summaryController = TextEditingController();
  final _mealRatingController = TextEditingController();
  final _mealNotesController = TextEditingController();
  final _sleepHoursController = TextEditingController();
  final _sleepNotesController = TextEditingController();
  final _adminNotesController = TextEditingController();
  String _mood = 'biasa';
  int? _selectedChildId;
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
    _dateController.text = ApiService.today();
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
    if (_selectedChildId == null) {
      setState(() => _error = tr('Pilih anak terlebih dahulu.'));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final response = await _api.storeDailyStory(
        childId: _selectedChildId!,
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
              content: Text(tr('Cerita hari ini ditambahkan.')),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdAll),
            ),
          );
          Navigator.pop(context, true);
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

    return Scaffold(
      appBar:
          AppBar(title: Text(tr('Buat Daily Story'))),
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
                decoration:
                    InputDecoration(labelText: tr('Anak *')),
                items: widget.children
                    .map<DropdownMenuItem<int>>((c) =>
                        DropdownMenuItem(
                            value: c['id'],
                            child: Text(c['name'] ?? '-')))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedChildId = v),
                validator: (v) =>
                    v == null ? tr('Pilih anak') : null,
              ),
              const SizedBox(height: 16),

              // Date
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: tr('Tanggal'),
                  hintText: tr('YYYY-MM-DD (default: hari ini)'),
                ),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 16),

              // Summary
              TextFormField(
                controller: _summaryController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: tr('Ringkasan Kegiatan'),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Mood selector
              Text(
                tr('Mood'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
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
                    onSelected: (_) =>
                        setState(() => _mood = e.key),
                    selectedColor: AppColors.primary,
                    backgroundColor:
                        ThemeHelper.surface(context),
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
                          InputDecoration(labelText: tr('Jam Tidur')),
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
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: tr('Catatan Admin (internal)'),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      _isSubmitting ? null : _handleSave,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          tr('Simpan Cerita'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
