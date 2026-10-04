// lib/features/prescription/prescription_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/repositories/care_repositories.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/care_models.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/soft_button.dart';

class PrescriptionDetailScreen extends ConsumerStatefulWidget {
  final String prescriptionId;

  const PrescriptionDetailScreen({super.key, required this.prescriptionId});

  @override
  ConsumerState<PrescriptionDetailScreen> createState() => _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends ConsumerState<PrescriptionDetailScreen> {
  bool _isLoading = true;
  PatientPrescription? _prescription;

  @override
  void initState() {
    super.initState();
    _loadPrescription();
  }

  Future<void> _loadPrescription() async {
    setState(() => _isLoading = true);
    final repo = ref.read(prescriptionRepositoryProvider);
    final rx = await repo.getPrescriptionById(widget.prescriptionId);
    if (mounted) {
      setState(() {
        _prescription = rx;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPdfAndShare() async {
    if (_prescription == null) return;
    final pdfService = ref.read(pdfServiceProvider);
    final profile = ref.read(userProfileProvider);

    final path = await pdfService.generatePrescriptionPdf(_prescription!, profile);
    await SharePlus.instance.share(ShareParams(files: [XFile(path)], text: 'Prescription from ${_prescription!.doctorName}'));
  }

  Future<void> _openPdf() async {
    if (_prescription == null) return;
    final pdfService = ref.read(pdfServiceProvider);
    final profile = ref.read(userProfileProvider);

    final path = await pdfService.generatePrescriptionPdf(_prescription!, profile);
    await OpenFilex.open(path);
  }

  Future<void> _scheduleMedicineReminders() async {
    if (_prescription == null) return;
    final reminderRepo = ref.read(reminderRepositoryProvider);
    final notifService = NotificationService();

    for (final med in _prescription!.medicines) {
      final rem = AppReminder(
        id: 'med_${med.id}',
        title: 'Medicine: ${med.name}',
        body: '${med.dose} (${med.form}) - ${med.instructions}',
        timeStr: '09:00',
        type: 'medicine',
        repeatDays: [1, 2, 3, 4, 5, 6, 7],
      );
      await reminderRepo.saveReminder(rem);
      await notifService.scheduleReminder(rem);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dose reminders scheduled successfully!')),
      );
    }
  }

  Future<void> _deletePrescription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Prescription?'),
        content: const Text('This will delete the prescription entry and linked dose reminders.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final repo = ref.read(prescriptionRepositoryProvider);
      await repo.deletePrescription(widget.prescriptionId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        appBar: AppHeader(title: 'Prescription Detail'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_prescription == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: const AppHeader(title: 'Prescription Detail'),
        body: const Center(child: Text('Prescription not found.')),
      );
    }

    final rx = _prescription!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        title: 'Prescription #${rx.id.substring(0, 6)}',
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.primaryDark),
            onPressed: _exportPdfAndShare,
            tooltip: 'Share PDF',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            onPressed: _deletePrescription,
            tooltip: 'Delete Prescription',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor & Clinic Header Card
            GlowCard(
              hasGlow: true,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        rx.doctorName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Text('GlowAI Rx', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ],
                  ),
                  if (rx.clinicName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(rx.clinicName, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rx Date: ${rx.dateStr}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      if (rx.followUpDateStr.isNotEmpty)
                        Text('Follow-up: ${rx.followUpDateStr}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Doctor's Diagnosis & Notes
            if (rx.diagnosis.isNotEmpty) ...[
              const Text(
                'Doctor\'s Diagnosis & Notes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              GlowCard(
                padding: const EdgeInsets.all(14),
                child: Text(
                  rx.diagnosis,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Prescribed Medicines List
            const Text(
              'Prescribed Medicines',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            ...rx.medicines.map((med) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlowCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${med.name} (${med.form})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              'Dose: ${med.dose} · ${med.frequency} (${med.durationDays} days)',
                              style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                            ),
                            if (med.instructions.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(med.instructions, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Create Medicine Reminders Chip / Button
            GlowCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: AppColors.primaryDark),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dose Reminders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text('Schedule daily notification reminders for these medicines', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _scheduleMedicineReminders,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    child: const Text('Schedule', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Prescription Attachments if present
            if (rx.attachmentPaths.isNotEmpty) ...[
              const Text(
                'Attachments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: rx.attachmentPaths.map((path) {
                  final isPdf = path.endsWith('.pdf');
                  return GestureDetector(
                    onTap: () {
                      if (isPdf) {
                        OpenFilex.open(path);
                      } else {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(child: Image.file(File(path))),
                        );
                      }
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: isPdf
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                                SizedBox(height: 4),
                                Text('View PDF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(path), fit: BoxFit.cover),
                            ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Legal Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'DISCLAIMER: Always follow your doctor\'s direct instructions. GlowAI provides general guidance and does not alter doctor prescriptions.',
                style: TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            GlowButton(
              label: 'View / Open PDF Document',
              icon: Icons.picture_as_pdf_rounded,
              onPressed: _openPdf,
            ),
            const SizedBox(height: 12),
            SoftButton(
              label: 'Find Nearby Pharmacies',
              icon: Icons.local_pharmacy_rounded,
              width: double.infinity,
              height: 50,
              onPressed: () => context.push('/stores'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
