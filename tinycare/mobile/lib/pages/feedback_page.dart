import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  int _rating = 5;
  List<dynamic> _feedbacks = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedbacks() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _api.getFeedback();
      setState(() { _feedbacks = data; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Gagal memuat feedback.'; _isLoading = false; });
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await _api.submitFeedback(
        subject: _subjectController.text,
        message: _messageController.text,
        rating: _rating,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Feedback berhasil dikirim!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        );
        _loadFeedbacks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal mengirim feedback.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
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
        title: const Text('Balas Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(feedback['subject'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Tulis balasan...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      final response = await _api.respondFeedback(feedback['id'], adminResponse: result);
      if (response['success'] == true) {
        _showToast('Balasan berhasil dikirim.');
        _loadFeedbacks();
      } else {
        _showToast(response['message'] ?? 'Gagal mengirim balasan.', isError: true);
      }
    } catch (e) {
      _showToast('Gagal mengirim balasan.', isError: true);
    }
  }

  Future<void> _updateStatus(dynamic feedback, String status) async {
    try {
      final response = await _api.updateFeedbackStatus(feedback['id'], status: status);
      if (response['success'] == true) {
        _showToast('Status berhasil diperbarui.');
        _loadFeedbacks();
      } else {
        _showToast(response['message'] ?? 'Gagal memperbarui status.', isError: true);
      }
    } catch (e) {
      _showToast('Gagal memperbarui status.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Feedback')),
      floatingActionButton: !isAdmin ? FloatingActionButton(
        onPressed: _showFeedbackForm,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add),
      ) : null,
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(message: _error!, onRetry: _loadFeedbacks)
              : _feedbacks.isEmpty
                  ? AppWidgets.emptyState(
                      icon: Icons.rate_review_outlined,
                      title: 'Belum ada feedback',
                      subtitle: !isAdmin ? 'Ketuk tombol + untuk mengirim feedback.' : null,
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
    );
  }

  Widget _buildFeedbackCard(dynamic feedback, bool isAdmin) {
    final status = feedback['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
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
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
                ),
                _buildRatingStars(feedback['rating'] ?? 5),
              ],
            ),
            const SizedBox(height: 10),
            Text(feedback['message'] ?? '',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
            if (feedback['user'] != null || feedback['parent'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(feedback['user']?['name'] ?? feedback['parent']?['user']?['name'] ?? '-',
                      style: AppTypography.caption),
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
                  color: AppColors.primarySubtle,
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: AppColors.primaryLighter),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.reply, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        const Text('Balasan Admin',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(feedback['admin_response'],
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(feedback['created_at'] ?? '-', style: AppTypography.caption),
                const Spacer(),
                AppWidgets.statusBadge(statusLabel, statusColor),
              ],
            ),

            // Admin actions
            if (isAdmin) ...[
              const SizedBox(height: 12),
              const Divider(color: AppColors.border),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _respondToFeedback(feedback),
                      icon: const Icon(Icons.reply, size: 16),
                      label: const Text('Balas', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Status', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, size: 16),
                        ],
                      ),
                    ),
                    onSelected: (value) => _updateStatus(feedback, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'pending', child: Text('Menunggu')),
                      const PopupMenuItem(value: 'reviewed', child: Text('Ditinjau')),
                      const PopupMenuItem(value: 'responded', child: Text('Dibalas')),
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
                          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 20),
                      const Text('Kirim Feedback', style: AppTypography.h2),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(labelText: 'Subjek'),
                        validator: (v) => v == null || v.isEmpty ? 'Subjek harus diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Rating', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
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
                        decoration: const InputDecoration(labelText: 'Pesan', alignLabelWithHint: true),
                        validator: (v) => v == null || v.isEmpty ? 'Pesan harus diisi' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitFeedback,
                          child: _isSubmitting
                              ? const SizedBox(height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Kirim'),
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
      default: return AppColors.textMuted;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'responded': return 'Dibalas';
      case 'reviewed': return 'Ditinjau';
      case 'pending': return 'Menunggu';
      default: return status ?? '-';
    }
  }
}
