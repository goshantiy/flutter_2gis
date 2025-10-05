import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class ColorUtils {
  /// Получить цвет маркера в зависимости от наличия даты
  static int getMarkerColor(bool hasDate) {
    return hasDate 
        ? AppConstants.markerWithDateColor 
        : AppConstants.markerWithoutDateColor;
  }
  
  /// Получить цвет линии в зависимости от наличия даты и заголовка
  static int getLineColor(bool hasDate, String title) {
    final colors = hasDate 
        ? AppConstants.lineColorsWithDate 
        : AppConstants.lineColorsWithoutDate;
    
    final colorIndex = title.hashCode.abs() % colors.length;
    return colors[colorIndex];
  }
  
  /// Конвертировать int цвет в Color для Flutter UI
  static Color intToColor(int colorValue) {
    return Color(colorValue);
  }
  
  /// Получить цвет для успешных операций
  static Color get successColor => Colors.green;
  
  /// Получить цвет для ошибок
  static Color get errorColor => Colors.red;
  
  /// Получить цвет для предупреждений
  static Color get warningColor => Colors.orange;
}