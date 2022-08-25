import 'dart:convert';

class Person {
  String email;
  String name;
  String photo;
  String token;
  String uid;
  
  Person({
    required this.email,
    required this.name,
    required this.photo,
    required this.token,
    required this.uid,
  });

  Person copyWith({
    String? email,
    String? name,
    String? photo,
    String? token,
    String? uid,
  }) {
    return Person(
      email: email ?? this.email,
      name: name ?? this.name,
      photo: photo ?? this.photo,
      token: token ?? this.token,
      uid: uid ?? this.uid,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
  
    result.addAll({'email': email});
    result.addAll({'name': name});
    result.addAll({'photo': photo});
    result.addAll({'token': token});
    result.addAll({'uid': uid});
  
    return result;
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photo: map['photo'] ?? '',
      token: map['token'] ?? '',
      uid: map['uid'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Person.fromJson(String source) => Person.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Person(email: $email, name: $name, photo: $photo, token: $token, uid: $uid)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Person &&
      other.email == email &&
      other.name == name &&
      other.photo == photo &&
      other.token == token &&
      other.uid == uid;
  }

  @override
  int get hashCode {
    return email.hashCode ^
      name.hashCode ^
      photo.hashCode ^
      token.hashCode ^
      uid.hashCode;
  }
}
