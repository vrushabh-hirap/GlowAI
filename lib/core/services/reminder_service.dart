import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/reminder_model.dart';
import '../mock/mock_data.dart';

// TODO(module: notifications) connect to flutter_local_notifications

abstract class ReminderService {
  List<ReminderModel> getReminders();
  void toggleReminder(String id);
  void addReminder(ReminderModel reminder);
  void deleteReminder(String id);
}

class FakeReminderService implements ReminderService {
  final List<ReminderModel> _reminders = List.from(MockData.sampleReminders);

  @override
  List<ReminderModel> getReminders() => List.unmodifiable(_reminders);

  @override
  void toggleReminder(String id) {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reminders[idx] = _reminders[idx].copyWith(enabled: !_reminders[idx].enabled);
    }
  }

  @override
  void addReminder(ReminderModel reminder) {
    _reminders.add(reminder);
  }

  @override
  void deleteReminder(String id) {
    _reminders.removeWhere((r) => r.id == id);
  }
}

class ReminderNotifier extends StateNotifier<List<ReminderModel>> {
  final FakeReminderService _service;
  ReminderNotifier(this._service) : super(_service.getReminders());

  void toggle(String id) {
    _service.toggleReminder(id);
    state = List.from(_service.getReminders());
  }

  void add(ReminderModel reminder) {
    _service.addReminder(reminder);
    state = List.from(_service.getReminders());
  }

  void delete(String id) {
    _service.deleteReminder(id);
    state = List.from(_service.getReminders());
  }
}

final reminderServiceProvider = Provider<ReminderService>((ref) => FakeReminderService());

final reminderProvider = StateNotifierProvider<ReminderNotifier, List<ReminderModel>>((ref) {
  final service = ref.watch(reminderServiceProvider) as FakeReminderService;
  return ReminderNotifier(service);
});
