import 'package:flutter/material.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import '../models/marker_model.dart';
import '../services/data_loader_service.dart';
import '../services/json_parser_service.dart';
import '../services/map_service.dart';
import '../widgets/date_filter_widget.dart';
import '../widgets/control_buttons_widget.dart';

class EventsMapPage extends StatefulWidget {
  final sdk.Context? sdkContext;

  const EventsMapPage({super.key, this.sdkContext});

  @override
  State<EventsMapPage> createState() => _EventsMapPageState();
}

class _EventsMapPageState extends State<EventsMapPage> {
  final TextEditingController _jsonController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  
  List<MarkerModel> _markers = [];
  List<MarkerModel> _allMarkers = [];
  bool _isLoading = false;
  bool _isInitialLoad = true;
  Set<String> _availableDates = {};
  String? _selectedDate;
  
  // Для карточки маркера
  MarkerModel? _selectedMarker;
  final DraggableScrollableController _cardController = DraggableScrollableController();

  final _mapWidgetController = sdk.MapWidgetController();
  sdk.MapObjectManager? _mapObjectManager;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _loadSampleData();
  }

  void _initializeMap() {
    if (widget.sdkContext != null) {
      _mapWidgetController.getMapAsync((map) {
        _mapObjectManager = sdk.MapObjectManager(map);
        debugPrint('MapObjectManager инициализирован');
      });
    }
  }

  void _showMarkerCard(MarkerModel marker) {
    setState(() {
      _selectedMarker = marker;
    });
    
    // Показываем карточку, расширив DraggableScrollableSheet
    if (_cardController.isAttached) {
      _cardController.animateTo(
        0.4,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    
    debugPrint('Показываем карточку для: ${marker.title}');
  }

  void _hideMarkerCard() {
    if (_cardController.isAttached) {
      _cardController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _selectedMarker = null;
      });
    });
  }

  void _handleMapTap(TapDownDetails details) {
    final tapPosition = details.localPosition;
    debugPrint('Тап по карте в позиции: $tapPosition');
    
    // Простой подход: проверяем расстояние до каждого маркера на экране
    _mapWidgetController.getMapAsync((map) {
      try {
        final projection = map.camera.projection;
        
        // Конвертируем тап в координаты карты
        final geoPoint = projection.screenToMap(sdk.ScreenPoint(
          x: tapPosition.dx, 
          y: tapPosition.dy
        ));
        
        if (geoPoint != null) {
          debugPrint('Координаты тапа: ${geoPoint.latitude.value}, ${geoPoint.longitude.value}');
          
          // Ищем ближайший маркер
          _findNearestMarker(geoPoint);
        } else {
          debugPrint('Не удалось определить координаты тапа');
        }
      } catch (e) {
        debugPrint('Ошибка обработки тапа: $e');
      }
    });
  }

  void _findNearestMarker(sdk.GeoPoint tapPoint) {
    const double threshold = 0.001; // Порог расстояния для определения "близко"
    MarkerModel? nearestMarker;
    double minDistance = double.infinity;
    
    for (final marker in _markers) {
      final distance = _calculateDistance(
        tapPoint.latitude.value,
        tapPoint.longitude.value,
        marker.latitude,
        marker.longitude,
      );
      
      if (distance < threshold && distance < minDistance) {
        minDistance = distance;
        nearestMarker = marker;
      }
    }
    
    if (nearestMarker != null) {
      debugPrint('Найден ближайший маркер: ${nearestMarker.title}');
      _showMarkerCard(nearestMarker);
    } else {
      debugPrint('Маркер не найден рядом с точкой тапа');
      _hideMarkerCard();
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return ((lat1 - lat2) * (lat1 - lat2) + (lon1 - lon2) * (lon1 - lon2));
  }

  void _loadSampleData() {
    // ВАЖНО: Только загружаем в текстовое поле, НЕ парсим
    _jsonController.text = DataLoaderService.getSampleJson();
  }

  void _parseAndDisplayEvents() {
    if (_isInitialLoad) {
      debugPrint('Первая загрузка - данные не обрабатываются');
      return;
    }

    try {
      _clearMarkers();
      
      final markers = JsonParserService.parseEventsJson(_jsonController.text);
      
      _allMarkers = markers;
      _availableDates = markers.map((m) => m.date).where((d) => d.isNotEmpty).toSet();
      
      _filterMarkersByDate(_selectedDate);
      
      // Не центрируем карту автоматически - оставляем на Москве
      
      _showSuccessMessage(markers);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка парсинга JSON: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessMessage(List<MarkerModel> markers) {
    final pointsCount = markers.where((m) => m.isPoint).length;
    final linesCount = markers.where((m) => m.isLine).length;
    
    String message = '';
    if (pointsCount > 0 && linesCount > 0) {
      message = 'Добавлено $pointsCount точек и $linesCount линий';
    } else if (pointsCount > 0) {
      message = 'Добавлено $pointsCount точек';
    } else if (linesCount > 0) {
      message = 'Добавлено $linesCount линий';
    } else {
      message = 'Не найдено объектов для отображения';
    }
    
    if (_availableDates.isNotEmpty) {
      message += '\\nДоступно дат: ${_availableDates.length}';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearMarkers() {
    _markers.clear();
    _allMarkers.clear();
    _availableDates.clear();
    _selectedDate = null;
    _mapObjectManager?.removeAll();
    setState(() {});
  }

  void _filterMarkersByDate(String? date) {
    setState(() {
      _selectedDate = date;
      if (date == null) {
        _markers = List.from(_allMarkers);
      } else {
        _markers = _allMarkers.where((marker) => marker.date == date).toList();
      }
    });
    
    _redrawMarkersOnMap();
  }

  void _redrawMarkersOnMap() {
    if (_isInitialLoad || _mapObjectManager == null) return;
    
    _mapObjectManager!.removeAll();
    
    for (final marker in _markers) {
      if (marker.isPoint) {
        Future.delayed(const Duration(milliseconds: 50), () {
          MapService.addMarkerToMap(_mapObjectManager!, marker);
        });
      }
    }
  }

  void _centerMapOnMarkers() {
    if (_markers.isEmpty) return;

    try {
      final newPosition = MapService.calculateBounds(_markers);
      // Обновляем позицию карты через контроллер
      _mapWidgetController.getMapAsync((map) {
        map.camera.move(
          newPosition.point,
          newPosition.zoom,
          newPosition.tilt,
          newPosition.bearing,
        );
      });
    } catch (e) {
      debugPrint('Ошибка центрирования: $e');
    }
  }

  Future<void> _loadFromFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final content = await DataLoaderService.loadFromFile();
      if (content != null) {
        _jsonController.text = content;
        _isInitialLoad = false;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Файл успешно загружен'),
            backgroundColor: Colors.green,
          ),
        );
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
          title: const Text('Загрузить JSON по URL'),
          content: TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://example.com/data.json',
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
                _loadFromUrl();
              },
              child: const Text('Загрузить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadFromUrl() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final content = await DataLoaderService.loadFromUrl(_urlController.text);
      _jsonController.text = content;
      _isInitialLoad = false;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('JSON успешно загружен'),
          backgroundColor: Colors.green,
        ),
      );
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

  @override
  void dispose() {
    _jsonController.dispose();
    _urlController.dispose();
    _clearMarkers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Основной контент
            Column(
              children: [
                // Карта - фиксированная высота
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTapDown: (details) => _handleMapTap(details),
                        child: widget.sdkContext != null
                            ? sdk.MapWidget(
                                sdkContext: widget.sdkContext!,
                                mapOptions: sdk.MapOptions(
                                  position: MapService.defaultPosition,
                                ),
                                controller: _mapWidgetController,
                              )
                            : const Center(
                                child: Text(
                                  'SDK не инициализирован',
                                  style: TextStyle(fontSize: 18),
                                ),
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
                                  ? 'Объектов на карте: ${_markers.length} (фильтр: $_selectedDate)'
                                  : 'Объектов на карте: ${_markers.length}',
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
                  ControlButtonsWidget(
                    isLoading: _isLoading,
                    onLoadFromFile: _loadFromFile,
                    onLoadFromUrl: _showUrlDialog,
                    onLoadSample: _loadSampleData,
                    onShowEvents: () {
                      _isInitialLoad = false;
                      _parseAndDisplayEvents();
                    },
                    onClearMarkers: _clearMarkers,
                    onCenterMap: _centerMapOnMarkers,
                  ),
                  
                  DateFilterWidget(
                    availableDates: _availableDates,
                    selectedDate: _selectedDate,
                    onDateSelected: _filterMarkersByDate,
                  ),

                  // Поле ввода JSON
                  SizedBox(
                    height: 300,
                    child: TextField(
                      controller: _jsonController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Вставьте JSON данные событий здесь...',
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
            ],
          ),
            
            // Карточка маркера
            if (_selectedMarker != null)
              DraggableScrollableSheet(
                controller: _cardController,
                initialChildSize: 0.0,
                minChildSize: 0.0,
                maxChildSize: 0.6,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Заголовок с кнопкой закрытия
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedMarker!.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _hideMarkerCard,
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                        
                        // Контент карточки
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_selectedMarker!.description.isNotEmpty) ...[
                                  const Text(
                                    'Описание:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(_selectedMarker!.description),
                                  const SizedBox(height: 16),
                                ],
                                
                                if (_selectedMarker!.date.isNotEmpty) ...[
                                  const Text(
                                    'Дата:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(_selectedMarker!.date),
                                  const SizedBox(height: 16),
                                ],
                                
                                const Text(
                                  'Координаты:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Широта: ${_selectedMarker!.latitude.toStringAsFixed(6)}\n'
                                  'Долгота: ${_selectedMarker!.longitude.toStringAsFixed(6)}',
                                ),
                                const SizedBox(height: 16),
                                
                                const Text(
                                  'Тип объекта:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(_selectedMarker!.isPoint ? 'Точка' : 'Линия'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}