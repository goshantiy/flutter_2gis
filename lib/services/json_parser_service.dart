import 'dart:convert';
import '../models/event_model.dart';
import '../models/marker_model.dart';

class JsonParserService {
  static List<MarkerModel> parseEventsJson(String jsonString) {
    final List<MarkerModel> markers = [];
    
    try {
      final jsonData = jsonDecode(jsonString);
      
      if (jsonData.containsKey('events')) {
        final events = (jsonData['events'] as List)
            .map((e) => EventModel.fromJson(e))
            .toList();
        
        for (final event in events) {
          markers.addAll(_parseEvent(event));
        }
      } else if (jsonData['type'] == 'FeatureCollection') {
        markers.addAll(_parseGeoJson(jsonData));
      }
    } catch (e) {
      rethrow;
    }
    
    return markers;
  }

  static List<MarkerModel> _parseEvent(EventModel event) {
    final List<MarkerModel> markers = [];
    final dateRange = event.date?.displayString ?? '';
    
    // Обрабатываем POI (точки интереса)
    for (int i = 0; i < event.poi.length; i++) {
      final poi = event.poi[i];
      if (poi.length >= 2) {
        markers.add(MarkerModel(
          latitude: poi[1],
          longitude: poi[0],
          title: event.poi.length > 1 ? '${event.name} (POI ${i + 1})' : event.name,
          description: event.description,
          date: dateRange,
          type: MarkerType.point,
        ));
      }
    }
    
    // Обрабатываем closures (перекрытия)
    for (int i = 0; i < event.closures.length; i++) {
      final closure = event.closures[i];
      if (closure.type == 'LineString' && closure.coordinates.isNotEmpty) {
        final firstPoint = closure.coordinates.first;
        markers.add(MarkerModel(
          latitude: firstPoint[1],
          longitude: firstPoint[0],
          title: event.closures.length > 1 
              ? '${event.name} (Перекрытие ${i + 1})' 
              : '${event.name} (Перекрытие)',
          description: 'Перекрытие дороги на время мероприятия',
          date: dateRange,
          type: MarkerType.line,
          pointsCount: closure.coordinates.length,
          lineCoordinates: closure.coordinates.map<List<double>>((coord) => 
              [coord[0].toDouble(), coord[1].toDouble()]).toList(),
        ));
      }
    }
    
    // Обрабатываем days (дни события)
    if (event.days != null) {
      for (int dayIndex = 0; dayIndex < event.days!.length; dayIndex++) {
        final day = event.days![dayIndex];
        final dayDateRange = day.date?.displayString ?? '';
        
        // POI для конкретного дня
        for (int i = 0; i < day.poi.length; i++) {
          final poi = day.poi[i];
          if (poi.length >= 2) {
            markers.add(MarkerModel(
              latitude: poi[1],
              longitude: poi[0],
              title: '${event.name} (День ${dayIndex + 1})',
              description: day.description,
              date: dayDateRange,
              type: MarkerType.point,
            ));
          }
        }
      }
    }
    
    return markers;
  }

  static List<MarkerModel> _parseGeoJson(Map<String, dynamic> geoJsonData) {
    final List<MarkerModel> markers = [];
    final features = geoJsonData['features'] as List;

    for (final feature in features) {
      final geometryType = feature['geometry']['type'];
      final properties = feature['properties'] as Map<String, dynamic>;

      final title = _getPropertyValue(properties, ['name', 'назва', 'title', 'Name', 'ST_NAME']) ?? '';
      final description = _getPropertyValue(properties, ['description', 'описа', 'desc', 'Description']) ?? '';
      final date = _getPropertyValue(properties, ['date', 'дата', 'время', 'time']) ?? '';
      
      String fullDescription = description;
      if (date.isNotEmpty) {
        fullDescription = fullDescription.isEmpty ? date : '$description\n📅 $date';
      }

      if (geometryType == 'Point') {
        final coordinates = feature['geometry']['coordinates'] as List;
        markers.add(MarkerModel(
          latitude: coordinates[1] as double,
          longitude: coordinates[0] as double,
          title: title.isEmpty ? 'Точка' : title,
          description: fullDescription,
          date: date,
          type: MarkerType.point,
        ));
      } else if (geometryType == 'LineString') {
        final coordinates = feature['geometry']['coordinates'] as List;
        if (coordinates.isNotEmpty) {
          final firstCoord = coordinates.first as List;
          markers.add(MarkerModel(
            latitude: firstCoord[1] as double,
            longitude: firstCoord[0] as double,
            title: title.isEmpty ? 'Линия' : title,
            description: fullDescription,
            date: date,
            type: MarkerType.line,
            pointsCount: coordinates.length,
            lineCoordinates: coordinates.map<List<double>>((coord) => 
                [coord[0].toDouble(), coord[1].toDouble()]).toList(),
          ));
        }
      }
    }
    
    return markers;
  }

  static String? _getPropertyValue(Map<String, dynamic> properties, List<String> keys) {
    for (String key in keys) {
      if (properties.containsKey(key) && properties[key] != null) {
        return properties[key].toString();
      }
    }
    return null;
  }
}