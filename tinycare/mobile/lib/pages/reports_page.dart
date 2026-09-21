import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/api_error.dart';
import '../l10n/app_strings.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final ApiService _api = ApiService();
  List<dynamic> _weeklyReports = [];
  List<dynamic> _monthlyReports = [];
  List<dynamic> _children = [];
  bool _isLoading = true;
  String? _error;
  String _activeTab = 'weekly';
  int? _selectedChildId;
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
      // Load children first — needed for Generate
      final children = await _api.getChildren();
      _children = children;
      if (children.isNotEmpty && _selectedChildId == null) {
        _selectedChildId = children[0]['id'];
      }

      // Load weekly reports
      List<dynamic> weekly = [];
      try {
        final weeklyRes = await _api.getWeeklyReports(perPage: 20);
        weekly = _parsePaginated(weeklyRes);
      } catch (e) {
        debugPrint('[Reports] Weekly reports load failed: $e');
        // Don't crash — show empty state
      }

      // Load monthly reports
      List<dynamic> monthly = [];
      try {
        final monthlyRes = await _api.getMonthlyReports(perPage: 20);
        monthly = _parsePaginated(monthlyRes);
      } catch (e) {
        debugPrint('[Reports] Monthly reports load failed: $e');
        // Don't crash — show empty state
      }

      if (!mounted) return;
      setState(() {
        _weeklyReports = weekly;
        _monthlyReports = monthly;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiErrorHandler.getMessage(e);
        _isLoading = false;
      });
    }
  }

  /// Parse Laravel paginated response: { data: { data: [...], ... } }
  List<dynamic> _parsePaginated(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map && data.containsKey('data')) {
      final items = data['data'];
      return items is List ? items : [];
    }
    if (data is List) return data;
    return [];
  }

  Future<void> _generateReport() async {
    if (_selectedChildId == null) {
      _showToast(tr('Pilih anak terlebih dahulu.'), isError: true);
      return;
    }

    setState(() => _generating = true);
    try {
      if (_activeTab == 'weekly') {
        final now = DateTime.now();
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final weekStart =
            '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
        final res = await _api.generateWeeklyReport(_selectedChildId!, weekStart: weekStart);
        if (res['success'] == false) {
          _showToast(res['message'] ?? tr('Gagal membuat laporan.'), isError: true);
          if (mounted) setState(() => _generating = false);
          return;
        }
      } else {
        final now = DateTime.now();
        final res = await _api.generateMonthlyReport(_selectedChildId!, month: now.month, year: now.year);
        if (res['success'] == false) {
          _showToast(res['message'] ?? tr('Gagal membuat laporan.'), isError: true);
          if (mounted) setState(() => _generating = false);
          return;
        }
      }
      _showToast(tr('Laporan berhasil dibuat!'));
      await _loadData();
    } catch (e) {
      _showToast(ApiErrorHandler.getMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _generating = false);
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Laporan')),
        actions: [
          // Child selector
          if (_children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DropdownButton<int>(
                value: _selectedChildId,
                underline: const SizedBox(),
                hint: Text(tr('Pilih Anak'), style: TextStyle(fontSize: 13)),
                items: _children.map<DropdownMenuItem<int>>((child) {
                  return DropdownMenuItem(
                    value: child['id'],
                    child: Text(child['name'] ?? '-',
                        style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id != null) setState(() => _selectedChildId = id);
                },
              ),
            ),
        ],
      ),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(message: _error!, onRetry: _loadData)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tab Selector
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _activeTab = 'weekly'),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _activeTab == 'weekly'
                                        ? AppColors.primary
                                        : ThemeHelper.surface(context),
                                    borderRadius: const BorderRadius.horizontal(
                                        left: Radius.circular(12)),
                                    border: Border.all(
                                        color: _activeTab == 'weekly'
                                            ? AppColors.primary
                                            : ThemeHelper.border(context)),
                                  ),
                                  child: Center(
                                    child: Text(tr('Mingguan'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _activeTab == 'weekly'
                                              ? Colors.white
                                              : ThemeHelper.textSecondary(context),
                                        )),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _activeTab = 'monthly'),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _activeTab == 'monthly'
                                        ? AppColors.primary
                                        : ThemeHelper.surface(context),
                                    borderRadius: const BorderRadius.horizontal(
                                        right: Radius.circular(12)),
                                    border: Border.all(
                                        color: _activeTab == 'monthly'
                                            ? AppColors.primary
                                            : ThemeHelper.border(context)),
                                  ),
                                  child: Center(
                                    child: Text(tr('Bulanan'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _activeTab == 'monthly'
                                              ? Colors.white
                                              : ThemeHelper.textSecondary(context),
                                        )),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Report content
                        if (_activeTab == 'weekly') ...[
                          if (_weeklyReports.isEmpty)
                            _buildEmptyOrGenerate(tr('Mingguan'), isAdmin)
                          else
                            ..._weeklyReports
                                .map((r) => _buildWeeklyReportCard(r)),
                        ] else ...[
                          if (_monthlyReports.isEmpty)
                            _buildEmptyOrGenerate(tr('Bulanan'), isAdmin)
                          else
                            ..._monthlyReports
                                .map((r) => _buildMonthlyReportCard(r)),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyOrGenerate(String type, bool isAdmin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ThemeHelper.surface(context),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: ThemeHelper.border(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: AppRadius.lgAll,
            ),
            child: const Icon(Icons.assessment_outlined,
                size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(tr('Belum ada laporan {{type}}', {'type': type}),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ThemeHelper.text(context))),
          const SizedBox(height: 8),
          Text(
            tr('Laporan {{type}} belum dibuat. Tekan tombol di bawah untuk generate laporan pertama.', {'type': type}),
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: ThemeHelper.textSecondary(context)),
          ),
          const SizedBox(height: 20),
          if (isAdmin)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generating ? null : _generateReport,
                icon: _generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(_generating
                    ? tr('Generating...')
                    : tr('Generate Laporan {{type}}', {'type': type})),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyReportCard(dynamic report) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report['child']?['name'] ?? '-',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ThemeHelper.text(context))),
                    const SizedBox(height: 4),
                    Text(
                      '${report['week_start'] ?? '-'} s/d ${report['week_end'] ?? '-'}',
                      style: TextStyle(
                          fontSize: 12, color: ThemeHelper.textMuted(context)),
                    ),
                  ],
                ),
              ),
              AppWidgets.statusBadge(
                  report['is_generated'] == true ? tr('Generated') : tr('Draft'),
                  report['is_generated'] == true
                      ? AppColors.success
                      : AppColors.warning),
            ],
          ),
          const SizedBox(height: 14),
          if (report['overall_summary'] != null &&
              report['overall_summary'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: ThemeHelper.bgAlt(context),
                  borderRadius: AppRadius.mdAll),
              child: Text(report['overall_summary'],
                  style: TextStyle(
                      fontSize: 13,
                      color: ThemeHelper.textSecondary(context),
                      height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyReportCard(dynamic report) {
    final monthNames = [
      '',
      tr('Januari'),
      tr('Februari'),
      tr('Maret'),
      tr('April'),
      tr('Mei'),
      tr('Juni'),
      tr('Juli'),
      tr('Agustus'),
      tr('September'),
      tr('Oktober'),
      tr('November'),
      tr('Desember')
    ];
    final month = report['month'] ?? 0;
    final year = report['year'] ?? '';
    final monthName = month > 0 && month <= 12 ? monthNames[month] : '';

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report['child']?['name'] ?? '-',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ThemeHelper.text(context))),
                    const SizedBox(height: 4),
                    Text('$monthName $year',
                        style: TextStyle(
                            fontSize: 12,
                            color: ThemeHelper.textMuted(context))),
                  ],
                ),
              ),
              AppWidgets.statusBadge(
                  report['is_generated'] == true ? tr('Generated') : tr('Draft'),
                  report['is_generated'] == true
                      ? AppColors.success
                      : AppColors.warning),
            ],
          ),
          const SizedBox(height: 14),
          if (report['overall_summary'] != null &&
              report['overall_summary'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: ThemeHelper.bgAlt(context),
                  borderRadius: AppRadius.mdAll),
              child: Text(report['overall_summary'],
                  style: TextStyle(
                      fontSize: 13,
                      color: ThemeHelper.textSecondary(context),
                      height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }
}
