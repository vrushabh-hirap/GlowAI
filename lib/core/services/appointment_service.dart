import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/appointment_model.dart';
import '../mock/mock_data.dart';

// TODO(module: consultation) connect to Hive appointment storage

abstract class AppointmentService {
  List<AppointmentModel> getAppointments();
  AppointmentModel bookAppointment({
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    required DateTime dateTime,
    required String timeSlot,
    required ConsultationMode mode,
  });
  void cancelAppointment(String id);
}

class FakeAppointmentService implements AppointmentService {
  final List<AppointmentModel> _appointments = List.from(MockData.initialAppointments);

  @override
  List<AppointmentModel> getAppointments() => List.unmodifiable(_appointments);

  @override
  AppointmentModel bookAppointment({
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    required DateTime dateTime,
    required String timeSlot,
    required ConsultationMode mode,
  }) {
    final newApp = AppointmentModel(
      id: 'app_${DateTime.now().millisecondsSinceEpoch}',
      patientId: MockData.patientUser.id,
      patientName: MockData.patientUser.name,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      dateTime: dateTime,
      timeSlot: timeSlot,
      mode: mode,
      status: AppointmentStatus.booked,
      scanId: '',
      jitsiRoom: 'https://meet.jit.si/GlowAI-app_${DateTime.now().millisecondsSinceEpoch}',
    );
    _appointments.insert(0, newApp);
    return newApp;
  }

  @override
  void cancelAppointment(String id) {
    final index = _appointments.indexWhere((a) => a.id == id);
    if (index != -1) {
      _appointments[index] = _appointments[index].copyWith(status: AppointmentStatus.cancelled);
    }
  }
}

class AppointmentNotifier extends StateNotifier<List<AppointmentModel>> {
  final FakeAppointmentService _service;
  AppointmentNotifier(this._service) : super(_service.getAppointments());

  void book({
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    required DateTime dateTime,
    required String timeSlot,
    required ConsultationMode mode,
  }) {
    _service.bookAppointment(
      doctorId: doctorId,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      dateTime: dateTime,
      timeSlot: timeSlot,
      mode: mode,
    );
    state = List.from(_service.getAppointments());
  }

  void cancel(String id) {
    _service.cancelAppointment(id);
    state = List.from(_service.getAppointments());
  }
}

final appointmentServiceProvider = Provider<AppointmentService>((ref) => FakeAppointmentService());

final appointmentProvider = StateNotifierProvider<AppointmentNotifier, List<AppointmentModel>>((ref) {
  final service = ref.watch(appointmentServiceProvider) as FakeAppointmentService;
  return AppointmentNotifier(service);
});
