import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import '../models/marker_model.dart';
import '../models/event_status.dart';
import '../services/data_loader_service.dart';
import '../services/json_parser_service.dart';
import '../services/map_service.dart';
import '../widgets/event_status_filter_widget.dart';
import '../widgets/marker_card_widget.dart';
import '../utils/event_status_utils.dart';

class EventsMapPage extends StatefulWidget {
  final sdk.Context? sdkContext;

  const EventsMapPage({super.key, this.sdkContext});

  @override
  State<EventsMapPage> createState() => _EventsMapPageState();
}

class _EventsMapPageState extends State<EventsMapPage> {
  List<MarkerModel> _markers = [];
  List<MarkerModel> _allMarkers = [];
  bool _isInitialLoad = true;
  EventStatus _selectedStatus = EventStatus.all;

  // Управление отображением
  bool _markersVisible = true;
  bool _isFullScreen = false;
  bool _isMenuVisible = true; // Добавляем флаг видимости меню

  // Для карточки маркера
  MarkerModel? _selectedMarker;
  DraggableScrollableController? _cardController;

  // Для нижнего меню
  DraggableScrollableController? _menuController;

  final _mapWidgetController = sdk.MapWidgetController();
  sdk.MapObjectManager? _mapObjectManager;
  sdk.MapOptions? _mapOptions;

  @override
  void initState() {
    super.initState();
    _cardController = DraggableScrollableController();
    _menuController = DraggableScrollableController();
    _initializeMapOptions();
    _initializeMap();
    _loadDataFromApi();
  }

  Future<void> _initializeMapOptions() async {
    if (widget.sdkContext != null) {
      try {
        debugPrint('Загружаем кастомные стили карты...');

        // Асинхронная загрузка стиля карты из файла
        final styleBuilder = sdk.StyleBuilder(widget.sdkContext!);
        final style = await styleBuilder
            .loadStyle(sdk.File('assets/sdk-styles-2025-10-05-16-04-52.2gis'))
            .value;

        // Создание MapOptions с загруженным стилем
        _mapOptions = sdk.MapOptions(
          position: sdk.CameraPosition(
            point: sdk.GeoPoint(
              latitude: sdk.Latitude(55.7539), // Москва
              longitude: sdk.Longitude(37.6156),
            ),
            zoom: sdk.Zoom(11.0),
          ),
          style: style,
        );

        debugPrint('Кастомные стили карты загружены: ✓');
        setState(() {}); // Обновляем UI после загрузки стилей
      } catch (e) {
        debugPrint('Ошибка загрузки кастомных стилей: $e');
        debugPrint('Используем стандартные стили');

        // Fallback на стандартные стили
        _mapOptions = sdk.MapOptions(
          position: sdk.CameraPosition(
            point: sdk.GeoPoint(
              latitude: sdk.Latitude(55.7539), // Москва
              longitude: sdk.Longitude(37.6156),
            ),
            zoom: sdk.Zoom(11.0),
          ),
        );
        setState(() {});
      }
    }
  }

  void _initializeMap() {
    if (widget.sdkContext != null) {
      _mapWidgetController.getMapAsync((map) {
        _mapObjectManager = sdk.MapObjectManager(map);

        // Пока используем простой подход без обработчиков SDK
        debugPrint('MapObjectManager инициализирован');

        // Устанавливаем позицию на Москву с небольшой задержкой
        Future.delayed(const Duration(milliseconds: 500), () {
          final moscowPosition = MapService.defaultPosition;
          map.camera.move(
            moscowPosition.point,
            moscowPosition.zoom,
            moscowPosition.tilt,
            moscowPosition.bearing,
          );
          debugPrint(
              'Карта перемещена на Москву: ${moscowPosition.point.latitude.value}, ${moscowPosition.point.longitude.value}');
        });

        debugPrint('MapObjectManager инициализирован с обработчиком кликов');
      });
    } else {
      debugPrint('SDK Context не инициализирован!');
    }
  }

  void _showMarkerCard(MarkerModel marker) {
    // Тактильная обратная связь
    HapticFeedback.lightImpact();

    // Просто скрываем меню через состояние - без контроллеров
    debugPrint('Скрываем меню при открытии карточки');

    setState(() {
      _selectedMarker = marker;
      _isMenuVisible = false; // Скрываем меню через состояние
    });

    // Показываем карточку с задержкой, чтобы меню успело скрыться
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_cardController?.isAttached == true) {
        try {
          _cardController!.animateTo(
            0.4, // Увеличиваем начальный размер карточки
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        } catch (e) {
          debugPrint('Ошибка показа карточки: $e');
        }
      }
    });

    debugPrint('Показываем карточку для: ${marker.title}');
  }

  void _hideMarkerCard() {
    if (_cardController?.isAttached == true) {
      try {
        _cardController!.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } catch (e) {
        debugPrint('Ошибка скрытия карточки: $e');
      }
    }

    // Возвращаем меню через состояние и контроллер
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _selectedMarker = null;
        _isMenuVisible = true; // Показываем меню обратно
      });

      // Программно возвращаем меню к начальному размеру
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_menuController?.isAttached == true && !_isFullScreen) {
          try {
            _menuController!.animateTo(
              0.3,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
            debugPrint('Меню программно возвращено к размеру 0.3');
          } catch (e) {
            debugPrint('Ошибка возврата меню к размеру 0.3: $e');
          }
        }
      });

      debugPrint('Меню возвращено при закрытии карточки');
    });
  }

  void _toggleMarkersVisibility() {
    setState(() {
      _markersVisible = !_markersVisible;
    });

    if (_markersVisible) {
      _redrawMarkersOnMap();
    } else {
      _mapObjectManager?.removeAll();
    }

    debugPrint('Видимость маркеров: $_markersVisible');
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    debugPrint('Полноэкранный режим: $_isFullScreen');
  }

  void _handleMapTap(TapDownDetails details) {
    final tapPosition = details.localPosition;
    debugPrint('Тап по карте в позиции: $tapPosition');

    // Проверяем расстояние до каждого маркера на экране
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
          _findNearestMarkerByCoordinates(geoPoint);
        } else {
          debugPrint('Не удалось определить координаты тапа');
        }
      } catch (e) {
        debugPrint('Ошибка обработки тапа: $e');
      }
    });
  }

  void _findNearestMarkerByCoordinates(sdk.GeoPoint tapPoint) {
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

      // Автоматически парсим и отображаем события
      _isInitialLoad = false;
      _parseAndDisplayEvents(content);

      debugPrint('Данные успешно загружены с API');
    } catch (e) {
      debugPrint('Ошибка загрузки данных с API: $e');
      // В случае ошибки загружаем примеры данных
      final sampleData = DataLoaderService.getSampleJson();

      // Важно! Парсим примеры данных
      _isInitialLoad = false;
      _parseAndDisplayEvents(sampleData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки с API, показаны примеры данных: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _parseAndDisplayEvents(String jsonContent) {
    debugPrint('_parseAndDisplayEvents вызван');
    debugPrint('_isInitialLoad: $_isInitialLoad');

    if (_isInitialLoad) {
      debugPrint('Первая загрузка - данные не обрабатываются');
      return;
    }

    try {
      debugPrint('Начинаем парсинг JSON');
      _clearMarkers();

      final markers = JsonParserService.parseEventsJson(jsonContent);
      debugPrint('Распарсено маркеров: ${markers.length}');

      _allMarkers = markers;

      debugPrint('Вызываем _filterMarkersByStatus');
      _filterMarkersByStatus(_selectedStatus);

      // Не центрируем карту автоматически - оставляем на Москве

      _showSuccessMessage(markers);
    } catch (e) {
      debugPrint('Ошибка в _parseAndDisplayEvents: $e');
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

    // Убираем информацию о датах

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
    _selectedStatus = EventStatus.all;
    _mapObjectManager?.removeAll();
    setState(() {});
  }

  void _filterMarkersByStatus(EventStatus status) {
    debugPrint(
        '_filterMarkersByStatus вызван со статусом: ${status.displayName}');
    debugPrint('_allMarkers.length: ${_allMarkers.length}');

    setState(() {
      _selectedStatus = status;
      if (status == EventStatus.all) {
        _markers = List.from(_allMarkers);
      } else {
        _markers = _allMarkers.where((marker) {
          final eventStatus = EventStatusUtils.getEventStatus(marker.date);
          return eventStatus == status;
        }).toList();
      }
    });

    debugPrint('После фильтрации _markers.length: ${_markers.length}');
    debugPrint('Вызываем _redrawMarkersOnMap');
    _redrawMarkersOnMap();
  }

  void _redrawMarkersOnMap() {
    debugPrint('_redrawMarkersOnMap вызван');
    debugPrint('_isInitialLoad: $_isInitialLoad');
    debugPrint('_mapObjectManager == null: ${_mapObjectManager == null}');
    debugPrint('_markersVisible: $_markersVisible');
    debugPrint('_markers.length: ${_markers.length}');

    if (_isInitialLoad || _mapObjectManager == null) {
      debugPrint(
          'Выход из _redrawMarkersOnMap: _isInitialLoad=$_isInitialLoad, _mapObjectManager==null=${_mapObjectManager == null}');
      return;
    }

    _mapObjectManager!.removeAll();
    debugPrint('Очистили все объекты с карты');

    // Если маркеры скрыты, не отрисовываем их
    if (!_markersVisible) {
      debugPrint('Маркеры скрыты, пропускаем отрисовку');
      return;
    }

    for (final marker in _markers) {
      debugPrint(
          'Обрабатываем маркер: ${marker.title}, isPoint: ${marker.isPoint}, isLine: ${marker.isLine}');

      if (marker.isPoint) {
        debugPrint('Добавляем точечный маркер: ${marker.title}');
        Future.delayed(const Duration(milliseconds: 50), () async {
          if (widget.sdkContext != null) {
            debugPrint('SDK контекст доступен, создаем маркер');
            try {
              await MapService.addMarkerToMap(
                  _mapObjectManager!, marker, widget.sdkContext!);
              debugPrint('Маркер успешно добавлен: ${marker.title}');
            } catch (e) {
              debugPrint('Ошибка добавления маркера ${marker.title}: $e');
            }
          } else {
            debugPrint('SDK контекст недоступен!');
          }
        });
      } else if (marker.isLine) {
        debugPrint('Добавляем линейный маркер: ${marker.title}');
        Future.delayed(const Duration(milliseconds: 50), () {
          try {
            MapService.addLineToMap(_mapObjectManager!, marker);
            debugPrint('Линия успешно добавлена: ${marker.title}');
          } catch (e) {
            debugPrint('Ошибка добавления линии ${marker.title}: $e');
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _cardController?.dispose();
    _menuController?.dispose();
    _clearMarkers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Карта на весь экран
            SizedBox(
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
              child: Stack(
                children: [
                  GestureDetector(
                    onTapDown: (details) => _handleMapTap(details),
                    child: widget.sdkContext != null && _mapOptions != null
                        ? sdk.MapWidget(
                            sdkContext: widget.sdkContext!,
                            mapOptions: _mapOptions!,
                            controller: _mapWidgetController,
                          )
                        : widget.sdkContext != null && _mapOptions == null
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text(
                                      'Загружаем стили карты...',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.map_outlined,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      '2GIS SDK не инициализирован',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Проверьте API ключ в assets/dgissdk.key',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                  ),

                  // Кнопки управления в правом верхнем углу
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      children: [
                        // Кнопка переключения видимости маркеров
                        FloatingActionButton.small(
                          onPressed: _toggleMarkersVisibility,
                          backgroundColor:
                              _markersVisible ? Colors.blue : Colors.grey,
                          child: Icon(
                            _markersVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Кнопка полноэкранного режима
                        FloatingActionButton.small(
                          onPressed: _toggleFullScreen,
                          backgroundColor:
                              _isFullScreen ? Colors.green : Colors.blue,
                          child: Icon(
                            _isFullScreen
                                ? Icons.fullscreen_exit
                                : Icons.fullscreen,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Карточка маркера в стиле 2GIS
            if (_selectedMarker != null)
              DraggableScrollableSheet(
                controller: _cardController,
                initialChildSize: 0.0,
                minChildSize: 0.0,
                maxChildSize: 0.9,
                snap: true,
                snapSizes: const [0.3, 0.6, 0.9],
                builder: (context, scrollController) {
                  return NotificationListener<DraggableScrollableNotification>(
                    onNotification: (notification) {
                      // Обрабатываем изменения размера карточки
                      return false;
                    },
                    child: MarkerCardWidget(
                      marker: _selectedMarker!,
                      onClose: _hideMarkerCard,
                      scrollController: scrollController,
                    ),
                  );
                },
              ),

            // Фиксированное меню поверх карты (не закрываемое)
            if (!_isFullScreen && _isMenuVisible)
              DraggableScrollableSheet(
                controller: _menuController,
                initialChildSize: 0.3,
                minChildSize: 0.0, // Позволяем полностью скрывать меню
                maxChildSize: 0.8,
                snap: true,
                snapSizes: const [
                  0.0,
                  0.3,
                  0.6,
                  0.8
                ], // Добавляем 0.0 для полного скрытия
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ручка для перетаскивания
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),

                          // Заголовок
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: Row(
                              children: const [
                                Icon(Icons.tune, color: Colors.blue, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Настройки карты',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Divider(height: 1),

                          // Содержимое меню
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                EventStatusFilterWidget(
                                  selectedStatus: _selectedStatus,
                                  onStatusSelected: _filterMarkersByStatus,
                                ),

                                const SizedBox(height: 10),

                                // Кнопка обновления данных
                                ElevatedButton.icon(
                                  onPressed: _loadDataFromApi,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Обновить данные'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
