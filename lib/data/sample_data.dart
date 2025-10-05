class SampleData {
  static const String eventsJson = '''
{
  "events": [
    {
      "name": "Фестиваль «Спасская башня»",
      "description": "Музыкальный праздник military tattoo, проходящий в Москве",
      "date": {
        "start": "06.10.2025",
        "end": "12.10.2025"
      },
      "POI": [[37.620245338778268, 55.754154717527896]],
      "closures": [
        {
          "type": "LineString",
          "coordinates": [
            [37.6156, 55.7539],
            [37.6180, 55.7560],
            [37.6200, 55.7580]
          ]
        }
      ]
    },
    {
      "name": "Фестиваль фестивалей",
      "days": [
        {
          "description": "Первый день фестиваля, очень весело",
          "POI": [[37.62024533877827, 55.754154717527896]],
          "date": {
            "start": "05.10.2025 18:00",
            "end": "05.10.2025 23:00"
          },
          "closures": []
        }
      ]
    },
    {
      "name": "ВДНХ",
      "description": "Специальная программа с анимационной вечеринкой",
      "date": {
        "start": "03.10.2025",
        "end": "12.12.2025"
      },
      "POI": [[37.629277, 55.831388]]
    },
    {
      "name": "Парк Горького",
      "description": "Концерт под открытым небом",
      "date": {
        "start": "15.10.2025",
        "end": "15.10.2025"
      },
      "POI": [[37.601194, 55.728083]],
      "closures": [
        {
          "type": "LineString",
          "coordinates": [
            [37.600000, 55.727000],
            [37.602000, 55.729000],
            [37.604000, 55.731000]
          ]
        }
      ]
    }
  ]
}''';

  static const String geoJsonSample = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [37.6173, 55.7558]
      },
      "properties": {
        "name": "Красная площадь",
        "description": "Главная площадь Москвы",
        "date": "01.01.2025"
      }
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "LineString",
        "coordinates": [
          [37.6156, 55.7539],
          [37.6180, 55.7560],
          [37.6200, 55.7580]
        ]
      },
      "properties": {
        "name": "Маршрут экскурсии",
        "description": "Пешеходный маршрут по центру Москвы"
      }
    }
  ]
}''';
}