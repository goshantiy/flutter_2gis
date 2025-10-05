import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../data/sample_data.dart';

class DataLoaderService {
  static Future<String?> loadFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        String content = '';
        
        if (file.bytes != null) {
          content = String.fromCharCodes(file.bytes!);
        } else if (file.path != null) {
          final fileContent = await File(file.path!).readAsString();
          content = fileContent;
        } else {
          throw Exception('Не удалось получить содержимое файла');
        }

        if (content.isNotEmpty) {
          return content;
        } else {
          throw Exception('Файл пустой');
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  static Future<String> loadFromUrl(String url) async {
    if (url.trim().isEmpty) {
      throw Exception('URL не может быть пустым');
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static String getSampleJson() {
    return SampleData.eventsJson;
  }
  
  static String getSampleGeoJson() {
    return SampleData.geoJsonSample;
  }
}