import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as dgis;
import 'pages/geojson_points.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Загружаем API ключ из assets
  String? apiKey;
  try {
    apiKey = await rootBundle.loadString('assets/dgissdk.key');
  } catch (e) {
    debugPrint('Ошибка загрузки API ключа: $e');
  }

  // Инициализируем 2GIS SDK
  dgis.Context? sdkContext;
  try {
    if (apiKey != null && apiKey.isNotEmpty) {
      sdkContext = await dgis.DGis.initialize();
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
      home: GeoJsonPointsPage(sdkContext: sdkContext),
    );
  }
}
