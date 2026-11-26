import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/cached_resource.dart';
import '../services/parent_data_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/offline_banner.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> with ResourceBinding {
  final ApiService _api = ApiService();
  final ParentDataRepository _repo = ParentDataRepository();
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  int _rating = 5;

  /// Cache-first feedback list.
  late final CachedResource<List<dynamic>> _res;
  List<dynamic> get _feedbacks => _res.data ?? const [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _res = CachedResource<List<dynamic>>(onChanged: onResourceChanged);
    _loadFeedbacks();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedbacks() => _repo.loadFeedback(_res);

  /// Send feedback. Success is only reported after the backend confirmed it;
  /// an offline attempt tells the parent the message was NOT sent.
  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final response = await _repo.sendFeedback(
        subject: _subjectController.text,
        message: _messageController.text,
        rating: _rating,
      );
      if (!mounted) return;
      if (response['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Feedback berhasil dikirim!')),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        );
        _loadFeedbacks();
      } else {
        _showToast(
          response['message'] ?? tr('Gagal mengirim feedback.'),
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showToast(
        tr(ParentDataRepository.writeFailureMessage(e)),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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

  Future<void> _respondToFeedback(dynamic feedback) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Balas Feedback')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(feedback['subject'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: tr('Tulis balasan...'),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Batal'))),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(tr('Kirim')),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      final response = await _api.respondFeedback(feedback['id'], adminResponse: result);
      if (response['success'] == true) {
        _showToast(tr('Balasan berhasil dikirim.'));
        _loadFeedbacks();
      } else {
        _showToast(response['message'] ?? tr('Gagal mengirim balasan.'), isError: true);
      }
    } catch (e) {
      _showToast(tr('Gagal mengirim balasan.'), isError: true);
    }
  }

  Future<void> _updateStatus(dynamic feedback, String status) async {
    try {
      final response = await _api.updateFeedbackStatus(feedback['id'], status: status);
      if (response['success'] == true) {
        _showToast(tr('Status berhasil diperbarui.'));
        _loadFeedbacks();
      } else {
        _showToast(response['message'] ?? tr('Gagal memperbarui status.'), isError: true);
      }
    } catch (e) {
      _showToast(tr('Gagal memperbarui status.'), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(title: Text(tr('Feedback'))),
      floatingActionButton: !isAdmin ? FloatingActionButton(
        onPressed: _showFeedbackForm,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add),
      ) : null,
      body: Column(
        children: [
          OfflineBanner(resource: _res, onRetry: _loadFeedbacks),
          Expanded(
            child: _res.isLoading
                ? AppWidgets.loadingIndicator()
                : _res.error != null
                    ? AppWidgets.errorState(
                        message: tr(_res.error!),
                        onRetry: _loadFeedbacks,
                      )
                    : _feedbacks.isEmpty
                        ? AppWidgets.emptyState(
                            icon: Icons.rate_review_outlined,
                            title: tr('Belum ada feedback'),
                            subtitle: !isAdmin ? tr('Ketuk tombol + untuk mengirim feedback.') : null,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadFeedbacks,
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _feedbacks.length,
                              itemBuilder: (context, index) => _buildFeedbackCard(_feedbacks[index], isAdmin),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(dynamic feedback, bool isAdmin) {
    final status = feedback['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ThemeHelper.surface(context),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: ThemeHelper.border(context)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(feedback['subject'] ?? '-',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
                ),
                _buildRatingStars(feedback['rating'] ?? 5),
              ],
            ),
            const SizedBox(height: 10),
            Text(feedback['message'] ?? '',
                style: TextStyle(fontSize: 14, color: ThemeHelper.textSecondary(context), height: 1.5)),
            if (feedback['user'] != null || feedback['parent'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: ThemeHelper.textMuted(context)),
                  const SizedBox(width: 6),
                  Text(feedback['user']?['name'] ?? feedback['parent']?['user']?['name'] ?? '-',
                      style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context))),
                ],
              ),
            ],

            // Admin Response
            if (feedback['admin_response'] != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ThemeHelper.successBg(context),
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: ThemeHelper.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.reply, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(tr('Balasan Admin'),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(feedback['admin_response'],
                        style: TextStyle(fontSize: 13, color: ThemeHelper.textSecondary(context))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: ThemeHelper.textMuted(context)),
                const SizedBox(width: 6),
                Text(feedback['created_at'] ?? '-', style: AppTypography.caption.copyWith(color: ThemeHelper.textMuted(context))),
                const Spacer(),
                AppWidgets.statusBadge(statusLabel, statusColor),
              ],
            ),

            // Admin actions
            if (isAdmin) ...[
              const SizedBox(height: 12),
              Divider(color: ThemeHelper.border(context)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _respondToFeedback(feedback),
                      icon: const Icon(Icons.reply, size: 16),
                      label: Text(tr('Balas'), style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: ThemeHelper.border(context)),
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tr('Status'), style: TextStyle(fontSize: 12, color: ThemeHelper.textSecondary(context))),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, size: 16),
                        ],
                      ),
                    ),
                    onSelected: (value) => _updateStatus(feedback, value),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'pending', child: Text(tr('Menunggu'))),
                      PopupMenuItem(value: 'reviewed', child: Text(tr('Ditinjau'))),
                      PopupMenuItem(value: 'responded', child: Text(tr('Dibalas'))),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(index < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 16);
      }),
    );
  }

  void _showFeedbackForm() {
    _subjectController.clear();
    _messageController.clear();
    _rating = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4,
                          decoration: BoxDecoration(color: ThemeHelper.border(context), borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 20),
                      Text(tr('Kirim Feedback'), style: AppTypography.h2.copyWith(color: ThemeHelper.text(context))),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _subjectController,
                        decoration: InputDecoration(labelText: tr('Subjek')),
                        validator: (v) => v == null || v.isEmpty ? tr('Subjek harus diisi') : null,
                      ),
                      const SizedBox(height: 16),
                      Text(tr('Rating'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ThemeHelper.text(context))),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () => setModalState(() => _rating = index + 1),
                            child: Icon(index < _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 4,
                        decoration: InputDecoration(labelText: tr('Pesan'), alignLabelWithHint: true),
                        validator: (v) => v == null || v.isEmpty ? tr('Pesan harus diisi') : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitFeedback,
                          child: _isSubmitting
                              ? const SizedBox(height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(tr('Kirim')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'responded': return AppColors.success;
      case 'reviewed': return AppColors.info;
      case 'pending': return AppColors.warning;
      default: return ThemeHelper.textMuted(context);
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'responded': return tr('Dibalas');
      case 'reviewed': return tr('Ditinjau');
      case 'pending': return tr('Menunggu');
      default: return status ?? '-';
    }
  }
}
