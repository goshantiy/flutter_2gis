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

  List<MarkerModel> _markers = [];
  List<MarkerModel> _allMarkers = [];
  bool _isInitialLoad = true;
  Set<String> _availableDates = {};
  String? _selectedDate;

  // Для карточки маркера
  MarkerModel? _selectedMarker;
  final DraggableScrollableController _cardController =
      DraggableScrollableController();

  final _mapWidgetController = sdk.MapWidgetController();
  sdk.MapObjectManager? _mapObjectManager;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _loadDataFromApi();
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
        final geoPoint = projection
            .screenToMap(sdk.ScreenPoint(x: tapPosition.dx, y: tapPosition.dy));

        if (geoPoint != null) {
          debugPrint(
              'Координаты тапа: ${geoPoint.latitude.value}, ${geoPoint.longitude.value}');

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

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return ((lat1 - lat2) * (lat1 - lat2) + (lon1 - lon2) * (lon1 - lon2));
  }

  void _loadDataFromApi() async {
    try {
      const apiUrl = 'https://events-api-eta.vercel.app/api/events';
      final content = await DataLoaderService.loadFromUrl(apiUrl);
      _jsonController.text = content;

      // Автоматически парсим и отображаем события
      _isInitialLoad = false;
      _parseAndDisplayEvents();

      debugPrint('Данные успешно загружены с API');
    } catch (e) {
      debugPrint('Ошибка загрузки данных с API: $e');
      // В случае ошибки загружаем примеры данных
      _jsonController.text = DataLoaderService.getSampleJson();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки с API, показаны примеры данных: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
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
      _availableDates =
          markers.map((m) => m.date).where((d) => d.isNotEmpty).toSet();

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
      } else if (marker.isLine) {
        Future.delayed(const Duration(milliseconds: 50), () {
          MapService.addLineToMap(_mapObjectManager!, marker);
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

  void _showMarkersList() {
    if (_markers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет маркеров для отображения'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Объекты на карте (${_markers.length})'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: _markers.length,
              itemBuilder: (context, index) {
                final marker = _markers[index];
                return ListTile(
                  leading: Icon(
                    marker.isPoint ? Icons.place : Icons.route,
                    color: marker.hasDate ? Colors.blue : Colors.red,
                  ),
                  title: Text(marker.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (marker.description.isNotEmpty)
                        Text(
                          marker.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (marker.date.isNotEmpty)
                        Text(
                          '📅 ${marker.date}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showMarkerInfo(marker);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  void _showMarkerInfo(MarkerModel marker) {
    String fullInfo = marker.title;
    if (marker.description.isNotEmpty) {
      fullInfo += '\\n\\n${marker.description}';
    }
    if (marker.date.isNotEmpty) {
      fullInfo += '\\n\\n📅 ${marker.date}';
    }
    if (marker.isLine && marker.pointsCount != null) {
      fullInfo += '\\n\\n📏 Точек: ${marker.pointsCount}';
    }

    // Показываем информацию в диалоге
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(marker.title),
          content: SingleChildScrollView(
            child: Text(fullInfo),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _jsonController.dispose();
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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
                        16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ControlButtonsWidget(
                          onClearMarkers: _clearMarkers,
                          onCenterMap: _centerMapOnMarkers,
                          onShowMarkersList: _showMarkersList,
                          onRefreshData: _loadDataFromApi,
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
                                if (_selectedMarker!
                                    .description.isNotEmpty) ...[
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
                                Text(_selectedMarker!.isPoint
                                    ? 'Точка'
                                    : 'Линия'),
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
