class EventModel {
  final String name;
  final String description;
  final EventDate? date;
  final List<List<double>> poi;
  final List<EventClosure> closures;
  final List<EventDay>? days;

  EventModel({
    required this.name,
    this.description = '',
    this.date,
    this.poi = const [],
    this.closures = const [],
    this.days,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      name: json['name'] ?? 'Событие',
      description: json['description'] ?? '',
      date: json['date'] != null ? EventDate.fromJson(json['date']) : null,
      poi: (json['POI'] as List?)
              ?.cast<List<dynamic>>()
              .map((p) => p.cast<double>())
              .toList() ??
          [],
      closures: (json['closures'] as List?)
              ?.map((c) => EventClosure.fromJson(c))
              .toList() ??
          [],
      days: (json['days'] as List?)?.map((d) => EventDay.fromJson(d)).toList(),
    );
  }
}

class EventDate {
  final String start;
  final String end;

  EventDate({required this.start, this.end = ''});

  factory EventDate.fromJson(Map<String, dynamic> json) {
    return EventDate(
      start: json['start'] ?? '',
      end: json['end'] ?? '',
    );
  }

  String get displayString {
    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start - $end';
    } else if (start.isNotEmpty) {
      return start;
    }
    return '';
  }
}

class EventClosure {
  final String type;
  final List<List<double>> coordinates;

  EventClosure({required this.type, required this.coordinates});

  factory EventClosure.fromJson(Map<String, dynamic> json) {
    return EventClosure(
      type: json['type'] ?? '',
      coordinates: (json['coordinates'] as List?)
              ?.cast<List<dynamic>>()
              .map((coord) => coord.cast<double>())
              .toList() ??
          [],
    );
  }
}

class EventDay {
  final String description;
  final EventDate? date;
  final List<List<double>> poi;
  final List<EventClosure> closures;

  EventDay({
    this.description = '',
    this.date,
    this.poi = const [],
    this.closures = const [],
  });

  factory EventDay.fromJson(Map<String, dynamic> json) {
    return EventDay(
      description: json['description'] ?? '',
      date: json['date'] != null ? EventDate.fromJson(json['date']) : null,
      poi: (json['POI'] as List?)
              ?.cast<List<dynamic>>()
              .map((p) => p.cast<double>())
              .toList() ??
          [],
      closures: (json['closures'] as List?)
              ?.map((c) => EventClosure.fromJson(c))
              .toList() ??
          [],
    );
  }
}
