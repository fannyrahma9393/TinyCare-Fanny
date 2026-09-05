import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/child_photo.dart';

class ParentsPage extends StatefulWidget {
  const ParentsPage({super.key});

  @override
  State<ParentsPage> createState() => _ParentsPageState();
}

class _ParentsPageState extends State<ParentsPage> {
  final ApiService _api = ApiService();
  List<dynamic> _allParents = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'all';

  List<dynamic> get _parents {
    if (_filter == 'all') return _allParents;
    return _allParents.where((p) {
      final status = p['user']?['status'] ?? 'active';
      return status == _filter;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadParents();
  }

  Future<void> _loadParents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.getParents(filter: _filter);
      setState(() {
        _allParents = response['data']?['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data orang tua. Silakan coba lagi.';
        _isLoading = false;
      });
    }
  }

  String _getName(dynamic parent) {
    // Backend nests user data: parent['user']['name']
    final user = parent['user'];
    if (user != null && user['name'] != null && user['name'].toString().isNotEmpty) {
      return user['name'];
    }
    // Fallback
    return 'Orang Tua';
  }

  String _getEmail(dynamic parent) {
    final user = parent['user'];
    if (user != null && user['email'] != null && user['email'].toString().isNotEmpty) {
      return user['email'];
    }
    return '-';
  }

  String _getPhone(dynamic parent) {
    return parent['phone']?.toString() ?? '-';
  }

  String _getStatus(dynamic parent) {
    final user = parent['user'];
    if (user != null) {
      return user['status'] ?? 'active';
    }
    return 'active';
  }

  int _getChildrenCount(dynamic parent) {
    final children = parent['children'];
    if (children is List) return children.length;
    return 0;
  }

  String _getInitial(dynamic parent) {
    final name = _getName(parent);
    if (name.isNotEmpty && name != 'Orang Tua') {
      return name[0].toUpperCase();
    }
    return 'OT';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orang Tua')),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('Semua', 'all'),
                _buildFilterChip('Aktif', 'active'),
                _buildFilterChip('Menunggu', 'pending'),
              ],
            ),
          ),

          // Parent List
          Expanded(
            child: _isLoading
                ? AppWidgets.loadingIndicator()
                : _error != null
                    ? AppWidgets.errorState(message: _error!, onRetry: _loadParents)
                    : _parents.isEmpty
                        ? AppWidgets.emptyState(
                            icon: Icons.people_outline,
                            title: 'Tidak ada data orang tua',
                            subtitle: 'Data orang tua akan muncul ketika sudah terdaftar.',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadParents,
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _parents.length,
                              itemBuilder: (context, index) => _buildParentCard(_parents[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : ThemeHelper.textSecondary(context),
        )),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _filter = value);
          _loadParents();
        },
        selectedColor: AppColors.primary,
        backgroundColor: ThemeHelper.surface(context),
        side: BorderSide(color: ThemeHelper.border(context)),
      ),
    );
  }

  Widget _buildParentCard(dynamic parent) {
    final status = _getStatus(parent);
    final childrenCount = _getChildrenCount(parent);
    final name = _getName(parent);
    final email = _getEmail(parent);
    final phone = _getPhone(parent);
    final initial = _getInitial(parent);

    final statusColor = status == 'active'
        ? AppColors.success
        : status == 'pending'
            ? AppColors.warning
            : ThemeHelper.textMuted(context);
    final statusLabel = status == 'active'
        ? 'Aktif'
        : status == 'pending'
            ? 'Menunggu'
            : status == 'rejected'
                ? 'Ditolak'
                : status;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: ThemeHelper.surface(context),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: ThemeHelper.border(context)),
        boxShadow: AppColors.cardShadow,
      ),
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: () => _openParentDetail(parent),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(email, style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (phone != '-') ...[
                      const SizedBox(height: 2),
                      Text(phone, style: TextStyle(fontSize: 11, color: ThemeHelper.textMuted(context))),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '$childrenCount ${childrenCount == 1 ? 'anak' : 'anak'} terdaftar',
                      style: TextStyle(fontSize: 11, color: ThemeHelper.textMuted(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppWidgets.statusBadge(statusLabel, statusColor),
                  const SizedBox(height: 8),
                  Icon(Icons.chevron_right, size: 18, color: ThemeHelper.textMuted(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openParentDetail(dynamic parent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParentDetailPage(parent: parent),
      ),
    ).then((result) {
      if (result == true) _loadParents();
    });
  }
}

/// Parent Detail Page
class ParentDetailPage extends StatefulWidget {
  final dynamic parent;
  const ParentDetailPage({super.key, required this.parent});

  @override
  State<ParentDetailPage> createState() => _ParentDetailPageState();
}

class _ParentDetailPageState extends State<ParentDetailPage> {
  final ApiService _api = ApiService();
  late dynamic _parent;

  @override
  void initState() {
    super.initState();
    _parent = widget.parent;
  }

  String _getName() {
    final user = _parent['user'];
    if (user != null && user['name'] != null && user['name'].toString().isNotEmpty) {
      return user['name'];
    }
    return 'Orang Tua';
  }

  String _getEmail() {
    final user = _parent['user'];
    if (user != null && user['email'] != null) {
      return user['email'];
    }
    return '-';
  }

  String _getPhone() {
    return _parent['phone']?.toString() ?? '-';
  }

  String _getStatus() {
    final user = _parent['user'];
    if (user != null) {
      return user['status'] ?? 'active';
    }
    return 'active';
  }

  List<dynamic> _getChildren() {
    final children = _parent['children'];
    if (children is List) return children;
    return [];
  }

  String _getInitial() {
    final name = _getName();
    if (name.isNotEmpty && name != 'Orang Tua') {
      return name[0].toUpperCase();
    }
    return 'OT';
  }

  Future<void> _approveParent() async {
    try {
      final userId = _parent['user_id'] ?? _parent['user']?['id'];
      if (userId == null) return;
      final response = await _api.approveUser(userId);
      if (response['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Akun orang tua berhasil disetujui.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal menyetujui akun.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        );
      }
    }
  }

  Future<void> _rejectParent() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Akun'),
        content: const Text('Apakah Anda yakin ingin menolak akun ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, 'rejected'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    if (reason == null) return;

    try {
      final userId = _parent['user_id'] ?? _parent['user']?['id'];
      if (userId == null) return;
      final response = await _api.rejectUser(userId, reason: reason);
      if (response['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Akun orang tua ditolak.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal menolak akun.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _getStatus();
    final isPending = status == 'pending';
    final children = _getChildren();
    final name = _getName();
    final initial = _getInitial();
    final statusColor = status == 'active'
        ? AppColors.success
        : status == 'pending'
            ? AppColors.warning
            : ThemeHelper.textMuted(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: isPending
            ? [
                TextButton(
                  onPressed: _approveParent,
                  child: const Text('Setujui', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                ),
                TextButton(
                  onPressed: _rejectParent,
                  child: const Text('Tolak', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: ThemeHelper.surface(context),
                borderRadius: AppRadius.xlAll,
                border: Border.all(color: ThemeHelper.border(context)),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLighter,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(name, style: AppTypography.h2.copyWith(color: ThemeHelper.text(context)), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(_getEmail(), style: AppTypography.bodySmall.copyWith(color: ThemeHelper.textSecondary(context)), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  AppWidgets.statusBadge(
                    status == 'active' ? 'Aktif' : status == 'pending' ? 'Menunggu' : status,
                    statusColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Account Info
            Container(
              width: double.infinity,
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
                  Text('Informasi Akun', style: AppTypography.h3.copyWith(color: ThemeHelper.text(context))),
                  const SizedBox(height: 16),
                  AppWidgets.infoRow('Nama', name),
                  AppWidgets.infoRow('Email', _getEmail()),
                  AppWidgets.infoRow('Nomor HP', _getPhone()),
                  AppWidgets.infoRow('Status', status == 'active' ? 'Aktif' : status == 'pending' ? 'Menunggu' : status),
                  AppWidgets.infoRow('Jumlah Anak', '${children.length}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Children List
            Container(
              width: double.infinity,
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
                  Text('Anak Terdaftar', style: AppTypography.h3.copyWith(color: ThemeHelper.text(context))),
                  const SizedBox(height: 14),
                  if (children.isEmpty)
                    AppWidgets.emptyState(
                      icon: Icons.child_care_outlined,
                      title: 'Belum ada anak terdaftar',
                    )
                  else
                    ...children.map<Widget>((child) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ThemeHelper.bgAlt(context),
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: Row(
                        children: [
                          ChildPhoto(child: child, width: 40, radius: 8),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  child['name'] ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${child['gender'] == 'male' ? 'Laki-laki' : 'Perempuan'} · ${child['birth_date'] ?? '-'}',
                                  style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context)),
                                ),
                              ],
                            ),
                          ),
                          AppWidgets.statusBadge(
                            child['status'] == 'active' ? 'Aktif' : 'Nonaktif',
                            child['status'] == 'active' ? AppColors.success : ThemeHelper.textMuted(context),
                          ),
                        ],
                      ),
                    )),
                ],
              ),
            ),

            // Action buttons for pending parents
            if (isPending) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _approveParent,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _rejectParent,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
