import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/child_select.dart';
import '../l10n/app_strings.dart';

/// Development detail for one child — mirrors web DevelopmentDetail.jsx.
/// Shows child header, category cards, assessment history, and reports section.
class DevelopmentDetailPage extends StatefulWidget {
  const DevelopmentDetailPage({super.key, required this.childId});

  final int childId;

  @override
  State<DevelopmentDetailPage> createState() => _DevelopmentDetailPageState();
}

class _DevelopmentDetailPageState extends State<DevelopmentDetailPage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _child;
  Map<String, dynamic>? _developmentData;
  bool _isLoading = true;
  String? _error;

  // Reports
  List<dynamic> _weeklyReports = [];
  List<dynamic> _monthlyReports = [];
  String _reportTab = 'weekly';
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final child = await _api.getChild(widget.childId);
      final data = await _api.getDevelopment(widget.childId);
      // Load reports in parallel (optional, don't block)
      List<dynamic> weekly = [];
      List<dynamic> monthly = [];
      try {
        final weeklyRes = await _api.getWeeklyReports(perPage: 10);
        final weeklyData = weeklyRes['data'];
        if (weeklyData is Map && weeklyData.containsKey('data')) {
          weekly = weeklyData['data'] ?? [];
        }
      } catch (_) {}
      try {
        final monthlyRes = await _api.getMonthlyReports(perPage: 10);
        final monthlyData = monthlyRes['data'];
        if (monthlyData is Map && monthlyData.containsKey('data')) {
          monthly = monthlyData['data'] ?? [];
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _child = child;
        _developmentData = data;
        _weeklyReports = weekly;
        _monthlyReports = monthly;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = tr('Gagal memuat data perkembangan.');
        _isLoading = false;
      });
    }
  }

  Future<void> _generateWeeklyReport() async {
    setState(() => _generating = true);
    try {
      final now = DateTime.now();
      final dayOfWeek = now.weekday;
      final monday = now.subtract(Duration(days: dayOfWeek - 1));
      final weekStart =
          '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
      await _api.generateWeeklyReport(widget.childId, weekStart: weekStart);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Laporan mingguan berhasil dibuat.')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Gagal membuat laporan mingguan.')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _generateMonthlyReport() async {
    setState(() => _generating = true);
    try {
      final now = DateTime.now();
      await _api.generateMonthlyReport(
        widget.childId,
        month: now.month,
        year: now.year,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Laporan bulanan berhasil dibuat.')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Gagal membuat laporan bulanan.')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final textColor = ThemeHelper.text(context);

    return Scaffold(
      appBar: AppBar(title: Text(tr('Perkembangan Anak'))),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(
                  message: _error!,
                  onRetry: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _loadData();
                  },
                )
              : _child == null
                  ? AppWidgets.emptyState(
                      icon: Icons.child_care,
                      title: tr('Anak tidak ditemukan.'),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppColors.primary,
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          // Child header
                          ChildHeader(
                            child: _child,
                            subtitle: tr('Perkembangan & penilaian anak Anda.'),
                          ),
                          const SizedBox(height: 20),

                          // Category cards
                          Text(tr('Kategori Perkembangan'),
                              style: AppTypography.h3
                                  .copyWith(color: textColor)),
                          const SizedBox(height: 14),
                          ..._buildCategoryCards(),

                          // Reports section (admin only — matches web)
                          if (isAdmin) ...[
                            const SizedBox(height: 24),
                            _buildReportsSection(),
                          ],
                        ],
                      ),
                    ),
    );
  }

  List<Widget> _buildCategoryCards() {
    final categories = _developmentData?['categories'];
    if (categories is! List || categories.isEmpty) {
      return [
        AppWidgets.emptyState(
          icon: Icons.trending_up,
          title: tr('Belum ada penilaian'),
        ),
      ];
    }
    return categories
        .map<Widget>((cat) => _CategoryCard(category: cat))
        .toList();
  }

  /// Reports section — matches web DevelopmentDetail.jsx "Laporan Perkembangan"
  Widget _buildReportsSection() {
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);
    final reports =
        _reportTab == 'weekly' ? _weeklyReports : _monthlyReports;

    return Container(
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
          // Header with generate button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('Laporan Perkembangan'),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
              ElevatedButton.icon(
                onPressed: _generating
                    ? null
                    : _reportTab == 'weekly'
                        ? _generateWeeklyReport
                        : _generateMonthlyReport,
                icon: _generating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add, size: 16),
                label: Text(_generating ? tr('Membuat...') : tr('Generate')),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tab buttons (Mingguan / Bulanan)
          Row(
            children: [
              _buildReportTab('weekly', tr('Mingguan')),
              const SizedBox(width: 6),
              _buildReportTab('monthly', tr('Bulanan')),
            ],
          ),
          const SizedBox(height: 14),

          // Report list
          if (reports.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(                        tr('Belum ada laporan {{type}}. Klik Generate untuk membuat.',
                            {
                              'type': _reportTab == 'weekly'
                                  ? tr('Mingguan').toLowerCase()
                                  : tr('Bulanan').toLowerCase(),
                            }),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: mutedColor),
              ),
            )
          else
            ...reports.map((report) => _buildReportCard(report)),
        ],
      ),
    );
  }

  Widget _buildReportTab(String tab, String label) {
    final selected = _reportTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _reportTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : ThemeHelper.bgAlt(context),
          borderRadius: AppRadius.smAll,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : ThemeHelper.textSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(dynamic report) {
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);
    final bgColor = ThemeHelper.bgAlt(context);

    String periodText;
    if (_reportTab == 'weekly') {
      final start = report['week_start'] ?? '';
      final end = report['week_end'] ?? '';
      periodText = tr('{{start}} — {{end}}', {'start': start, 'end': end});
    } else {
      final month = report['month'] ?? 1;
      final year = report['year'] ?? DateTime.now().year;
      final months = [
        '', tr('Januari'), tr('Februari'), tr('Maret'), tr('April'), tr('Mei'), tr('Juni'),
        tr('Juli'), tr('Agustus'), tr('September'), tr('Oktober'), tr('November'), tr('Desember')
      ];
      periodText =
          '${months[month > 0 && month <= 12 ? month : 1]} $year';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.smAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                report['child']?['name'] ?? _child?['name'] ?? '-',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor),
              ),
              AppWidgets.statusBadge(tr('Generated'), AppColors.success),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            periodText,
            style: TextStyle(fontSize: 12, color: mutedColor),
          ),
          if (report['overall_summary'] != null &&
              report['overall_summary'].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              report['overall_summary'],
              style: TextStyle(
                fontSize: 12,
                color: ThemeHelper.textSecondary(context),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final dynamic category;

  Color _getProgressColor(double percentage) {
    if (percentage >= 75) return AppColors.success;
    if (percentage >= 50) return AppColors.warning;
    if (percentage >= 25) return Colors.orange;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);
    final avgProgress = (category['average_progress'] ?? 0).toDouble();
    final total = category['total_assessments'] ?? 0;
    final recent = category['recent_assessments'];

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
              Text(category['icon'] ?? '📊',
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category['name'] ?? '-',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                    const SizedBox(height: 2),
                    Text(tr('{{total}} penilaian', {'total': total}),
                        style: AppTypography.caption
                            .copyWith(color: mutedColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (avgProgress / 100).clamp(0.0, 1.0),
                    backgroundColor: ThemeHelper.border(context),
                    valueColor:
                        AlwaysStoppedAnimation(_getProgressColor(avgProgress)),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text('${avgProgress.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: textColor)),
            ],
          ),
          if (recent is List && recent.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(color: ThemeHelper.border(context)),
            const SizedBox(height: 10),
            ...recent.map<Widget>((a) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeHelper.bgAlt(context),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a['indicator'] ?? '-',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: textColor)),
                            const SizedBox(height: 2),
                            Text(
                                '${category['name'] ?? ''} · ${a['observation_date'] ?? ''}',
                                style: AppTypography.caption
                                    .copyWith(color: mutedColor)),
                          ],
                        ),
                      ),
                      Text(a['progress_label'] ?? '',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getProgressColor(
                                  a['progress_percentage'] ?? 0))),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
