/// Resultado de comparar la versión instalada con la publicada.
enum UpdateKind { none, optional, required }

/// Versión de la app: nombre visible (`1.2.2`) y número de build (`3`).
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.name, this.build);

  /// Acepta `1.2.2`, `1.2.2+3` o vacío (= desconocida).
  factory AppVersion.parse(String name, [Object? build]) {
    var n = name.trim();
    var b = int.tryParse('${build ?? ''}'.trim()) ?? 0;
    final plus = n.indexOf('+');
    if (plus >= 0) {
      b = int.tryParse(n.substring(plus + 1)) ?? b;
      n = n.substring(0, plus);
    }
    return AppVersion(n, b);
  }

  final String name;
  final int build;

  bool get isEmpty => name.isEmpty && build == 0;

  List<int> get _parts =>
      name.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();

  @override
  int compareTo(AppVersion other) {
    final a = _parts;
    final b = other._parts;
    final length = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < length; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return build.compareTo(other.build);
  }

  bool operator <(AppVersion other) => compareTo(other) < 0;

  @override
  String toString() => build > 0 ? '$name ($build)' : name;
}

/// Decide si hay que avisar de una actualización.
///
/// - `required`: la instalada es menor que la mínima permitida.
/// - `optional`: hay una más nueva publicada.
///
/// Una versión vacía en Remote Config se ignora.
UpdateKind evaluateUpdate({
  required AppVersion installed,
  required AppVersion latest,
  required AppVersion minimum,
}) {
  if (!minimum.isEmpty && installed < minimum) return UpdateKind.required;
  if (!latest.isEmpty && installed < latest) return UpdateKind.optional;
  return UpdateKind.none;
}
