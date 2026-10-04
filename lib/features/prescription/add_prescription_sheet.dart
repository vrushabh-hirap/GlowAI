// lib/features/prescription/add_prescription_sheet.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/repositories/care_repositories.dart';
import '../../core/theme/app_colors.dart';
import '../../models/care_models.dart';
import '../../shared/widgets/glow_button.dart';

class AddPrescriptionSheet extends ConsumerStatefulWidget {
  const AddPrescriptionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddPrescriptionSheet(),
    );
  }

  @override
  ConsumerState<AddPrescriptionSheet> createState() => _AddPrescriptionSheetState();
}

class _AddPrescriptionSheetState extends ConsumerState<AddPrescriptionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _doctorController = TextEditingController();
  final _clinicController = TextEditingController();
  final _notesController = TextEditingController();
  final _followUpController = TextEditingController();

  final List<MedicineItem> _medicines = [];
  final List<String> _attachmentPaths = [];

  @override
  void dispose() {
    _doctorController.dispose();
    _clinicController.dispose();
    _notesController.dispose();
    _followUpController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _attachmentPaths.add(image.path));
    }
  }

  Future<void> _pickPdf() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (files.isNotEmpty && files.first.path != null) {
      setState(() => _attachmentPaths.add(files.first.path!));
    }
  }

  void _addMedicineDialog() {
    final medNameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    final freqCtrl = TextEditingController(text: 'Twice daily');
    final durCtrl = TextEditingController(text: '7');
    final instCtrl = TextEditingController(text: 'After food');
    String form = 'Tablet';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Medicine Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: medNameCtrl,
                decoration: const InputDecoration(labelText: 'Medicine Name (e.g. Cetirizine)'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: form,
                decoration: const InputDecoration(labelText: 'Form'),
                items: ['Tablet', 'Cream', 'Gel', 'Lotion', 'Syrup', 'Capsule'].map((f) {
                  return DropdownMenuItem(value: f, child: Text(f));
                }).toList(),
                onChanged: (val) {
                  if (val != null) form = val;
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: doseCtrl,
                decoration: const InputDecoration(labelText: 'Dose / Strength (e.g. 10mg / 1 drop)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: freqCtrl,
                decoration: const InputDecoration(labelText: 'Frequency (e.g. Twice daily / AM & PM)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: durCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duration (Days)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: instCtrl,
                decoration: const InputDecoration(labelText: 'Instructions (e.g. Apply thin layer)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (medNameCtrl.text.trim().isEmpty) return;
              setState(() {
                _medicines.add(
                  MedicineItem(
                    id: const Uuid().v4(),
                    name: medNameCtrl.text.trim(),
                    strength: doseCtrl.text.trim(),
                    form: form,
                    dose: doseCtrl.text.trim(),
                    frequency: freqCtrl.text.trim(),
                    scheduledTimes: const ['09:00', '21:00'],
                    durationDays: int.tryParse(durCtrl.text.trim()) ?? 7,
                    instructions: instCtrl.text.trim(),
                  ),
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medicine item')),
      );
      return;
    }

    final rx = PatientPrescription(
      id: const Uuid().v4(),
      doctorName: _doctorController.text.trim(),
      clinicName: _clinicController.text.trim(),
      dateStr: DateTime.now().toIso8601String().substring(0, 10),
      diagnosis: _notesController.text.trim(),
      followUpDateStr: _followUpController.text.trim(),
      attachmentPaths: _attachmentPaths,
      medicines: _medicines,
    );

    final rxRepo = ref.read(prescriptionRepositoryProvider);
    await rxRepo.savePrescription(rx);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add New Prescription', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _doctorController,
                      decoration: const InputDecoration(
                        labelText: 'Doctor Name *',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _clinicController,
                      decoration: const InputDecoration(
                        labelText: 'Clinic / Hospital Name',
                        prefixIcon: Icon(Icons.local_hospital_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Diagnosis & Doctor Notes',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _followUpController,
                      decoration: const InputDecoration(
                        labelText: 'Follow-up Date (e.g. YYYY-MM-DD)',
                        prefixIcon: Icon(Icons.event_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Medicines Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Medicines List *', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _addMedicineDialog,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Medicine'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    if (_medicines.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Text('No medicines added yet. Tap "Add Medicine" above.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      )
                    else
                      ..._medicines.map((m) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.medication_rounded, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${m.name} (${m.form})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('${m.dose} · ${m.frequency} · ${m.durationDays}d', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 18),
                                onPressed: () => setState(() => _medicines.remove(m)),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 20),

                    // Attachments Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Paper Prescription Attachments', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                              onPressed: _pickAttachment,
                              tooltip: 'Attach Image',
                            ),
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
                              onPressed: _pickPdf,
                              tooltip: 'Attach PDF',
                            ),
                          ],
                        ),
                      ],
                    ),

                    if (_attachmentPaths.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: _attachmentPaths.map((path) {
                          return Chip(
                            avatar: Icon(path.endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image, size: 16),
                            label: Text(path.split('/').last, style: const TextStyle(fontSize: 11)),
                            onDeleted: () => setState(() => _attachmentPaths.remove(path)),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: GlowButton(
              label: 'Save Prescription',
              icon: Icons.check_circle_outline_rounded,
              onPressed: _savePrescription,
            ),
          ),
        ],
      ),
    );
  }
}
