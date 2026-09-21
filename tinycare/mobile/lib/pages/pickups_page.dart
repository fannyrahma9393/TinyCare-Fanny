import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

class PickupsPage extends StatefulWidget {
  const PickupsPage({super.key, required this.childId, required this.childName});

  final int childId;
  final String childName;

  @override
  State<PickupsPage> createState() => _PickupsPageState();
}

class _PickupsPageState extends State<PickupsPage> {
  final ApiService _api = ApiService();
  List<dynamic> _pickups = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final pickups = await _api.getAuthorizedPickups(widget.childId);
      setState(() {
        _pickups = pickups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = tr('Gagal memuat daftar penjemput.');
        _isLoading = false;
      });
    }
  }

  Future<void> _openForm({Map<String, dynamic>? pickup}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickupFormModal(
        childId: widget.childId,
        pickup: pickup,
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _toggleStatus(Map<String, dynamic> pickup) async {
    final next = pickup['status'] == 'active' ? 'inactive' : 'active';
    try {
      await _api.updateAuthorizedPickup(
        pickup['id'] as int,
        status: next,
      );
      if (!mounted) return;
      AppWidgets.showSnackBar(
        context,
        next == 'active' ? tr('Penjemput diaktifkan.') : tr('Penjemput dinonaktifkan.'),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      AppWidgets.showSnackBar(context, tr('Gagal memperbarui status.'), isError: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> pickup) async {
    final confirm = await AppWidgets.confirmDialog(
      context,
      title: tr('Hapus Penjemput'),
      content: 'Yakin ingin menghapus ${pickup['name'] ?? 'penjemput'} dari daftar penjemput yang diizinkan?',
      confirmLabel: tr('Hapus'),
      confirmColor: AppColors.error,
    );
    if (!confirm) return;

    try {
      await _api.deleteAuthorizedPickup(pickup['id'] as int);
      if (!mounted) return;
      AppWidgets.showSnackBar(context, tr('Penjemput berhasil dihapus.'));
      _load();
    } catch (e) {
      if (!mounted) return;
      AppWidgets.showSnackBar(context, tr('Gagal menghapus penjemput.'), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Penjemput'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: Text(tr('Tambah')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
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
                    _load();
                  },
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: _pickups.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            AppWidgets.emptyState(
                              icon: Icons.person_add_alt_outlined,
                              title: tr('Belum ada penjemput terdaftar'),
                              subtitle:
                                  tr('Tambahkan orang yang diizinkan menjemput {{name}}.',
                          {'name': widget.childName}),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: _pickups.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _buildPickupCard(_pickups[index]),
                        ),
                ),
    );
  }

  Widget _buildPickupCard(dynamic pickup) {
    final status = pickup['status'] ?? 'active';
    final active = status == 'active';
    final name = pickup['name'] as String? ?? '-';
    final relationship = pickup['relationship'] as String? ?? '';
    final phone = pickup['phone'] as String? ?? '';
    final idNumber = pickup['id_number'] as String?;
    final notes = pickup['notes'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.smAll,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ThemeHelper.text(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      relationship,
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeHelper.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
              AppWidgets.statusBadge(
                active ? tr('Aktif') : tr('Nonaktif'),
                active ? AppColors.success : AppColors.textMuted,
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _openForm(pickup: Map<String, dynamic>.from(pickup as Map));
                      break;
                    case 'toggle':
                      _toggleStatus(pickup);
                      break;
                    case 'delete':
                      _delete(pickup);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text(tr('Edit'))),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(active ? tr('Nonaktifkan') : tr('Aktifkan')),
                  ),
                  PopupMenuItem(value: 'delete', child: Text(tr('Hapus'))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppWidgets.infoRow(tr('Nomor HP'), phone.isEmpty ? '-' : phone),
          if (idNumber != null && idNumber.isNotEmpty)
            AppWidgets.infoRow(tr('No. Identitas'), idNumber),
          if (notes != null && notes.isNotEmpty)
            AppWidgets.infoRow(tr('Catatan'), notes),
        ],
      ),
    );
  }
}

class _PickupFormModal extends StatefulWidget {
  const _PickupFormModal({required this.childId, this.pickup});

  final int childId;
  final Map<String, dynamic>? pickup;

  @override
  State<_PickupFormModal> createState() => _PickupFormModalState();
}

class _PickupFormModalState extends State<_PickupFormModal> {
  static const _relationships = ['ayah', 'ibu', 'paman', 'bibi', 'kakek', 'nenek', 'lainnya'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _idNumberController;
  late final TextEditingController _notesController;
  late String _relationship;
  bool _isSubmitting = false;
  String? _error;

  bool get _isEdit => widget.pickup != null;

  @override
  void initState() {
    super.initState();
    final p = widget.pickup;
    _nameController = TextEditingController(text: '${p?['name'] ?? ''}');
    _phoneController = TextEditingController(text: '${p?['phone'] ?? ''}');
    _idNumberController = TextEditingController(text: '${p?['id_number'] ?? ''}');
    _notesController = TextEditingController(text: '${p?['notes'] ?? ''}');
    _relationship = _relationships.contains(p?['relationship'])
        ? p!['relationship'] as String
        : _relationships.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final api = ApiService();
      final String? idNumber = _idNumberController.text.trim().isEmpty
          ? null
          : _idNumberController.text.trim();
      final String? notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      final response = _isEdit
          ? await api.updateAuthorizedPickup(
              widget.pickup!['id'] as int,
              name: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              relationship: _relationship,
              idNumber: idNumber,
              notes: notes,
            )
          : await api.storeAuthorizedPickup(
              widget.childId,
              name: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              relationship: _relationship,
              idNumber: idNumber,
              notes: notes,
            );

      if (response['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = response['message'] ?? tr('Gagal menyimpan. Silakan coba lagi.');
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = tr('Tidak dapat terhubung ke server. Silakan coba lagi.');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ThemeHelper.surface(context),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isEdit ? tr('Edit Penjemput') : tr('Tambah Penjemput'),
                  style: AppTypography.h2.copyWith(color: ThemeHelper.text(context)),
                ),
                const SizedBox(height: 6),
                Text(
                  tr('Orang yang diizinkan menjemput anak Anda.'),
                  style: AppTypography.caption.copyWith(
                    color: ThemeHelper.textMuted(context),
                  ),
                ),
                const SizedBox(height: 20),

                if (_error != null) ...[
                  AppWidgets.errorAlert(_error!),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: tr('Nama Lengkap *')),
                  validator: (v) => v == null || v.isEmpty ? tr('Nama tidak boleh kosong') : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _relationship,
                  decoration: InputDecoration(labelText: tr('Hubungan *')),
                  items: _relationships.map((r) {
                    return DropdownMenuItem(value: r, child: Text(r));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _relationship = v);
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: tr('Nomor HP *')),
                  validator: (v) => v == null || v.isEmpty ? tr('Nomor HP tidak boleh kosong') : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _idNumberController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: tr('No. Identitas')),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(labelText: tr('Catatan')),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(tr('Simpan'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}