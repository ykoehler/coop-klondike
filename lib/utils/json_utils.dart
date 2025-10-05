List<dynamic> normalizeDynamicList(dynamic data) {
  if (data is List) {
    return data;
  }
  if (data is Map) {
    final keys = data.keys.toList()
      ..sort(_compareDynamicKeys);
    return keys.map((key) => data[key]).toList();
  }
  return const [];
}

List<Map<String, dynamic>> normalizeMapList(dynamic data) {
  final result = <Map<String, dynamic>>[];
  for (final entry in normalizeDynamicList(data)) {
    if (entry is Map) {
      result.add(Map<String, dynamic>.from(entry));
    }
  }
  return result;
}

int _compareDynamicKeys(dynamic a, dynamic b) {
  final aInt = int.tryParse(a.toString());
  final bInt = int.tryParse(b.toString());
  if (aInt != null && bInt != null) {
    return aInt.compareTo(bInt);
  }
  return a.toString().compareTo(b.toString());
}
