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
      appBar: AppBar(
        title: const Text('2GIS Maps & Events'),
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
    );
  }
}