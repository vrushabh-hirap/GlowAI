import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/medicine_model.dart';
import '../../models/prescription_model.dart';
import '../mock/mock_data.dart';

// TODO(module: prescription) connect to Hive prescription box

abstract class PrescriptionService {
  List<PrescriptionModel> getPrescriptions();
  PrescriptionModel addPrescription({
    required String appointmentId,
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    required String patientId,
    required String patientName,
    required String notes,
    required String followUpDate,
    required List<MedicineModel> medicines,
  });
}

class FakePrescriptionService implements PrescriptionService {
  final List<PrescriptionModel> _prescriptions = List.from(MockData.initialPrescriptions);

  @override
  List<PrescriptionModel> getPrescriptions() => List.unmodifiable(_prescriptions);

  @override
  PrescriptionModel addPrescription({
    required String appointmentId,
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    required String patientId,
    required String patientName,
    required String notes,
    required String followUpDate,
    required List<MedicineModel> medicines,
  }) {
    final rx = PrescriptionModel(
      id: 'rx_${DateTime.now().millisecondsSinceEpoch}',
      appointmentId: appointmentId,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      patientId: patientId,
      patientName: patientName,
      date: DateTime.now(),
      notes: notes,
      followUpDate: followUpDate,
      medicines: medicines,
    );
    _prescriptions.insert(0, rx);
    return rx;
  }
}

class PrescriptionNotifier extends StateNotifier<List<PrescriptionModel>> {
  final FakePrescriptionService _service;
  PrescriptionNotifier(this._service) : super(_service.getPrescriptions());

  void add({
    required String appointmentId,
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    required String patientId,
    required String patientName,
    required String notes,
    required String followUpDate,
    required List<MedicineModel> medicines,
  }) {
    _service.addPrescription(
      appointmentId: appointmentId,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      patientId: patientId,
      patientName: patientName,
      notes: notes,
      followUpDate: followUpDate,
      medicines: medicines,
    );
    state = List.from(_service.getPrescriptions());
  }
}

final prescriptionServiceProvider = Provider<PrescriptionService>((ref) => FakePrescriptionService());

final prescriptionProvider = StateNotifierProvider<PrescriptionNotifier, List<PrescriptionModel>>((ref) {
  final service = ref.watch(prescriptionServiceProvider) as FakePrescriptionService;
  return PrescriptionNotifier(service);
});
