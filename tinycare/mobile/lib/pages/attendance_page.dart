import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Admin attendance page — mirrors web Attendance.
///
/// Lists attendance records with date, child name, check-in/check-out times,
/// and status. Admin can view and manage attendance.
class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final ApiService _api = ApiService();
  List<dynamic> _attendance = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedMonth;
  String? _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month.toString().padLeft(2, '0');
    _selectedYear = now.year.toString();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final attendance = await _api.getAdminAttendance(
        month: _selectedMonth,
        year: _selectedYear,
      );
      setState(() {
        _attendance = attendance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data kehadiran.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);
    final surfaceColor = ThemeHelper.surface(context);
    final borderColor = ThemeHelper.border(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kehadiran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendance,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Bulan',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: '01', child: Text('Januari')),
                      DropdownMenuItem(value: '02', child: Text('Februari')),
                      DropdownMenuItem(value: '03', child: Text('Maret')),
                      DropdownMenuItem(value: '04', child: Text('April')),
                      DropdownMenuItem(value: '05', child: Text('Mei')),
                      DropdownMenuItem(value: '06', child: Text('Juni')),
                      DropdownMenuItem(value: '07', child: Text('Juli')),
                      DropdownMenuItem(value: '08', child: Text('Agustus')),
                      DropdownMenuItem(value: '09', child: Text('September')),
                      DropdownMenuItem(value: '10', child: Text('Oktober')),
                      DropdownMenuItem(value: '11', child: Text('November')),
                      DropdownMenuItem(value: '12', child: Text('Desember')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedMonth = v);
                        _loadAttendance();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Tahun',
                      isDense: true,
                    ),
                    items: List.generate(5, (i) {
                      final year = (DateTime.now().year - 2 + i).toString();
                      return DropdownMenuItem(value: year, child: Text(year));
                    }),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedYear = v);
                        _loadAttendance();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: _isLoading
                ? AppWidgets.loadingIndicator()
                : _error != null
                    ? AppWidgets.errorState(message: _error!, onRetry: _loadAttendance)
                    : _attendance.isEmpty
                        ? AppWidgets.emptyState(
                            icon: Icons.calendar_today,
                            title: 'Belum ada data kehadiran',
                            subtitle: 'Data kehadiran akan muncul di sini.',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAttendance,
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              itemCount: _attendance.length,
                              itemBuilder: (context, index) =>
                                  _buildAttendanceCard(_attendance[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(dynamic record) {
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);
    final surfaceColor = ThemeHelper.surface(context);
    final borderColor = ThemeHelper.border(context);

    final date = record['date'] ?? '-';
    final childName = (record['child']?['name'] ?? record['name'] ?? '-') as String;
    final checkIn = record['check_in_time'] ?? '-';
    final checkOut = record['check_out_time'] ?? '-';
    final status = record['status'] ?? 'hadir';
    final statusColor = status == 'hadir' ? AppColors.success : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: borderColor),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              status == 'hadir' ? Icons.check_circle : Icons.schedule,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  childName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(date),
                  style: TextStyle(fontSize: 12, color: mutedColor),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Masuk: $checkIn',
                style: TextStyle(fontSize: 12, color: mutedColor),
              ),
              const SizedBox(height: 2),
              Text(
                'Keluar: $checkOut',
                style: TextStyle(fontSize: 12, color: mutedColor),
              ),
            ],
          ),
          const SizedBox(width: 8),
          AppWidgets.statusBadge(
            status == 'hadir' ? 'Hadir' : 'Tidak Hadir',
            statusColor,
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        final m = int.tryParse(parts[1]);
        return '${parts[2]} ${months[m! - 1]} ${parts[0]}';
      }
    } catch (_) {}
    return dateStr;
  }
}
