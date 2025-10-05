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
  ) async {
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
          zIndex: sdk.ZIndex(1),
          userData: marker.toMap(),
        ),
      );

      mapObjectManager.addObject(circle);
    } catch (e) {
      debugPrint('Ошибка добавления маркера: $e');
    }
  }

  static Future<void> addLineToMap(
    sdk.MapObjectManager mapObjectManager,
    MarkerModel lineMarker,
    List<sdk.GeoPoint> points,
  ) async {
    if (points.isEmpty) return;

    try {
      final lineColor = ColorUtils.getLineColor(lineMarker.hasDate, lineMarker.title);

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
      
      if (maxDiff > 0.1) zoom = 10.0;
      else if (maxDiff > 0.05) zoom = 12.0;
      else if (maxDiff > 0.01) zoom = 14.0;
      else if (maxDiff > 0.005) zoom = 15.0;
      else zoom = 16.0;
    }

    return sdk.CameraPosition(
      point: sdk.GeoPoint(
        latitude: sdk.Latitude(centerLat),
        longitude: sdk.Longitude(centerLng),
      ),
      zoom: sdk.Zoom(zoom),
    );
  }

  static List<sdk.GeoPoint> parseLineCoordinates(String jsonString, String eventName, int closureIndex) {
    // Эта функция должна извлекать координаты линии из исходного JSON
    // Для упрощения возвращаем пустой список
    // В реальной реализации нужно сохранять исходные данные
    return [];
  }
}