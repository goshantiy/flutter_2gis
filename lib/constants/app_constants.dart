class AppConstants {
  // Настройки карты
  static const double defaultLatitude = 55.7539;
  static const double defaultLongitude = 37.6156;
  static const double defaultZoom = 11.0;
  static const double markerRadius = 50.0;
  static const double lineWidth = 8.0;
  
  // Цвета маркеров
  static const int markerWithDateColor = 0xFF2196F3; // Blue
  static const int markerWithoutDateColor = 0xFFFF5722; // Red
  static const int markerStrokeColor = 0xFFFFFFFF; // White
  
  // Цвета линий
  static const List<int> lineColorsWithDate = [
    0xFFFF9800, // Orange
    0xFFFF5722, // Deep Orange
    0xFFFFC107, // Amber
  ];
  
  static const List<int> lineColorsWithoutDate = [
    0xFF9C27B0, // Purple
    0xFF673AB7, // Deep Purple
    0xFF3F51B5, // Indigo
  ];
  
  // UI настройки
  static const double mapHeightRatio = 0.4;
  static const double textFieldHeight = 300.0;
  static const double strokeWidth = 2.0;
  
  // Тексты
  static const String appTitle = '2GIS Maps & Events';
  static const String sdkNotInitialized = 'SDK не инициализирован';
  static const String jsonHintText = 'Вставьте JSON данные событий здесь...';
  
  // Сообщения
  static const String loadingSuccess = 'JSON успешно загружен';
  static const String parseError = 'Ошибка парсинга JSON';
  static const String loadingError = 'Ошибка загрузки';
  static const String noObjectsFound = 'Не найдено объектов для отображения';
}