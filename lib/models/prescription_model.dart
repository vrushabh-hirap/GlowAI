import 'package:equatable/equatable.dart';
import 'medicine_model.dart';

class PrescriptionModel extends Equatable {
  final String id;
  final String appointmentId;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String patientId;
  final String patientName;
  final DateTime date;
  final String notes;
  final String followUpDate;
  final List<MedicineModel> medicines;
  final String disclaimer;

  const PrescriptionModel({
    required this.id,
    required this.appointmentId,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.patientId,
    required this.patientName,
    required this.date,
    required this.notes,
    required this.followUpDate,
    required this.medicines,
    this.disclaimer = 'Informational screening only. Not a medical diagnosis.',
  });

  @override
  List<Object?> get props => [
        id,
        appointmentId,
        doctorId,
        doctorName,
        doctorSpecialty,
        patientId,
        patientName,
        date,
        notes,
        followUpDate,
        medicines,
        disclaimer,
      ];
}
