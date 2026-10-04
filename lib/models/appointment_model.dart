import 'package:equatable/equatable.dart';

enum ConsultationMode { chat, voice, video }
enum AppointmentStatus { booked, completed, cancelled }

class AppointmentModel extends Equatable {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final DateTime dateTime;
  final String timeSlot;
  final ConsultationMode mode;
  final AppointmentStatus status;
  final String? scanId;
  final String jitsiRoom;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.dateTime,
    required this.timeSlot,
    required this.mode,
    required this.status,
    this.scanId,
    required this.jitsiRoom,
  });

  AppointmentModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialty,
    DateTime? dateTime,
    String? timeSlot,
    ConsultationMode? mode,
    AppointmentStatus? status,
    String? scanId,
    String? jitsiRoom,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      dateTime: dateTime ?? this.dateTime,
      timeSlot: timeSlot ?? this.timeSlot,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      scanId: scanId ?? this.scanId,
      jitsiRoom: jitsiRoom ?? this.jitsiRoom,
    );
  }

  @override
  List<Object?> get props => [
        id,
        patientId,
        patientName,
        doctorId,
        doctorName,
        doctorSpecialty,
        dateTime,
        timeSlot,
        mode,
        status,
        scanId,
        jitsiRoom,
      ];
}
