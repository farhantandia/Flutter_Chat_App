import 'dart:convert';

class Room {
  String email;
  bool inRoom;
  String lastChat;
  int lastDateTime;
  String lastUid;
  String name;
  String photo;
  String type;
  String uid;
  Room({
    required this.email,
    required this.inRoom,
    required this.lastChat,
    required this.lastDateTime,
    required this.lastUid,
    required this.name,
    required this.photo,
    required this.type,
    required this.uid,
  });

  Room copyWith({
    String? email,
    bool? inRoom,
    String? lastChat,
    int? lastDateTime,
    String? lastUid,
    String? name,
    String? photo,
    String? type,
    String? uid,
  }) {
    return Room(
      email: email ?? this.email,
      inRoom: inRoom ?? this.inRoom,
      lastChat: lastChat ?? this.lastChat,
      lastDateTime: lastDateTime ?? this.lastDateTime,
      lastUid: lastUid ?? this.lastUid,
      name: name ?? this.name,
      photo: photo ?? this.photo,
      type: type ?? this.type,
      uid: uid ?? this.uid,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
  
    result.addAll({'email': email});
    result.addAll({'inRoom': inRoom});
    result.addAll({'lastChat': lastChat});
    result.addAll({'lastDateTime': lastDateTime});
    result.addAll({'lastUid': lastUid});
    result.addAll({'name': name});
    result.addAll({'photo': photo});
    result.addAll({'type': type});
    result.addAll({'uid': uid});
  
    return result;
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      email: map['email'] ?? '',
      inRoom: map['inRoom'] ?? false,
      lastChat: map['lastChat'] ?? '',
      lastDateTime: map['lastDateTime']?.toInt() ?? 0,
      lastUid: map['lastUid'] ?? '',
      name: map['name'] ?? '',
      photo: map['photo'] ?? '',
      type: map['type'] ?? '',
      uid: map['uid'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

    factory Room.fromJson(Map<String, dynamic> json) => Room(
      email: json['email'] ?? '',
      inRoom: json['inRoom'] ?? false,
      lastChat: json['lastChat'] ?? '',
      lastDateTime: json['lastDateTime']?.toInt() ?? 0,
      lastUid: json['lastUid'] ?? '',
      name: json['name'] ?? '',
      photo: json['photo'] ?? '',
      type: json['type'] ?? '',
      uid: json['uid'] ?? '',
      );

  @override
  String toString() {
    return 'Room(email: $email, inRoom: $inRoom, lastChat: $lastChat, lastDateTime: $lastDateTime, lastUid: $lastUid, name: $name, photo: $photo, type: $type, uid: $uid)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Room &&
      other.email == email &&
      other.inRoom == inRoom &&
      other.lastChat == lastChat &&
      other.lastDateTime == lastDateTime &&
      other.lastUid == lastUid &&
      other.name == name &&
      other.photo == photo &&
      other.type == type &&
      other.uid == uid;
  }

  @override
  int get hashCode {
    return email.hashCode ^
      inRoom.hashCode ^
      lastChat.hashCode ^
      lastDateTime.hashCode ^
      lastUid.hashCode ^
      name.hashCode ^
      photo.hashCode ^
      type.hashCode ^
      uid.hashCode;
  }
}
