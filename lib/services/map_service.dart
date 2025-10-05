import 'package:flutter/material.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import '../models/marker_model.dart';
import '../constants/app_constants.dart';
import '../utils/color_utils.dart';

class MapService {
  static sdk.CameraPosition get defaultPosition => sdk.CameraPosition(
        point: sdk.GeoPoint(
          latitude: sdk.Latitude(AppConstants.defaultLatitude),
          longitude: sdk.Longitude(AppConstants.defaultLongitude),
        ),
        zoom: sdk.Zoom(AppConstants.defaultZoom),
      );

  static Future<void> addMarkerToMap(
    sdk.MapObjectManager mapObjectManager,
    MarkerModel marker,
    sdk.Context sdkContext,
  ) async {
    try {
      // Создаем стильные маркеры с разными дизайнами

      debugPrint(
          'Начинаем создание маркера: ${marker.title} (${marker.latitude}, ${marker.longitude})');

      // Пробуем создать маркер с иконкой согласно официальному примеру
      try {
        await _createSimpleMarker(mapObjectManager, marker, sdkContext);
      } catch (iconError) {
        debugPrint('Ошибка создания маркера с иконкой: $iconError');
        debugPrint('Используем fallback на геометрические маркеры');

        // Fallback на красивые геометрические маркеры
        if (marker.isLine) {
          _createSquareMarker(mapObjectManager, marker);
          debugPrint('Создан квадратный маркер для перекрытия');
        } else if (marker.hasDate) {
          _createEventMarker(mapObjectManager, marker);
          debugPrint('Создан маркер события с датой');
        } else {
          _createPlaceMarker(mapObjectManager, marker);
          debugPrint('Создан простой маркер места');
        }
      }

      debugPrint('Стильный маркер добавлен: ${marker.title}');
    } catch (e) {
      debugPrint('Ошибка добавления маркера: $e');

      // Fallback на простой круг если иконка не загрузилась
      try {
        final markerColor = ColorUtils.getMarkerColor(marker.hasDate);
        final circle = sdk.Circle(
          sdk.CircleOptions(
            position: sdk.GeoPoint(
              latitude: sdk.Latitude(marker.latitude),
              longitude: sdk.Longitude(marker.longitude),
            ),
            radius: sdk.Meter(AppConstants.markerRadius),
            color: sdk.Color(markerColor),
            strokeColor: sdk.Color(AppConstants.markerStrokeColor),
            strokeWidth: sdk.LogicalPixel(AppConstants.strokeWidth),
            zIndex: sdk.ZIndex(2),
            userData: marker.toMap(),
          ),
        );
        mapObjectManager.addObject(circle);
        debugPrint('Использован fallback круг для маркера: ${marker.title}');
      } catch (fallbackError) {
        debugPrint('Ошибка fallback маркера: $fallbackError');
      }
    }
  }

  static Future<void> addLineToMap(
    sdk.MapObjectManager mapObjectManager,
    MarkerModel lineMarker,
  ) async {
    if (lineMarker.lineCoordinates == null ||
        lineMarker.lineCoordinates!.isEmpty) {
      debugPrint('Нет координат для линии: ${lineMarker.title}');
      return;
    }

    try {
      // Конвертируем координаты в GeoPoint
      final points = lineMarker.lineCoordinates!
          .map((coord) => sdk.GeoPoint(
                latitude: sdk.Latitude(coord[1]), // lat
                longitude: sdk.Longitude(coord[0]), // lon
              ))
          .toList();

      final lineColor =
          ColorUtils.getLineColor(lineMarker.hasDate, lineMarker.title);

      final polyline = sdk.Polyline(
        sdk.PolylineOptions(
          points: points,
          width: sdk.LogicalPixel(AppConstants.lineWidth),
          color: sdk.Color(lineColor),
          zIndex: sdk.ZIndex(1),
          userData: lineMarker.toMap(),
        ),
      );

      mapObjectManager.addObject(polyline);
      debugPrint(
          'Линия добавлена: ${lineMarker.title} (${points.length} точек)');
    } catch (e) {
      debugPrint('Ошибка добавления линии: $e');
    }
  }

  static sdk.CameraPosition calculateBounds(List<MarkerModel> markers) {
    if (markers.isEmpty) return defaultPosition;

    double minLat = markers.first.latitude;
    double maxLat = markers.first.latitude;
    double minLng = markers.first.longitude;
    double maxLng = markers.first.longitude;

    for (final marker in markers) {
      if (marker.latitude < minLat) minLat = marker.latitude;
      if (marker.latitude > maxLat) maxLat = marker.latitude;
      if (marker.longitude < minLng) minLng = marker.longitude;
      if (marker.longitude > maxLng) maxLng = marker.longitude;
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    double zoom = 15.0;

    if (markers.length > 1) {
      final latDiff = maxLat - minLat;
      final lngDiff = maxLng - minLng;
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

      if (maxDiff > 0.1)
        zoom = 10.0;
      else if (maxDiff > 0.05)
        zoom = 12.0;
      else if (maxDiff > 0.01)
        zoom = 14.0;
      else if (maxDiff > 0.005)
        zoom = 15.0;
      else
        zoom = 16.0;
    }

    return sdk.CameraPosition(
      point: sdk.GeoPoint(
        latitude: sdk.Latitude(centerLat),
        longitude: sdk.Longitude(centerLng),
      ),
      zoom: sdk.Zoom(zoom),
    );
  }

  static List<sdk.GeoPoint> parseLineCoordinates(
      String jsonString, String eventName, int closureIndex) {
    // Эта функция должна извлекать координаты линии из исходного JSON
    // Для упрощения возвращаем пустой список
    // В реальной реализации нужно сохранять исходные данные
    return [];
  }

  // Создает квадратный маркер для перекрытий
  static void _createSquareMarker(
    sdk.MapObjectManager mapObjectManager,
    MarkerModel marker,
  ) {
    final position = sdk.GeoPoint(
      latitude: sdk.Latitude(marker.latitude),
      longitude: sdk.Longitude(marker.longitude),
    );

    // Основной квадрат (имитируем через круг с большой обводкой)
    final square = sdk.Circle(
      sdk.CircleOptions(
        position: position,
        radius: sdk.Meter(30),
        color: sdk.Color(0xFFFF5722), // Оранжевый для перекрытий
        strokeColor: sdk.Color(0xFFFFFFFF),
        strokeWidth: sdk.LogicalPixel(4),
        zIndex: sdk.ZIndex(2),
        userData: marker.toMap(),
      ),
    );
    mapObjectManager.addObject(square);

    // Внутренний символ
    final innerSymbol = sdk.Circle(
      sdk.CircleOptions(
        position: position,
        radius: sdk.Meter(12),
        color: sdk.Color(0xFFFFFFFF),
        zIndex: sdk.ZIndex(3),
        userData: marker.toMap(),
      ),
    );
    mapObjectManager.addObject(innerSymbol);
  }

  // Создает круглый маркер для событий с датой
  static void _createEventMarker(
    sdk.MapObjectManager mapObjectManager,
    MarkerModel marker,
  ) {
    final position = sdk.GeoPoint(
      latitude: sdk.Latitude(marker.latitude),
      longitude: sdk.Longitude(marker.longitude),
    );

    // Внешний круг (эффект пульсации)
    final outerCircle = sdk.Circle(
      sdk.CircleOptions(
        position: position,
        radius: sdk.Meter(60),
        color: sdk.Color(0x332196F3), // Полупрозрачный синий
        strokeColor: sdk.Color(0x662196F3),
        strokeWidth: sdk.LogicalPixel(2),
        zIndex: sdk.ZIndex(1),
        userData: marker.toMap(),
      ),
    );
    mapObjectManager.addObject(outerCircle);

    // Основной круг
    final mainCircle = sdk.Circle(
      sdk.CircleOptions(
        position: position,
        radius: sdk.Meter(35),
        color: sdk.Color(0xFF2196F3), // Синий для событий
        strokeColor: sdk.Color(0xFFFFFFFF),
        strokeWidth: sdk.LogicalPixel(3),
        zIndex: sdk.ZIndex(2),
        userData: marker.toMap(),
      ),
    );
    mapObjectManager.addObject(mainCircle);

    // Внутренний символ
    final innerSymbol = sdk.Circle(
      sdk.CircleOptions(
        position: position,
        radius: sdk.Meter(15),
        color: sdk.Color(0xFFFFFFFF),
        zIndex: sdk.ZIndex(3),
        userData: marker.toMap(),
      ),
    );
    mapObjectManager.addObject(innerSymbol);
  }

  // Создает простой круглый маркер для обычных мест
  static void _createPlaceMarker(
    sdk.MapObjectManager mapObjectManager,
    MarkerModel marker,
  ) {
    final position = sdk.GeoPoint(
      latitude: sdk.Latitude(marker.latitude),
      longitude: sdk.Longitude(marker.longitude),
    );

    // Основной круг
    final mainCircle = sdk.Circle(
      sdk.CircleOptions(
        position: position,
        radius: sdk.Meter(30),
        color: sdk.Color(0xFF9E9E9E), // Серый для обычных мест
        strokeColor: sdk.Color(0xFFFFFFFF),
        strokeWidth: sdk.LogicalPixel(3),
        zIndex: sdk.ZIndex(2),
        userData: marker.toMap(),
      ),
    );
    mapObjectManager.addObject(mainCircle);

    // Внутренний символ
    final innerSymbol = sdk.Circle(
      sdk.CircleOptions(
        position: position,
        radius: sdk.Meter(12),
        color: sdk.Color(0xFFFFFFFF),
        zIndex: sdk.ZIndex(3),
        userData: marker.toMap(),
      ),
    );
    mapObjectManager.addObject(innerSymbol);
  }

  // Создает маркер с SVG иконкой из ассетов
  static Future<void> _createSimpleMarker(
    sdk.MapObjectManager mapObjectManager,
    MarkerModel marker,
    sdk.Context sdkContext,
  ) async {
    try {
      debugPrint('Создаем маркер с SVG иконкой для: ${marker.title}');

      // Создаем позицию маркера
      final position = sdk.GeoPointWithElevation(
        latitude: sdk.Latitude(marker.latitude),
        longitude: sdk.Longitude(marker.longitude),
      );

      // Определяем правильную SVG иконку
      final iconPath = _getSvgIconPath(marker);
      debugPrint('Используем SVG иконку: $iconPath');

      // Загружаем SVG иконку из ассетов
      final imageLoader = sdk.ImageLoader(sdkContext);
      final icon = await imageLoader.loadSVGFromAsset(iconPath);

      // Создаем стиль текста для маркера
      final textStyle = sdk.TextStyle(
        textPlacement: sdk.TextPlacement.topCenter, // Текст сверху по центру
        strokeWidth: sdk.LogicalPixel(2), // Толщина обводки
        textOffset: sdk.LogicalPixel(4), // Отступ от иконки
        strokeColor: sdk.Color(0xFF000000), // Черная обводка
        color: sdk.Color(0xFFFFFFFF), // Белый текст
        fontSize: sdk.LogicalPixel(12), // Размер шрифта
      );

      // Создаем маркер с SVG иконкой, текстом и стилем
      final markerObject = sdk.Marker(
        sdk.MarkerOptions(
          position: position,
          icon: icon,
          iconWidth: sdk.LogicalPixel(24), // Маленький размер маркеров
          text: _truncateText(marker.title, 20), // Добавляем текст к маркеру
          textStyle: textStyle, // Применяем стиль текста
          anchor: sdk.Anchor(
            x: 0.5, // Центр по X
            y: 0.5, // Центр по Y
          ),
          zIndex: sdk.ZIndex(10),
          userData: marker.toMap(),
        ),
      );

      // Добавляем маркер на карту
      mapObjectManager.addObject(markerObject);

      debugPrint('SVG маркер с текстом добавлен успешно: ${marker.title}');
    } catch (e) {
      debugPrint('Ошибка создания SVG маркера: $e');
      rethrow;
    }
  }

  // Определяет путь к SVG иконке в зависимости от типа и времени события
  static String _getSvgIconPath(MarkerModel marker) {
    if (marker.isLine) {
      // Для перекрытий используем icon3
      return 'assets/icon3.svg';
    }

    if (!marker.hasDate) {
      // Для событий без даты используем зеленый (идут сейчас)
      return 'assets/icon2.svg'; // Зеленый
    }

    // Для событий с датой определяем статус по времени
    try {
      final now = DateTime.now();
      final eventDate = _parseEventDate(marker.date);

      if (eventDate == null) {
        return 'assets/icon2.svg'; // Зеленый (идут сейчас) если не удалось распарсить дату
      }

      final difference = eventDate.difference(now).inHours;

      if (difference < -24) {
        // Событие прошло более суток назад - серый
        return 'assets/icon3.svg'; // Серый
      } else if (difference < 24) {
        // Событие происходит сейчас или в ближайшие сутки - зеленый
        return 'assets/icon2.svg'; // Зеленый (идут сейчас)
      } else {
        // Событие в будущем - синий
        return 'assets/icon1.svg'; // Синий (скоро)
      }
    } catch (e) {
      debugPrint('Ошибка определения времени события: $e');
      return 'assets/icon2.svg'; // Зеленый (идут сейчас) как fallback
    }
  }

  // Обрезает текст до указанной длины
  static String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength - 3)}...';
  }

  // Парсит дату события из строки
  static DateTime? _parseEventDate(String dateStr) {
    try {
      // Пробуем разные форматы дат
      if (dateStr.contains('.')) {
        // Формат DD.MM.YYYY или DD.MM.YYYY HH:mm
        final parts = dateStr.split(' ');
        final datePart = parts[0];
        final dateComponents = datePart.split('.');

        if (dateComponents.length >= 3) {
          final day = int.parse(dateComponents[0]);
          final month = int.parse(dateComponents[1]);
          final year = int.parse(dateComponents[2]);

          int hour = 12; // По умолчанию полдень
          int minute = 0;

          if (parts.length > 1 && parts[1].contains(':')) {
            final timeParts = parts[1].split(':');
            hour = int.parse(timeParts[0]);
            minute = int.parse(timeParts[1]);
          }

          return DateTime(year, month, day, hour, minute);
        }
      }

      // Пробуем стандартный ISO формат
      return DateTime.parse(dateStr);
    } catch (e) {
      debugPrint('Не удалось распарсить дату: $dateStr');
      return null;
    }
  }
}
