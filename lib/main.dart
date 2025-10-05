import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as dgis;
import 'pages/events_map_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Загружаем API ключ из assets
  String? apiKey;
  try {
    apiKey = await rootBundle.loadString('assets/dgissdk.key');
    debugPrint('API ключ загружен: ${apiKey.isNotEmpty ? "✓" : "✗"}');
  } catch (e) {
    debugPrint('Ошибка загрузки API ключа: $e');
  }

  // Инициализируем 2GIS SDK
  dgis.Context? sdkContext;
  try {
    if (apiKey != null && apiKey.isNotEmpty) {
      debugPrint('Инициализируем 2GIS SDK...');
      sdkContext = await dgis.DGis.initialize();
      debugPrint('2GIS SDK инициализирован: ✓');
    } else {
      debugPrint('API ключ пустой или не найден');
    }
  } catch (e) {
    debugPrint('Ошибка инициализации SDK: $e');
  }

  runApp(MyApp(sdkContext: sdkContext));
}

class MyApp extends StatelessWidget {
  final dgis.Context? sdkContext;

  const MyApp({super.key, this.sdkContext});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2GIS Maps & GeoJSON',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: EventsMapPage(sdkContext: sdkContext),
    );
  }
}
