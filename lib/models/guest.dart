import 'package:flutter/foundation.dart' show immutable;

const String guestTable = 'guests';

class GuestFields {
  static final List<String> values = [
    id,
    partyId,
    name,
    email,
  ];

  // Column names for Guest tables
  static const id = 'id';
  static const partyId = 'party_id';
  static const name = 'name';
  static const email = 'email';
}

@immutable
class Guest {
  final int? id;
  final int? partyId;
  final String name;
  final String email;

  const Guest({
    this.id,
    this.partyId,
    required this.name,
    required this.email,
  });

  set id(int? value) {
    id = value;
  }

  Guest copy({
    int? id,
    int? partyId,
    String? name,
    String? email,
  }) =>
      Guest(
        id: id ?? this.id,
        partyId: partyId ?? this.partyId,
        name: name ?? this.name,
        email: email ?? this.email,
      );

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      GuestFields.id: id,
      GuestFields.partyId: partyId,
      GuestFields.name: name,
      GuestFields.email: email,
    };
  }


  factory Guest.fromMap(Map<String, dynamic> map) {
    return Guest(
      id: map[GuestFields.id] != null ? map[GuestFields.id] as int : null,
      partyId: map[GuestFields.partyId] as int,
      name: map[GuestFields.name] as String,
      email: map[GuestFields.email] as String,
    );
  }
}
