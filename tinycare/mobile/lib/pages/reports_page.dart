import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/api_error.dart';

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
      _showToast('Pilih anak terlebih dahulu.', isError: true);
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
          _showToast(res['message'] ?? 'Gagal membuat laporan.', isError: true);
          if (mounted) setState(() => _generating = false);
          return;
        }
      } else {
        final now = DateTime.now();
        final res = await _api.generateMonthlyReport(_selectedChildId!, month: now.month, year: now.year);
        if (res['success'] == false) {
          _showToast(res['message'] ?? 'Gagal membuat laporan.', isError: true);
          if (mounted) setState(() => _generating = false);
          return;
        }
      }
      _showToast('Laporan berhasil dibuat!');
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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          // Child selector
          if (_children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DropdownButton<int>(
                value: _selectedChildId,
                underline: const SizedBox(),
                hint: const Text('Pilih Anak', style: TextStyle(fontSize: 13)),
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
                                        : AppColors.surface,
                                    borderRadius: const BorderRadius.horizontal(
                                        left: Radius.circular(12)),
                                    border: Border.all(
                                        color: _activeTab == 'weekly'
                                            ? AppColors.primary
                                            : AppColors.border),
                                  ),
                                  child: Center(
                                    child: Text('Mingguan',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _activeTab == 'weekly'
                                              ? Colors.white
                                              : AppColors.textSecondary,
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
                                        : AppColors.surface,
                                    borderRadius: const BorderRadius.horizontal(
                                        right: Radius.circular(12)),
                                    border: Border.all(
                                        color: _activeTab == 'monthly'
                                            ? AppColors.primary
                                            : AppColors.border),
                                  ),
                                  child: Center(
                                    child: Text('Bulanan',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _activeTab == 'monthly'
                                              ? Colors.white
                                              : AppColors.textSecondary,
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
                            _buildEmptyOrGenerate('Mingguan', isAdmin)
                          else
                            ..._weeklyReports
                                .map((r) => _buildWeeklyReportCard(r)),
                        ] else ...[
                          if (_monthlyReports.isEmpty)
                            _buildEmptyOrGenerate('Bulanan', isAdmin)
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
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
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
          Text('Belum ada laporan $type',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          Text(
            'Laporan $type belum dibuat. Tekan tombol di bawah untuk generate laporan pertama.',
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                    ? 'Generating...'
                    : 'Generate Laporan $type'),
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
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
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
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text)),
                    const SizedBox(height: 4),
                    Text(
                      '${report['week_start'] ?? '-'} s/d ${report['week_end'] ?? '-'}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              AppWidgets.statusBadge(
                  report['is_generated'] == true ? 'Generated' : 'Draft',
                  report['is_generated'] == true
                      ? AppColors.success
                      : AppColors.warning),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatChip(
                  'Hadir', '${report['total_attendance'] ?? 0}', AppColors.info),
              const SizedBox(width: 8),
              _buildStatChip('Aktivitas', '${report['total_activities'] ?? 0}',
                  AppColors.success),
              const SizedBox(width: 8),
              _buildStatChip(
                  'Cerita',
                  '${report['total_daily_stories'] ?? 0}',
                  Colors.purple),
            ],
          ),
          if (report['attendance_summary'] != null &&
              report['attendance_summary'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSummaryRow('Kehadiran', '${report['attendance_summary']}'),
          ],
          if (report['overall_summary'] != null &&
              report['overall_summary'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.bgAlt, borderRadius: AppRadius.mdAll),
              child: Text(report['overall_summary'],
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyReportCard(dynamic report) {
    const monthNames = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final month = report['month'] ?? 0;
    final year = report['year'] ?? '';
    final monthName = month > 0 && month <= 12 ? monthNames[month] : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
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
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text)),
                    const SizedBox(height: 4),
                    Text('$monthName $year',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              AppWidgets.statusBadge(
                  report['is_generated'] == true ? 'Generated' : 'Draft',
                  report['is_generated'] == true
                      ? AppColors.success
                      : AppColors.warning),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatChip(
                  'Hadir', '${report['total_attendance'] ?? 0}', AppColors.info),
              const SizedBox(width: 8),
              _buildStatChip('Aktivitas', '${report['total_activities'] ?? 0}',
                  AppColors.success),
              const SizedBox(width: 8),
              _buildStatChip(
                  'Cerita',
                  '${report['total_daily_stories'] ?? 0}',
                  Colors.purple),
            ],
          ),
          if (report['attendance_summary'] != null &&
              report['attendance_summary'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSummaryRow('Kehadiran', '${report['attendance_summary']}'),
          ],
          if (report['overall_summary'] != null &&
              report['overall_summary'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.bgAlt, borderRadius: AppRadius.mdAll),
              child: Text(report['overall_summary'],
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        Expanded(
          child: Text(value,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: AppRadius.smAll),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
