// lib/features/prescription/prescriptions_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/care_repositories.dart';
import '../../core/theme/app_colors.dart';
import '../../models/care_models.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/tappable.dart';
import 'add_prescription_sheet.dart';
import 'prescription_detail_screen.dart';

class PrescriptionsListScreen extends ConsumerStatefulWidget {
  const PrescriptionsListScreen({super.key});

  @override
  ConsumerState<PrescriptionsListScreen> createState() => _PrescriptionsListScreenState();
}

class _PrescriptionsListScreenState extends ConsumerState<PrescriptionsListScreen> {
  bool _isLoading = true;
  List<PatientPrescription> _prescriptions = [];

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _isLoading = true);
    final repo = ref.read(prescriptionRepositoryProvider);
    final list = await repo.getAllPrescriptions();
    if (mounted) {
      setState(() {
        _prescriptions = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        title: 'My Prescriptions',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryDark),
            onPressed: () => AddPrescriptionSheet.show(context).then((_) => _loadPrescriptions()),
            tooltip: 'Add Prescription',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prescriptions.isEmpty
              ? EmptyState(
                  icon: Icons.description_outlined,
                  title: 'No Digital Prescriptions',
                  description: 'Add your doctor prescriptions or receive them directly from dermatologists.',
                  actionLabel: 'Add Prescription',
                  onAction: () => AddPrescriptionSheet.show(context).then((_) => _loadPrescriptions()),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _prescriptions.length,
                  itemBuilder: (context, index) {
                    final rx = _prescriptions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Tappable(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PrescriptionDetailScreen(prescriptionId: rx.id),
                            ),
                          ).then((_) => _loadPrescriptions());
                        },
                        child: GlowCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    rx.doctorName,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'VERIFIED RX',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                                    ),
                                  ),
                                ],
                              ),
                              if (rx.clinicName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  rx.clinicName,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                'Medicines (${rx.medicines.length}): ${rx.medicines.map((m) => m.name).join(", ")}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Date: ${rx.dateStr}' + (rx.followUpDateStr.isNotEmpty ? ' · Follow-up: ${rx.followUpDateStr}' : ''),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => AddPrescriptionSheet.show(context).then((_) => _loadPrescriptions()),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Rx', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
