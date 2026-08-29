import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/api_error.dart';
import 'package:provider/provider.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final ApiService _api = ApiService();
  List<dynamic> _children = [];
  int? _selectedChildId;
  Map<String, dynamic>? _attendanceData;
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
        await _loadAttendance(_selectedChildId!);
      } else {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Gagal memuat data.'; _isLoading = false; });
    }
  }

  Future<void> _loadAttendance(int childId) async {
    try {
      final now = DateTime.now();
      final data = await _api.getAttendance(childId, month: '${now.month}', year: '${now.year}');
      setState(() { _attendanceData = data; _isLoading = false; });
    } catch (e) {
      setState(() { _error = ApiErrorHandler.getMessage(e); _isLoading = false; });
    }
  }

  /// Compute summary from admin attendance data (admin endpoint has no summary)
  Map<String, int> _computeSummary() {
    final summary = <String, int>{
      'hadir': 0, 'izin': 0, 'sakit': 0, 'tidak_hadir': 0,
    };
    // Try parent format
    final parentSummary = _attendanceData?['summary'];
    if (parentSummary is Map) {
      summary['hadir'] = (parentSummary['hadir'] ?? 0) is int ? parentSummary['hadir'] : int.tryParse('${parentSummary['hadir']}') ?? 0;
      summary['izin'] = (parentSummary['izin'] ?? 0) is int ? parentSummary['izin'] : int.tryParse('${parentSummary['izin']}') ?? 0;
      summary['sakit'] = (parentSummary['sakit'] ?? 0) is int ? parentSummary['sakit'] : int.tryParse('${parentSummary['sakit']}') ?? 0;
      summary['tidak_hadir'] = (parentSummary['tidak_hadir'] ?? 0) is int ? parentSummary['tidak_hadir'] : int.tryParse('${parentSummary['tidak_hadir']}') ?? 0;
      if (summary.values.any((v) => v > 0)) return summary;
    }
    // Admin format: compute from records
    final records = _getAttendanceRecords();
    for (final r in records) {
      final st = r['status'] ?? '';
      if (summary.containsKey(st)) summary[st] = summary[st]! + 1;
    }
    return summary;
  }

  List<dynamic> _getAttendanceRecords() {
    if (_attendanceData == null) return [];
    final attendance = _attendanceData!['attendance'];
    if (attendance != null) {
      final data = attendance is Map ? (attendance['data'] ?? []) : attendance;
      if (data is List) return data;
    }
    final data = _attendanceData!['data'];
    if (data is List) return data;
    if (data is Map && data.containsKey('data')) return data['data'] ?? [];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Absensi')),
      floatingActionButton: (isAdmin && _children.isNotEmpty) ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context,
            MaterialPageRoute(builder: (_) => _AttendanceFormPage(children: _children, selectedChildId: _selectedChildId)));
          if (result == true && _selectedChildId != null) _loadAttendance(_selectedChildId!);
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
                  ? AppWidgets.emptyState(icon: Icons.calendar_today, title: 'Belum ada data anak')
                  : RefreshIndicator(
                      onRefresh: () async {
                        if (_selectedChildId != null) await _loadAttendance(_selectedChildId!);
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
                                  hint: Text('Pilih Anak', style: TextStyle(color: ThemeHelper.textMuted(context))),
                                  items: _children.map<DropdownMenuItem<int>>((child) =>
                                    DropdownMenuItem(value: child['id'], child: Text(child['name'] ?? '-'))
                                  ).toList(),
                                  onChanged: (id) {
                                    if (id != null) {
                                      setState(() { _selectedChildId = id; _isLoading = true; _error = null; });
                                      _loadAttendance(id);
                                    }
                                  },
                                ),
                              ),

                            if (_attendanceData != null) ...[
                              Text('Ringkasan Bulan Ini', style: AppTypography.h3.copyWith(color: ThemeHelper.text(context))),
                              const SizedBox(height: 14),
                              Builder(
                                builder: (context) {
                                  final summary = _computeSummary();
                                  return Row(
                                    children: [
                                      _buildSummaryCard('Hadir', '${summary['hadir']}', ThemeHelper.successBg(context), AppColors.success),
                                      const SizedBox(width: 8),
                                      _buildSummaryCard('Izin', '${summary['izin']}', ThemeHelper.infoBg(context), AppColors.info),
                                      const SizedBox(width: 8),
                                      _buildSummaryCard('Sakit', '${summary['sakit']}', ThemeHelper.warningBg(context), AppColors.warning),
                                      const SizedBox(width: 8),
                                      _buildSummaryCard('Alpa', '${summary['tidak_hadir']}', ThemeHelper.errorBg(context), AppColors.error),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 28),
                            ],

                            Text('Riwayat', style: AppTypography.h3.copyWith(color: ThemeHelper.text(context))),
                            const SizedBox(height: 14),
                            ..._buildAttendanceList(isAdmin),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(color: bgColor, borderRadius: AppRadius.mdAll),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAttendanceList(bool isAdmin) {
    // Admin endpoint returns paginated data directly: {data: [...], meta: {...}}
    // Parent endpoint returns: {attendance: {data: [...], ...}, summary: {...}}
    List<dynamic> dataList = [];
    
    if (_attendanceData != null) {
      // Try parent format first
      final attendance = _attendanceData!['attendance'];
      if (attendance != null) {
        final data = attendance is Map ? (attendance['data'] ?? []) : attendance;
        if (data is List) dataList = data;
      } else {
        // Admin format: paginated data directly
        final data = _attendanceData!['data'];
        if (data is List) {
          dataList = data;
        } else if (data is Map && data.containsKey('data')) {
          dataList = data['data'] ?? [];
        }
      }
    }

    if (dataList.isEmpty) {
      return [AppWidgets.emptyState(icon: Icons.calendar_today, title: 'Tidak ada riwayat')];
    }

    return dataList.map<Widget>((item) {
      final statusColor = {
        'hadir': AppColors.success,
        'izin': AppColors.info,
        'sakit': AppColors.warning,
        'tidak_hadir': AppColors.error,
      }[item['status']] ?? ThemeHelper.textMuted(context);

      final statusLabel = {
        'hadir': 'Hadir',
        'izin': 'Izin',
        'sakit': 'Sakit',
        'tidak_hadir': 'Tidak Hadir',
      }[item['status']] ?? item['status'] ?? '-';

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ThemeHelper.surface(context),
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: ThemeHelper.border(context)),
        ),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['date'] ?? '-', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: ThemeHelper.text(context))),
                  const SizedBox(height: 2),
                  Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (item['check_in_time'] != null)
              Text(item['check_in_time'] ?? '', style: TextStyle(color: ThemeHelper.textMuted(context), fontSize: 12)),
            if (isAdmin)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: ThemeHelper.textMuted(context)),
                onSelected: (value) async {
                  if (value == 'edit' && item['id'] != null) {
                    final result = await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => _AttendanceFormPage(
                        attendance: item, children: _children, selectedChildId: _selectedChildId)));
                    if (result == true && _selectedChildId != null) _loadAttendance(_selectedChildId!);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                ],
              ),
          ],
        ),
      );
    }).toList();
  }
}

// ==================== Attendance Form (Admin) ====================
class _AttendanceFormPage extends StatefulWidget {
  final dynamic attendance;
  final List<dynamic> children;
  final int? selectedChildId;
  const _AttendanceFormPage({this.attendance, required this.children, this.selectedChildId});

  @override
  State<_AttendanceFormPage> createState() => _AttendanceFormPageState();
}

class _AttendanceFormPageState extends State<_AttendanceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _checkInController = TextEditingController();
  final _checkOutController = TextEditingController();
  final _notesController = TextEditingController();
  String _status = 'hadir';
  int? _selectedChildId;
  bool _isSubmitting = false;
  String? _error;

  final ApiService _api = ApiService();
  bool get _isEditing => widget.attendance != null;

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.selectedChildId;
    if (_isEditing) {
      _dateController.text = widget.attendance['date'] ?? '';
      _checkInController.text = widget.attendance['check_in_time'] ?? '';
      _checkOutController.text = widget.attendance['check_out_time'] ?? '';
      _notesController.text = widget.attendance['notes'] ?? '';
      _status = widget.attendance['status'] ?? 'hadir';
      _selectedChildId = widget.attendance['child_id'] ?? widget.attendance['child']?['id'];
    } else {
      _dateController.text = ApiService.today(); // Default = today
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _error = null; });

    try {
      Map<String, dynamic> response;
      if (_isEditing) {
        response = await _api.updateAttendance(
          widget.attendance['id'],
          status: _status,
          checkInTime: _checkInController.text.trim().isNotEmpty ? _checkInController.text.trim() : null,
          checkOutTime: _checkOutController.text.trim().isNotEmpty ? _checkOutController.text.trim() : null,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );
      } else {
        if (_selectedChildId == null) {
          setState(() { _error = 'Pilih anak terlebih dahulu.'; _isSubmitting = false; });
          return;
        }
        response = await _api.storeAttendance(
          childId: _selectedChildId!,
          date: _dateController.text.trim(),
          status: _status,
          checkInTime: _checkInController.text.trim().isNotEmpty ? _checkInController.text.trim() : null,
          checkOutTime: _checkOutController.text.trim().isNotEmpty ? _checkOutController.text.trim() : null,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );
      }

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'Absensi diperbarui.' : 'Absensi dicatat.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
          );
          Navigator.pop(context, true);
        }      } else {
        setState(() {
          _error = response['message'] ?? 'Gagal menyimpan.';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() { _error = ApiErrorHandler.getMessage(e); _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Absensi' : 'Catat Absensi')),
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

              // Child selector (only for create)
              if (!_isEditing && widget.children.length > 1) ...[
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
              ],

              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Tanggal *', hintText: 'YYYY-MM-DD'),
                keyboardType: TextInputType.datetime,
                validator: (v) => v == null || v.isEmpty ? 'Tanggal tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              // Status selector
              Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  _buildStatusChip('hadir', '✅ Hadir', AppColors.success),
                  _buildStatusChip('izin', '📝 Izin', AppColors.info),
                  _buildStatusChip('sakit', '🤒 Sakit', AppColors.warning),
                  _buildStatusChip('tidak_hadir', '❌ Tidak Hadir', AppColors.error),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _checkInController,
                decoration: const InputDecoration(labelText: 'Waktu Masuk', hintText: 'HH:MM'),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _checkOutController,
                decoration: const InputDecoration(labelText: 'Waktu Pulang', hintText: 'HH:MM'),
                keyboardType: TextInputType.datetime,
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
                      : Text(_isEditing ? 'Simpan Perubahan' : 'Catat Absensi',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String value, String label, Color color) {
    final selected = _status == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : ThemeHelper.textSecondary(context))),
      selected: selected,
      onSelected: (_) => setState(() => _status = value),
      selectedColor: color,
      backgroundColor: ThemeHelper.surface(context),
      side: BorderSide(color: ThemeHelper.border(context)),
    );
  }
}
