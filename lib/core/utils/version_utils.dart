class VersionUtils {
  static List<int> _parse(String version) {
    return version
        .split('.')
        .take(3)
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
  }

  static int compare(String a, String b) {
    final aParts = _parse(a);
    final bParts = _parse(b);

    for (var i = 0; i < 3; i++) {
      final aVal = i < aParts.length ? aParts[i] : 0;
      final bVal = i < bParts.length ? bParts[i] : 0;
      if (aVal != bVal) return aVal.compareTo(bVal);
    }
    return 0;
  }

  static bool isOlder(String current, String latest) {
    return compare(current, latest) < 0;
  }
}
