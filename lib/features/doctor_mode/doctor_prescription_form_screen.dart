import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medicine_model.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';

class DoctorPrescriptionFormScreen extends StatefulWidget {
  final String appointmentId;

  const DoctorPrescriptionFormScreen({super.key, required this.appointmentId});

  @override
  State<DoctorPrescriptionFormScreen> createState() => _DoctorPrescriptionFormScreenState();
}

class _DoctorPrescriptionFormScreenState extends State<DoctorPrescriptionFormScreen> {
  final _notesController = TextEditingController(
    text: 'Patient shows mild inflammatory acne. Prescribed topical clindamycin gel and niacinamide serum.',
  );
  final _followUpController = TextEditingController(text: '2 Weeks (Oct 18, 2026)');

  final List<MedicineModel> _selectedMedicines = [
    MockData.medicines[1], // Clindamycin
    MockData.medicines[2], // Niacinamide
  ];

  @override
  void dispose() {
    _notesController.dispose();
    _followUpController.dispose();
    super.dispose();
  }

  void _addMedicine(MedicineModel med) {
    if (!_selectedMedicines.contains(med)) {
      setState(() => _selectedMedicines.add(med));
    }
  }

  void _removeMedicine(MedicineModel med) {
    setState(() => _selectedMedicines.remove(med));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Write Prescription',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Header
            GlowCard(
              child: Row(
                children: const [
                  CircleAvatar(backgroundColor: AppColors.primarySoft, child: Icon(Icons.person, color: AppColors.primaryDark)),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Patient: Sophia Miller', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Age: 26 · Female', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Clinical Notes Field
            AppTextField(
              label: 'Doctor Notes & Diagnosis',
              hintText: 'Enter clinical observations and instructions...',
              controller: _notesController,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Selected Medicines Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Selected Medicines', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primaryDark),
                  label: const Text('Add Medicine', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: MockData.medicines.length,
                          itemBuilder: (context, idx) {
                            final m = MockData.medicines[idx];
                            return ListTile(
                              leading: Image.asset('assets/images/medicines/med_glycolic.png', width: 40, height: 40),
                              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(m.use),
                              onTap: () {
                                _addMedicine(m);
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._selectedMedicines.map((med) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlowCard(
                  child: Row(
                    children: [
                      Image.asset('assets/images/medicines/med_glycolic.png', width: 44, height: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('${med.dosage} · ${med.frequency}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                        onPressed: () => _removeMedicine(med),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Follow-up Date
            AppTextField(
              label: 'Follow-up Schedule',
              hintText: 'e.g. 2 Weeks (Oct 18, 2026)',
              controller: _followUpController,
            ),
            const SizedBox(height: 32),

            GlowButton(
              label: 'Preview Prescription Document',
              icon: Icons.preview_rounded,
              width: double.infinity,
              onPressed: () {
                context.push('/doctor/prescription-preview');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
