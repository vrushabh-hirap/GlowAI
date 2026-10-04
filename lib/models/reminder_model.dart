import 'package:equatable/equatable.dart';

class ReminderModel extends Equatable {
  final String id;
  final String type; // Skincare, Medicine, Appointment, Hydration
  final String title;
  final String time;
  final String repeat; // Daily, Weekdays, Custom
  final bool enabled;

  const ReminderModel({
    required this.id,
    required this.type,
    required this.title,
    required this.time,
    this.repeat = 'Daily',
    this.enabled = true,
  });

  ReminderModel copyWith({
    String? id,
    String? type,
    String? title,
    String? time,
    String? repeat,
    bool? enabled,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      time: time ?? this.time,
      repeat: repeat ?? this.repeat,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  List<Object?> get props => [id, type, title, time, repeat, enabled];
}
