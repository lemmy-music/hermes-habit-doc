class CustomWidget {
  final int? id;
  final String name;
  final FieldType fieldType;
  final DateTime createdAt;

  CustomWidget({
    this.id,
    required this.name,
    required this.fieldType,
    required this.createdAt,
  });
}

enum FieldType {
  number,
  slider,
  checkbox,
}

class TrackingEvent {
  final int? id;
  final int widgetId;
  final dynamic value;
  final DateTime timestamp;

  TrackingEvent({
    this.id,
    required this.widgetId,
    required this.value,
    required this.timestamp,
  });
}

class Correlation {
  final int widget1Id;
  final int widget2Id;
  final double coefficient; // -1 to 1
  final int sampleSize;

  Correlation({
    required this.widget1Id,
    required this.widget2Id,
    required this.coefficient,
    required this.sampleSize,
  });
}
