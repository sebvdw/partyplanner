import 'package:flutter/foundation.dart' show immutable;

const String partyTable = 'parties';

class PartyFields {
  static final List<String> values = [
    id,
    title,
    description,
    date,
  ];

  // Column names for Party tables
  static const id = 'id';
  static const title = 'title';
  static const description = 'description';
  static const date = 'date';
}

@immutable
class Party {
  final int? id;
  final String title;
  final String description;
  final DateTime date;

  const Party({
    this.id,
    required this.title,
    required this.description,
    required this.date,
  });

  Party copy({
    int? id,
    String? title,
    String? description,
    DateTime? date,
    bool? isCompleted,
  }) =>
      Party(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        date: date ?? this.date,
      );

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      PartyFields.id: id,
      PartyFields.title: title,
      PartyFields.description: description,
      PartyFields.date: date.toIso8601String(),
    };
  }

  factory Party.fromMap(Map<String, dynamic> map) {
    return Party(
      id: map[PartyFields.id] != null ? map[PartyFields.id] as int : null,
      title: map[PartyFields.title] as String,
      description: map[PartyFields.description] as String,
      date: DateTime.parse(map[PartyFields.date] as String),
    );
  }
}
