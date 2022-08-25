import 'dart:convert';

class Chat {
  int lastDateTime;
  bool isRead;
  String message;
  String type;
  String uidReceiver;
  String uidSender;
  Chat({
    required this.lastDateTime,
    required this.isRead,
    required this.message,
    required this.type,
    required this.uidReceiver,
    required this.uidSender,
  });

  Chat copyWith({
    int? lastDateTime,
    bool? isRead,
    String? message,
    String? type,
    String? uidReceiver,
    String? uidSender,
  }) {
    return Chat(
      lastDateTime: lastDateTime ?? this.lastDateTime,
      isRead: isRead ?? this.isRead,
      message: message ?? this.message,
      type: type ?? this.type,
      uidReceiver: uidReceiver ?? this.uidReceiver,
      uidSender: uidSender ?? this.uidSender,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
  
    result.addAll({'lastDateTime': lastDateTime});
    result.addAll({'isRead': isRead});
    result.addAll({'message': message});
    result.addAll({'type': type});
    result.addAll({'uidReceiver': uidReceiver});
    result.addAll({'uidSender': uidSender});
  
    return result;
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      lastDateTime: map['lastDateTime']?.toInt() ?? 0,
      isRead: map['isRead'] ?? false,
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      uidReceiver: map['uidReceiver'] ?? '',
      uidSender: map['uidSender'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Chat.fromJson(String source) => Chat.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Chat(lastDateTime: $lastDateTime, isRead: $isRead, message: $message, type: $type, uidReceiver: $uidReceiver, uidSender: $uidSender)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Chat &&
      other.lastDateTime == lastDateTime &&
      other.isRead == isRead &&
      other.message == message &&
      other.type == type &&
      other.uidReceiver == uidReceiver &&
      other.uidSender == uidSender;
  }

  @override
  int get hashCode {
    return lastDateTime.hashCode ^
      isRead.hashCode ^
      message.hashCode ^
      type.hashCode ^
      uidReceiver.hashCode ^
      uidSender.hashCode;
  }
}
