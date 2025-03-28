import 'dart:js_interop';
import 'dart:js_interop_unsafe';

extension JSObjectExtension on JSObject {
  String? getStringProperty(String key) {
    final jsKey = key.toJS; // Convert Dart string to JSString

    final value = getProperty(jsKey);
    return switch (value) { JSString() => (value).toDart, _ => null };
  }
}

JSObject mapToJSObject(Map<String, dynamic> dartMap) {
  final jsObject = JSObject();

  for (var entry in dartMap.entries) {
    final key = entry.key.toJS; // Convert Dart String to JSString
    final value = entry.value;

    if (value is String) {
      jsObject.setProperty(key, value.toJS);
    } else if (value is num) {
      jsObject.setProperty(key, value.toJS);
    } else if (value is bool) {
      jsObject.setProperty(key, value.toJS);
    } else if (value == null) {
    } else if (value is Map<String, dynamic>) {
      // Recursively convert nested map to JSObject
      jsObject.setProperty(key, mapToJSObject(value));
    } else {
      throw Exception(
          "Unsupported type for key '${entry.key}': ${value.runtimeType}");
    }
  }

  return jsObject;
}
