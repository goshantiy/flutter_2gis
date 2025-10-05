enum MarkerType { point, line }

class MarkerModel {
  final double latitude;
  final double longitude;
  final String title;
  final String description;
  final String date;
  final MarkerType type;
  final int? pointsCount; // Для линий
  final List<List<double>>? lineCoordinates; // Координаты линии [[lon, lat], [lon, lat], ...]

  MarkerModel({
    required this.latitude,
    required this.longitude,
    required this.title,
    this.description = '',
    this.date = '',
    required this.type,
    this.pointsCount,
    this.lineCoordinates,
  });

  factory MarkerModel.fromMap(Map<String, dynamic> map) {
    return MarkerModel(
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      date: map['date'] as String? ?? '',
      type: map['type'] == 'line' ? MarkerType.line : MarkerType.point,
      pointsCount: map['pointsCount'] as int?,
      lineCoordinates: map['lineCoordinates'] != null 
          ? List<List<double>>.from(map['lineCoordinates'].map((x) => List<double>.from(x)))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'title': title,
      'description': description,
      'date': date,
      'type': type == MarkerType.line ? 'line' : 'point',
      if (pointsCount != null) 'pointsCount': pointsCount,
      if (lineCoordinates != null) 'lineCoordinates': lineCoordinates,
    };
  }

  bool get hasDate => date.isNotEmpty;
  bool get isLine => type == MarkerType.line;
  bool get isPoint => type == MarkerType.point;
}