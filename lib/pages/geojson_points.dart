import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;

class GeoJsonPointsPage extends StatefulWidget {
  final sdk.Context? sdkContext;

  const GeoJsonPointsPage({super.key, this.sdkContext});

  @override
  State<GeoJsonPointsPage> createState() => _GeoJsonPointsPageState();
}

class _GeoJsonPointsPageState extends State<GeoJsonPointsPage> {
  final TextEditingController _geoJsonController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  List<Map<String, dynamic>> _markers = [];
  List<Map<String, dynamic>> _allMarkers = []; // Все маркеры без фильтрации
  bool _isLoading = false;
  bool _showMarkersList = false;
  bool _isInitialLoad = true;
  Set<String> _availableDates = {}; // Доступные даты для фильтрации
  String? _selectedDate; // Выбранная дата для фильтрации
  sdk.CameraPosition _cameraPosition = sdk.CameraPosition(
    point: sdk.GeoPoint(
      latitude: sdk.Latitude(55.7539),
      longitude: sdk.Longitude(37.6156),
    ),
    zoom: sdk.Zoom(11.0),
  );
  
  // Для работы с картой и маркерами
  final _mapWidgetController = sdk.MapWidgetController();
  sdk.MapObjectManager? _mapObjectManager;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _loadSampleGeoJson();
  }

  void _initializeMap() {
    if (widget.sdkContext != null) {
      _mapWidgetController.getMapAsync((map) {
        _mapObjectManager = sdk.MapObjectManager(map);
        debugPrint('MapObjectManager инициализирован');
      });
    }
  }

  void _loadSampleGeoJson() {
    // Пример GeoJSON с поддержкой точек и линий
    const sampleGeoJson = '''
{
  "type": "FeatureCollection",
  "name": "Мероприятия и перекрытия в Москве",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "назва": "Фестиваль \\"Спасская башня\\"",
        "описа": "Первый день фестиваля. Вечернее представление - церемония торжественного открытия",
        "дата": "22.08.2025 20:00-22:30"
      },
      "geometry": {
        "type": "Point",
        "coordinates": [37.620245338778268, 55.754154717527896]
      }
    },
    {
      "type": "Feature",
      "properties": {
        "ST_NAME": "Тверская улица",
        "описа": "Перекрытие дороги на время мероприятия",
        "дата": "22.08.2025"
      },
      "geometry": {
        "type": "LineString",
        "coordinates": [
          [37.6156, 55.7539],
          [37.6180, 55.7560],
          [37.6200, 55.7580]
        ]
      }
    },
    {
      "type": "Feature",
      "properties": {
        "name": "Парк Горького",
        "description": "Центральный парк культуры и отдыха",
        "date": "Ежедневно 06:00-24:00"
      },
      "geometry": {
        "type": "Point",
        "coordinates": [37.6017, 55.7312]
      }
    }
  ]
}''';
    _geoJsonController.text = sampleGeoJson;
  }

  Future<void> _loadGeoJsonFromFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        String content = '';
        
        // Пробуем получить содержимое файла разными способами
        if (file.bytes != null) {
          // Веб-платформа или файл загружен в память
          content = String.fromCharCodes(file.bytes!);
        } else if (file.path != null) {
          // Мобильные платформы - читаем по пути
          final fileContent = await File(file.path!).readAsString();
          content = fileContent;
        } else {
          throw Exception('Не удалось получить содержимое файла');
        }

        if (content.isNotEmpty) {
          _geoJsonController.text = content;
          _isInitialLoad = false; // Это загрузка файла
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Файл "${file.name}" успешно загружен'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Файл пустой');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Файл не выбран'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки файла: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showUrlDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Загрузить GeoJSON по URL'),
          content: TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://example.com/data.geojson',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadGeoJsonFromUrl();
              },
              child: const Text('Загрузить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadGeoJsonFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите URL для загрузки GeoJSON'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _geoJsonController.text = response.body;
        _isInitialLoad = false; // Это загрузка по URL
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GeoJSON успешно загружен'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _parseAndDisplayGeoJson() {
    try {
      // Очищаем предыдущие маркеры
      _clearMarkers();

      final geoJsonData = jsonDecode(_geoJsonController.text);

      if (geoJsonData['type'] == 'FeatureCollection') {
        final features = geoJsonData['features'] as List;
        int pointsCount = 0;
        int linesCount = 0;

        for (final feature in features) {
          final geometryType = feature['geometry']['type'];
          final properties = feature['properties'] as Map<String, dynamic>;

          // Поддержка разных форматов полей
          String title = _getPropertyValue(properties, ['name', 'назва', 'title', 'Name', 'ST_NAME']) ?? '';
          String description = _getPropertyValue(properties, ['description', 'описа', 'desc', 'Description']) ?? '';
          String date = _getPropertyValue(properties, ['date', 'дата', 'время', 'time']) ?? '';
          String edgeId = _getPropertyValue(properties, ['EdgeId', 'id', 'ID']) ?? '';
          
          // Делаем уникальное название для линий с EdgeId
          if (edgeId.isNotEmpty && geometryType == 'LineString') {
            title = title.isEmpty ? 'Линия $edgeId' : '$title (ID: $edgeId)';
          }
          
          // Объединяем описание и дату
          String fullDescription = description;
          if (date.isNotEmpty) {
            fullDescription = fullDescription.isEmpty ? date : '$description\n📅 $date';
          }

          if (geometryType == 'Point') {
            final coordinates = feature['geometry']['coordinates'] as List;
            final longitude = coordinates[0] as double;
            final latitude = coordinates[1] as double;

            _addMarker(
              latitude: latitude,
              longitude: longitude,
              title: title.isEmpty ? 'Точка' : title,
              description: fullDescription,
              date: date,
            );
            pointsCount++;
          } else if (geometryType == 'LineString') {
            final coordinates = feature['geometry']['coordinates'] as List;
            final points = <sdk.GeoPoint>[];
            
            for (final coord in coordinates) {
              final coordList = coord as List;
              points.add(sdk.GeoPoint(
                latitude: sdk.Latitude(coordList[1] as double),
                longitude: sdk.Longitude(coordList[0] as double),
              ));
            }

            _addLineString(
              points: points,
              title: title.isEmpty ? 'Линия' : title,
              description: fullDescription,
              date: date,
            );
            linesCount++;
            debugPrint('Обработана линия $linesCount: $title с ${points.length} точками');
          }
        }

        // Автоматически центрируем карту на объекты с небольшой задержкой
        // только если это не первая загрузка примера
        if (!_isInitialLoad) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _centerMapOnMarkers();
          });
        }
        
        // ВАЖНО: НЕ СБРАСЫВАЕМ _isInitialLoad здесь!
        // Он сбрасывается только при ручных действиях пользователя
        
        // Обновляем отфильтрованный список только если это не первая загрузка
        if (!_isInitialLoad) {
          _filterMarkersByDate(_selectedDate);
        } else {
          // При первой загрузке просто копируем все маркеры без фильтрации
          _markers = List.from(_allMarkers);
        }
        
        String message = '';
        if (pointsCount > 0 && linesCount > 0) {
          message = 'Добавлено $pointsCount точек и $linesCount линий на карту';
        } else if (pointsCount > 0) {
          message = 'Добавлено $pointsCount точек на карту';
        } else if (linesCount > 0) {
          message = 'Добавлено $linesCount линий на карту';
        } else {
          message = 'Не найдено объектов для отображения';
        }
        
        if (_availableDates.isNotEmpty) {
          message += '\nДоступно дат: ${_availableDates.length}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка парсинга GeoJSON: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Вспомогательная функция для получения значения по разным ключам
  String? _getPropertyValue(Map<String, dynamic> properties, List<String> keys) {
    for (String key in keys) {
      if (properties.containsKey(key) && properties[key] != null) {
        return properties[key].toString();
      }
    }
    return null;
  }

  void _addMarker({
    required double latitude,
    required double longitude,
    required String title,
    required String description,
    String? date,
  }) {
    // Сохраняем данные маркера для отображения
    final markerData = {
      'latitude': latitude,
      'longitude': longitude,
      'title': title,
      'description': description,
      'date': date ?? '',
      'type': 'point',
    };

    _allMarkers.add(markerData);
    
    // Добавляем дату в список доступных дат
    if (date != null && date.isNotEmpty) {
      _availableDates.add(date);
    }
    
    // Добавляем реальный маркер на карту с задержкой только если это не первая загрузка
    if (!_isInitialLoad) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _addRealMarkerToMap(latitude, longitude, title, description, date);
      });
    }
  }

  Future<void> _addRealMarkerToMap(
    double latitude,
    double longitude,
    String title,
    String description,
    String? date,
  ) async {
    if (_mapObjectManager == null) return;

    try {
      // Определяем цвет для маркера
      final hasDate = date?.isNotEmpty == true;
      final markerColor = hasDate ? Colors.blue.value : Colors.red.value;

      // Создаем простой круг как маркер
      final circle = sdk.Circle(
        sdk.CircleOptions(
          position: sdk.GeoPoint(
            latitude: sdk.Latitude(latitude),
            longitude: sdk.Longitude(longitude),
          ),
          radius: sdk.Meter(50), // Радиус 50 метров
          color: sdk.Color(markerColor),
          strokeColor: sdk.Color(Colors.white.value),
          strokeWidth: sdk.LogicalPixel(2.0),
          zIndex: sdk.ZIndex(1), // Добавляем zIndex
          userData: {
            'title': title,
            'description': description,
            'date': date ?? '',
            'type': 'point',
          },
        ),
      );

      // Добавляем круг на карту
      _mapObjectManager!.addObject(circle);
    } catch (e) {
      debugPrint('Ошибка добавления маркера: $e');
    }
  }

  void _addLineString({
    required List<sdk.GeoPoint> points,
    required String title,
    required String description,
    String? date,
  }) {
    // Сохраняем данные линии для отображения в списке
    if (points.isNotEmpty) {
      // Берем первую точку для отображения в списке
      final firstPoint = points.first;
      final lineData = {
        'latitude': firstPoint.latitude.value,
        'longitude': firstPoint.longitude.value,
        'title': title,
        'description': description,
        'date': date ?? '',
        'type': 'line',
        'pointsCount': points.length,
      };
      
      _allMarkers.add(lineData);
      
      // Добавляем дату в список доступных дат
      if (date != null && date.isNotEmpty) {
        _availableDates.add(date);
      }
      
      debugPrint('Добавлена линия в список: $title с ${points.length} точками');
    }
    
    // Добавляем реальную линию на карту с задержкой только если это не первая загрузка
    if (!_isInitialLoad) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _addRealLineToMap(points, title, description, date);
      });
    }
  }

  Future<void> _addRealLineToMap(
    List<sdk.GeoPoint> points,
    String title,
    String description,
    String? date,
  ) async {
    if (_mapObjectManager == null || points.isEmpty) return;

    try {
      // Определяем цвет для линии
      final hasDate = date?.isNotEmpty == true;
      // Используем разные оттенки для лучшей видимости
      final colors = hasDate 
          ? [Colors.orange.value, Colors.deepOrange.value, Colors.amber.value]
          : [Colors.purple.value, Colors.deepPurple.value, Colors.indigo.value];
      final colorIndex = title.hashCode.abs() % colors.length;
      final lineColor = colors[colorIndex];

      // Создаем полилинию точно как в add_objects.dart
      final polyline = sdk.Polyline(
        sdk.PolylineOptions(
          points: points,
          width: sdk.LogicalPixel(8.0), // Увеличиваем ширину линии до 8 пикселей
          color: sdk.Color(lineColor),
          zIndex: sdk.ZIndex(1), // Добавляем zIndex как в примере
          userData: {
            'title': title,
            'description': description,
            'date': date ?? '',
            'type': 'line',
            'pointsCount': points.length,
          },
        ),
      );

      // Добавляем линию на карту
      _mapObjectManager!.addObject(polyline);
      debugPrint('Добавлена линия: $title с ${points.length} точками');
    } catch (e) {
      debugPrint('Ошибка добавления линии: $e');
    }
  }

  void _clearMarkers() {
    _markers.clear();
    _allMarkers.clear();
    _availableDates.clear();
    _selectedDate = null;
    // Удаляем все маркеры с карты
    _mapObjectManager?.removeAll();
    setState(() {}); // Обновляем UI
  }

  void _filterMarkersByDate(String? date) {
    setState(() {
      _selectedDate = date;
      if (date == null) {
        // Показываем все маркеры
        _markers = List.from(_allMarkers);
      } else {
        // Фильтруем по выбранной дате
        _markers = _allMarkers.where((marker) => marker['date'] == date).toList();
      }
    });
    
    // Перерисовываем маркеры на карте
    _redrawMarkersOnMap();
  }

  void _redrawMarkersOnMap() {
    // НЕ перерисовываем маркеры при первой загрузке
    if (_isInitialLoad) return;
    
    // Очищаем карту
    _mapObjectManager?.removeAll();
    
    // Добавляем отфильтрованные маркеры на карту
    for (final marker in _markers) {
      if (marker['type'] == 'point') {
        Future.delayed(const Duration(milliseconds: 50), () {
          _addRealMarkerToMap(
            marker['latitude'],
            marker['longitude'],
            marker['title'],
            marker['description'],
            marker['date'],
          );
        });
      } else if (marker['type'] == 'line') {
        // Для линий нужно восстановить точки из исходных данных
        // Пока просто пропускаем, так как это сложнее
        debugPrint('Перерисовка линий пока не поддерживается');
      }
    }
  }

  void _centerMapOnMarkers() {
    if (_markers.isEmpty) return;

    try {
      // Находим границы всех объектов (точек и линий)
      double minLat = _markers.first['latitude'];
      double maxLat = _markers.first['latitude'];
      double minLng = _markers.first['longitude'];
      double maxLng = _markers.first['longitude'];

      for (final marker in _markers) {
        final lat = marker['latitude'] as double;
        final lng = marker['longitude'] as double;
        
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        if (lng < minLng) minLng = lng;
        if (lng > maxLng) maxLng = lng;
      }

      // Вычисляем центр
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;

      // Вычисляем подходящий зум
      double zoom = 15.0; // По умолчанию для одного объекта
      
      if (_markers.length > 1) {
        final latDiff = maxLat - minLat;
        final lngDiff = maxLng - minLng;
        final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
        
        // Простая формула для расчета зума
        if (maxDiff > 0.1) zoom = 10.0;
        else if (maxDiff > 0.05) zoom = 12.0;
        else if (maxDiff > 0.01) zoom = 14.0;
        else if (maxDiff > 0.005) zoom = 15.0;
        else zoom = 16.0;
      }

      // Обновляем позицию камеры
      setState(() {
        _cameraPosition = sdk.CameraPosition(
          point: sdk.GeoPoint(
            latitude: sdk.Latitude(centerLat),
            longitude: sdk.Longitude(centerLng),
          ),
          zoom: sdk.Zoom(zoom),
        );
      });
      
      final pointsCount = _markers.where((m) => m['type'] != 'line').length;
      final linesCount = _markers.where((m) => m['type'] == 'line').length;
      
      String message = 'Карта центрирована';
      if (pointsCount > 0 && linesCount > 0) {
        message += ' по $pointsCount точкам и $linesCount линиям';
      } else if (pointsCount > 0) {
        message += ' по $pointsCount точкам';
      } else if (linesCount > 0) {
        message += ' по $linesCount линиям';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка центрирования: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _exportGeoJsonToFile() async {
    if (_geoJsonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет данных для экспорта'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить GeoJSON файл',
        fileName: 'geojson_points.geojson',
        type: FileType.custom,
        allowedExtensions: ['geojson', 'json'],
      );

      if (outputFile != null) {
        // В веб-версии FilePicker автоматически скачает файл
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GeoJSON файл сохранен'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения файла: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _geoJsonController.dispose();
    _urlController.dispose();
    _clearMarkers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2GIS Maps & GeoJSON'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Карта - фиксированная высота
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Stack(
              children: [
                widget.sdkContext != null
                    ? sdk.MapWidget(
                        sdkContext: widget.sdkContext!,
                        mapOptions: sdk.MapOptions(
                          position: _cameraPosition,
                        ),
                        controller: _mapWidgetController,
                      )
                    : const Center(
                        child: Text(
                          'SDK не инициализирован',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                // Показываем информацию о маркерах
                if (_markers.isNotEmpty)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedDate != null 
                            ? 'Маркеров на карте: ${_markers.length} (фильтр: $_selectedDate)'
                            : 'Маркеров на карте: ${_markers.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Панель управления - прокручиваемая
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16, 
                16, 
                16, 
                16 + MediaQuery.of(context).padding.bottom
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Кнопки загрузки
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _loadGeoJsonFromFile,
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Загрузить из файла'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _showUrlDialog(),
                          icon: const Icon(Icons.link),
                          label: const Text('Загрузить по URL'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GeoJSON данные:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton.icon(
                        onPressed: _loadSampleGeoJson,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Пример'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Фильтр по датам
                  if (_availableDates.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Фильтр по дате:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('Все'),
                              selected: _selectedDate == null,
                              onSelected: (selected) {
                                if (selected) _filterMarkersByDate(null);
                              },
                            ),
                            ..._availableDates.map((date) => FilterChip(
                              label: Text(date),
                              selected: _selectedDate == date,
                              onSelected: (selected) {
                                _filterMarkersByDate(selected ? date : null);
                              },
                            )).toList(),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),

                  // Переключатель режимов
                  if (_markers.isNotEmpty)
                    Row(
                      children: [
                        const Text('Режим просмотра: '),
                        ToggleButtons(
                          isSelected: [!_showMarkersList, _showMarkersList],
                          onPressed: (index) {
                            setState(() {
                              _showMarkersList = index == 1;
                            });
                          },
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('GeoJSON'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Маркеры'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  if (_markers.isNotEmpty) const SizedBox(height: 8),

                  // Поле ввода GeoJSON или список маркеров
                  SizedBox(
                    height: 300,
                    child: _markers.isNotEmpty && _showMarkersList
                        ? ListView.builder(
                            itemCount: _markers.length,
                            itemBuilder: (context, index) {
                              final marker = _markers[index];
                              final hasDate = marker['date'] != null &&
                                  marker['date'].toString().isNotEmpty;
                              final isLine = marker['type'] == 'line';

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                child: ListTile(
                                  leading: Icon(
                                    isLine
                                        ? (hasDate ? Icons.timeline : Icons.route)
                                        : (hasDate ? Icons.event_available : Icons.location_on),
                                    color: isLine
                                        ? (hasDate ? Colors.orange : Colors.purple)
                                        : (hasDate ? Colors.blue : Colors.red),
                                  ),
                                  title: Text(
                                    marker['title'] ?? (isLine ? 'Линия ${index + 1}' : 'Точка ${index + 1}'),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isLine 
                                            ? '🛣️ Линия (${marker['pointsCount']} точек) - ${marker['latitude'].toStringAsFixed(4)}, ${marker['longitude'].toStringAsFixed(4)}'
                                            : '📍 ${marker['latitude'].toStringAsFixed(4)}, ${marker['longitude'].toStringAsFixed(4)}',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      if (marker['description'] != null &&
                                          marker['description']
                                              .toString()
                                              .isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            marker['description'].toString(),
                                            style:
                                                const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      if (hasDate)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isLine ? Colors.orange : Colors.blue)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '📅 ${marker['date']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isLine ? Colors.orange : Colors.blue,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  dense: false,
                                ),
                              );
                            },
                          )
                        : TextField(
                            controller: _geoJsonController,
                            maxLines: null,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Вставьте GeoJSON данные здесь...',
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Кнопки управления
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _isInitialLoad = false; // Это ручная загрузка
                                _parseAndDisplayGeoJson();
                              },
                              icon: const Icon(Icons.add_location),
                              label: const Text('Показать точки'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _clearMarkers,
                              icon: const Icon(Icons.clear),
                              label: const Text('Очистить'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _centerMapOnMarkers,
                              icon: const Icon(Icons.center_focus_strong),
                              label: const Text('Центрировать'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _exportGeoJsonToFile,
                              icon: const Icon(Icons.file_download),
                              label: const Text('Экспорт'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}