import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/api_error.dart';

class DevelopmentPage extends StatefulWidget {
  const DevelopmentPage({super.key});

  @override
  State<DevelopmentPage> createState() => _DevelopmentPageState();
}

class _DevelopmentPageState extends State<DevelopmentPage> {
  final ApiService _api = ApiService();
  List<dynamic> _children = [];
  int? _selectedChildId;
  Map<String, dynamic>? _developmentData;
  List<dynamic> _categories = [];
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
        await _loadDevelopment(_selectedChildId!);
      } else {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Gagal memuat data.'; _isLoading = false; });
    }
  }

  Future<void> _loadDevelopment(int childId) async {
    try {
      final data = await _api.getDevelopment(childId);
      final cats = await _api.getDevelopmentCategories();
      setState(() {
        _developmentData = data;
        _categories = cats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = 'Gagal memuat data perkembangan.'; _isLoading = false; });
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    );
  }

  Future<void> _deleteAssessment(dynamic assessment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Penilaian'),
        content: const Text('Hapus penilaian ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final response = await _api.deleteAssessment(assessment['id']);
      if (response['success'] == true) {
        _showToast('Penilaian berhasil dihapus.');
        if (_selectedChildId != null) _loadDevelopment(_selectedChildId!);
      } else {
        _showToast(response['message'] ?? 'Gagal menghapus.', isError: true);
      }
    } catch (e) {
      _showToast('Gagal menghapus penilaian.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Perkembangan Anak')),
      floatingActionButton: (isAdmin && _selectedChildId != null && _categories.isNotEmpty) ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context,
            MaterialPageRoute(builder: (_) => AssessmentFormPage(
              childId: _selectedChildId!, categories: _categories)));
          if (result == true && _selectedChildId != null) _loadDevelopment(_selectedChildId!);
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
                  ? AppWidgets.emptyState(icon: Icons.trending_up, title: 'Belum ada data anak')
                  : RefreshIndicator(
                      onRefresh: () async {
                        if (_selectedChildId != null) await _loadDevelopment(_selectedChildId!);
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
                                  items: _children.map<DropdownMenuItem<int>>((c) =>
                                    DropdownMenuItem(value: c['id'], child: Text(c['name'] ?? '-'))
                                  ).toList(),
                                  onChanged: (id) {
                                    if (id != null) {
                                      setState(() { _selectedChildId = id; _isLoading = true; });
                                      _loadDevelopment(id);
                                    }
                                  },
                                ),
                              ),

                            if (_developmentData?['child'] != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySubtle,
                                  borderRadius: AppRadius.lgAll,
                                  border: Border.all(color: AppColors.primaryLighter),
                                ),
                                child: Text('Anak: ${_developmentData!['child']['name']}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryDark, fontSize: 14)),
                              ),

                            Text('Kategori Perkembangan', style: AppTypography.h3.copyWith(color: ThemeHelper.text(context))),
                            const SizedBox(height: 14),

                            // Use enriched categories from development endpoint (has assessment data)
                            // Fall back to raw categories if development data not loaded yet
                            Builder(
                              builder: (context) {
                                final enrichedCategories = _developmentData?['categories'];
                                final displayCategories = (enrichedCategories is List && enrichedCategories.isNotEmpty)
                                    ? enrichedCategories
                                    : _categories;
                                if (displayCategories.isEmpty) {
                                  return AppWidgets.emptyState(icon: Icons.trending_up, title: 'Belum ada kategori');
                                }
                                return Column(
                                  children: displayCategories.map<Widget>((cat) => _buildCategoryCard(cat, isAdmin)).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildCategoryCard(dynamic category, bool isAdmin) {
    final avgProgress = (category['average_progress'] ?? 0).toDouble();
    final latest = category['latest_assessment'];
    final total = category['total_assessments'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
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
              Text(category['icon'] ?? '📊', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category['name'] ?? '-', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
                    const SizedBox(height: 2),
                    Text('$total penilaian', style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context))),
                  ],
                ),
              ),
              if (latest != null)
                AppWidgets.statusBadge(latest['progress_label'] ?? '-', _getProgressColor(avgProgress)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: avgProgress / 100,
                    backgroundColor: ThemeHelper.border(context),
                    valueColor: AlwaysStoppedAnimation(_getProgressColor(avgProgress)),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text('${avgProgress.toStringAsFixed(0)}%',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: ThemeHelper.text(context))),
            ],
          ),

          if (category['recent_assessments'] != null && (category['recent_assessments'] as List).isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(color: ThemeHelper.border(context)),
            const SizedBox(height: 10),
            ...List.generate((category['recent_assessments'] as List).length, (i) {
              final a = (category['recent_assessments'] as List)[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: ThemeHelper.bgAlt(context), borderRadius: AppRadius.smAll),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['indicator'] ?? '-',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: ThemeHelper.text(context))),
                          const SizedBox(height: 2),
                          Text(a['observation_date'] ?? '', style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context))),
                        ],
                      ),
                    ),
                    Text(a['progress_label'] ?? '',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: _getProgressColor(a['progress_percentage'] ?? 0))),
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                        onPressed: () => _deleteAssessment(a),
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 75) return AppColors.success;
    if (percentage >= 50) return AppColors.warning;
    if (percentage >= 25) return Colors.orange;
    return AppColors.error;
  }
}

// ==================== Assessment Form (Admin) ====================
class AssessmentFormPage extends StatefulWidget {
  final int childId;
  final List<dynamic> categories;
  const AssessmentFormPage({super.key, required this.childId, required this.categories});

  @override
  State<AssessmentFormPage> createState() => _AssessmentFormPageState();
}

class _AssessmentFormPageState extends State<AssessmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _indicatorController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  int? _selectedCategoryId;
  // Backend enum: belum, mulai, berkembang, baik, sangat_baik
  String _progress = 'baik';
  bool _isSubmitting = false;
  String? _error;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _dateController.text = ApiService.today(); // Default = today
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _error = null; });

    try {
      final response = await _api.storeAssessment(
        childId: widget.childId,
        developmentCategoryId: _selectedCategoryId!,
        indicator: _indicatorController.text.trim(),
        progress: _progress,
        observationDate: _dateController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Penilaian berhasil ditambahkan.'),
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
      setState(() { _error = ApiErrorHandler.getMessage(e); _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Penilaian Perkembangan')),
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

              // Kategori (backend field: development_category_id)
              DropdownButtonFormField<int>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Kategori *'),
                items: widget.categories.map<DropdownMenuItem<int>>((c) =>
                  DropdownMenuItem(value: c['id'], child: Text('${c['icon'] ?? ''} ${c['name'] ?? ''}'))
                ).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                validator: (v) => v == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 16),

              // Indikator (REQUIRED by backend)
              TextFormField(
                controller: _indicatorController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Indikator *'),
                validator: (v) => v == null || v.isEmpty ? 'Indikator tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              // Tanggal observasi (backend: observation_date, REQUIRED)
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Tanggal Observasi *', hintText: 'YYYY-MM-DD'),
                keyboardType: TextInputType.datetime,
                validator: (v) => v == null || v.isEmpty ? 'Tanggal tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              // Progress (backend enum: belum, mulai, berkembang, baik, sangat_baik)
              Text('Progres', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  _buildProgressChip('belum', 'Belum'),
                  _buildProgressChip('mulai', 'Mulai'),
                  _buildProgressChip('berkembang', 'Berkembang'),
                  _buildProgressChip('baik', 'Baik'),
                  _buildProgressChip('sangat_baik', 'Sangat Baik'),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Catatan', alignLabelWithHint: true),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSave,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan Penilaian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressChip(String value, String label) {
    final selected = _progress == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : ThemeHelper.textSecondary(context))),
      selected: selected,
      onSelected: (_) => setState(() => _progress = value),
      selectedColor: AppColors.primary,
      backgroundColor: ThemeHelper.surface(context),
      side: BorderSide(color: ThemeHelper.border(context)),
    );
  }
}
