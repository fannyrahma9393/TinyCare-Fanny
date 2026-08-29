import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final ApiService _api = ApiService();
  List<dynamic> _users = [];
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.getUsers(filter: _filter);
      setState(() {
        _users = response['data']?['data'] ?? [];
        _summary = response['summary'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data pengguna. Silakan coba lagi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _approveUser(int userId) async {
    try {
      final response = await _api.approveUser(userId);
      if (response['success'] == true) {
        _showToast('Akun berhasil disetujui.');
        _loadUsers();
      } else {
        _showToast(response['message'] ?? 'Gagal menyetujui akun.', isError: true);
      }
    } catch (e) {
      _showToast('Gagal menyetujui akun. Silakan coba lagi.', isError: true);
    }
  }

  Future<void> _rejectUser(int userId) async {
    final reason = await _showRejectDialog();
    if (reason == null) return; // Cancelled

    try {
      final response = await _api.rejectUser(userId, reason: reason);
      if (response['success'] == true) {
        _showToast('Akun berhasil ditolak.');
        _loadUsers();
      } else {
        _showToast(response['message'] ?? 'Gagal menolak akun.', isError: true);
      }
    } catch (e) {
      _showToast('Gagal menolak akun. Silakan coba lagi.', isError: true);
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

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Akun'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Apakah Anda yakin ingin menolak akun ini?'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Alasan penolakan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return AppColors.success;
      case 'pending': return AppColors.warning;
      case 'rejected': return AppColors.error;
      default: return AppColors.textMuted;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active': return 'Aktif';
      case 'pending': return 'Menunggu';
      case 'rejected': return 'Ditolak';
      case 'inactive': return 'Nonaktif';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Pengguna')),
      body: Column(
        children: [
          // Summary Cards
          if (_summary != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildSummaryChip('Total', '${_summary!['total'] ?? '-'}', AppColors.primary),
                  const SizedBox(width: 8),
                  _buildSummaryChip('Aktif', '${_summary!['active_parents'] ?? '-'}', AppColors.success),
                  const SizedBox(width: 8),
                  _buildSummaryChip('Pending', '${_summary!['pending_parents'] ?? '-'}', AppColors.warning),
                  const SizedBox(width: 8),
                  _buildSummaryChip('Admin', '${_summary!['admins'] ?? '-'}', AppColors.info),
                ],
              ),
            ),

          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('Semua', 'all'),
                _buildFilterChip('Orang Tua', 'parent'),
                _buildFilterChip('Menunggu', 'pending'),
                _buildFilterChip('Admin', 'admin'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // User List
          Expanded(
            child: _isLoading
                ? AppWidgets.loadingIndicator()
                : _error != null
                    ? AppWidgets.errorState(message: _error!, onRetry: _loadUsers)
                    : _users.isEmpty
                        ? AppWidgets.emptyState(
                            icon: Icons.people_outline,
                            title: 'Tidak ada pengguna ditemukan',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUsers,
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _users.length,
                              itemBuilder: (context, index) => _buildUserCard(_users[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        )),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _filter = value);
          _loadUsers();
        },
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    final status = user['status'] ?? 'active';
    final role = user['role']?['name'] ?? 'parent';
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
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
                    Text(user['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(user['email'] ?? '-', style: AppTypography.caption),
                  ],
                ),
              ),
              AppWidgets.statusBadge(_statusLabel(status), _statusColor(status)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AppWidgets.statusBadge(
                role == 'admin_master' ? 'Admin Master' : role == 'admin' ? 'Admin' : 'Orang Tua',
                role == 'admin_master' ? AppColors.primary : role == 'admin' ? AppColors.info : AppColors.textMuted,
              ),
              const Spacer(),
              if (isPending) ...[
                ElevatedButton(
                  onPressed: () => _approveUser(user['id']),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Setujui', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: () => _rejectUser(user['id']),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Tolak', style: TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
