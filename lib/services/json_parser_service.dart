import 'dart:convert';
import '../models/marker_model.dart';

class JsonParserService {
  static List<MarkerModel> parseEventsJson(String jsonString) {
    final List<MarkerModel> markers = [];
    
    try {
      final jsonData = jsonDecode(jsonString);
      
      if (jsonData.containsKey('events')) {
        final events = jsonData['events'] as List;
        
        for (final eventData in events) {
          markers.addAll(_parseEvent(eventData));
        }
      } else if (jsonData['type'] == 'FeatureCollection') {
        markers.addAll(_parseGeoJson(jsonData));
      }
    } catch (e) {
      rethrow;
    }
    
    return markers;
  }

  static List<MarkerModel> _parseEvent(Map<String, dynamic> eventData) {
    final List<MarkerModel> markers = [];
    
    final name = eventData['name'] ?? 'Событие';
    final description = eventData['description'] ?? '';
    
    // Обрабатываем дату
    String dateRange = '';
    if (eventData['date'] != null) {
      final dateData = eventData['date'];
      if (dateData is Map) {
        final start = dateData['start'] ?? '';
        final end = dateData['end'] ?? '';
        if (start.isNotEmpty && end.isNotEmpty) {
          dateRange = '$start - $end';
        } else if (start.isNotEmpty) {
          dateRange = start;
        }
      } else if (dateData is String) {
        dateRange = dateData;
      }
    }
    
    // Обрабатываем POI (точки интереса)
    if (eventData['POI'] != null) {
      final poiList = eventData['POI'] as List;
      for (int i = 0; i < poiList.length; i++) {
        final poi = poiList[i] as List;
        if (poi.length >= 2) {
          markers.add(MarkerModel(
            latitude: poi[1].toDouble(),
            longitude: poi[0].toDouble(),
            title: poiList.length > 1 ? '$name (POI ${i + 1})' : name,
            description: description,
            date: dateRange,
            type: MarkerType.point,
          ));
        }
      }
    }
    
    // Обрабатываем closures (перекрытия)
    if (eventData['closures'] != null) {
      final closuresList = eventData['closures'] as List;
      for (int i = 0; i < closuresList.length; i++) {
        final closure = closuresList[i] as Map<String, dynamic>;
        if (closure['type'] == 'LineString' && closure['coordinates'] != null) {
          final coordinates = closure['coordinates'] as List;
          if (coordinates.isNotEmpty) {
            final firstPoint = coordinates.first as List;
            markers.add(MarkerModel(
              latitude: firstPoint[1].toDouble(),
              longitude: firstPoint[0].toDouble(),
              title: closuresList.length > 1 
                  ? '$name (Перекрытие ${i + 1})' 
                  : '$name (Перекрытие)',
              description: 'Перекрытие дороги на время мероприятия',
              date: dateRange,
              type: MarkerType.line,
              pointsCount: coordinates.length,
              lineCoordinates: coordinates.map<List<double>>((coord) => 
                  [coord[0].toDouble(), coord[1].toDouble()]).toList(),
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