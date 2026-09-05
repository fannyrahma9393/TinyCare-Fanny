import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/api_error.dart';
import '../widgets/child_photo.dart';
import 'development_detail_page.dart';

class DevelopmentPage extends StatefulWidget {
  const DevelopmentPage({super.key});

  @override
  State<DevelopmentPage> createState() => _DevelopmentPageState();
}

class _DevelopmentPageState extends State<DevelopmentPage> {
  final ApiService _api = ApiService();
  List<dynamic> _children = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final children = await _api.getChildren();
      setState(() {
        _children = children;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Perkembangan Anak')),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(
                  message: _error!,
                  onRetry: _loadChildren,
                )
              : _children.isEmpty
                  ? AppWidgets.emptyState(
                      icon: Icons.trending_up,
                      title: 'Belum ada data anak',
                      subtitle: 'Data akan muncul ketika anak sudah terdaftar di daycare.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadChildren,
                      color: AppColors.primary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Page header subtitle (matching web)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Pilih anak untuk melihat dan mengelola data perkembangan',
                              style: TextStyle(
                                fontSize: 13,
                                color: mutedColor,
                              ),
                            ),
                          ),

                          // Child card grid (matching web Development.jsx)
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
                                        builder: (_) => DevelopmentDetailPage(
                                          childId: child['id'],
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
                                          color: ThemeHelper.border(context)),
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
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? ThemeHelper.successBg(context)
                                                : ThemeHelper.bgAlt(context),
                                            borderRadius:
                                                BorderRadius.circular(99),
                                          ),
                                          child: Text(
                                            isActive
                                                ? 'Status: Aktif'
                                                : 'Status: Nonaktif',
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
                                              'Lihat Perkembangan',
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
    );
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
  String _progress = 'baik';
  bool _isSubmitting = false;
  String? _error;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _dateController.text = ApiService.today();
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
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final response = await _api.storeAssessment(
        childId: widget.childId,
        developmentCategoryId: _selectedCategoryId!,
        indicator: _indicatorController.text.trim(),
        progress: _progress,
        observationDate: _dateController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
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
        setState(() {
          _error = response['message'] ?? 'Gagal menyimpan.';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = ApiErrorHandler.getMessage(e);
        _isSubmitting = false;
      });
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

              DropdownButtonFormField<int>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Kategori *'),
                items: widget.categories
                    .map<DropdownMenuItem<int>>((c) => DropdownMenuItem(
                        value: c['id'],
                        child: Text('${c['icon'] ?? ''} ${c['name'] ?? ''}')))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                validator: (v) => v == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _indicatorController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Indikator *'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Indikator tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                    labelText: 'Tanggal Observasi *', hintText: 'YYYY-MM-DD'),
                keyboardType: TextInputType.datetime,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Tanggal tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              Text('Progres',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ThemeHelper.text(context))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
                decoration: const InputDecoration(
                    labelText: 'Catatan', alignLabelWithHint: true),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSave,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan Penilaian',
                          style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
      label: Text(label,
          style: TextStyle(
              fontSize: 12,
              color: selected
                  ? Colors.white
                  : ThemeHelper.textSecondary(context))),
      selected: selected,
      onSelected: (_) => setState(() => _progress = value),
      selectedColor: AppColors.primary,
      backgroundColor: ThemeHelper.surface(context),
      side: BorderSide(color: ThemeHelper.border(context)),
    );
  }
}
