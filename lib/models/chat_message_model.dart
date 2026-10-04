import 'package:equatable/equatable.dart';

class ChatMessageModel extends Equatable {
  final String id;
  final String appointmentId;
  final String senderId;
  final String senderName;
  final bool isDoctor;
  final String text;
  final DateTime timestamp;

  const ChatMessageModel({
    required this.id,
    required this.appointmentId,
    required this.senderId,
    required this.senderName,
    required this.isDoctor,
    required this.text,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        id,
        appointmentId,
        senderId,
        senderName,
        isDoctor,
        text,
        timestamp,
      ];
}
