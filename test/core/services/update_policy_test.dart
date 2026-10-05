import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/services/update_policy.dart';
import 'package:personal_finance/core/services/version_service.dart';

void main() {
  AppVersion v(String s) => AppVersion.parse(s);

  test('compara versión y build', () {
    expect(v('1.2.2+3') < v('1.2.2+4'), isTrue);
    expect(v('1.2.2+9') < v('1.2.10+1'), isTrue);
    expect(v('1.10.0') < v('1.9.9'), isFalse);
    expect(AppVersion.parse('1.2.2', '5').build, 5);
    expect(v('1.2.2+3').toString(), '1.2.2 (3)');
  });

  test('aviso opcional cuando hay una versión más nueva', () {
    expect(
      evaluateUpdate(
        installed: v('1.2.2+2'),
        latest: v('1.2.2+3'),
        minimum: v(''),
      ),
      UpdateKind.optional,
    );
  });

  test('obligatoria cuando la instalada es menor que la mínima', () {
    expect(
      evaluateUpdate(
        installed: v('1.1.4+5'),
        latest: v('1.2.2+3'),
        minimum: v('1.2.0'),
      ),
      UpdateKind.required,
    );
  });

  test('sin aviso si ya está al día o no hay datos', () {
    expect(
      evaluateUpdate(
        installed: v('1.2.2+3'),
        latest: v('1.2.2+3'),
        minimum: v('1.0.0'),
      ),
      UpdateKind.none,
    );
    expect(
      evaluateUpdate(installed: v('1.2.2+3'), latest: v(''), minimum: v('')),
      UpdateKind.none,
    );
  });

  test('el versionCode de Android vuelve al build del pubspec', () {
    expect(VersionService.androidBuildToPubspec(1000007), 7);
    expect(VersionService.androidBuildToPubspec(7), 7);
  });
}
