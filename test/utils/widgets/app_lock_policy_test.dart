import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/utils/widgets/app_lock_policy.dart';

void main() {
  late DateTime now;
  late AppLockPolicy policy;

  setUp(() {
    now = DateTime(2026, 10, 5, 10);
    policy = AppLockPolicy(now: () => now);
  });

  test('el diálogo biométrico (inactive → resumed) no vuelve a bloquear', () {
    expect(policy.shouldLockOn(AppLifecycleState.inactive), isFalse);
    expect(policy.shouldLockOn(AppLifecycleState.resumed), isFalse);
  });

  test('volver de segundo plano sí bloquea', () {
    policy.shouldLockOn(AppLifecycleState.inactive);
    policy.shouldLockOn(AppLifecycleState.hidden);
    policy.shouldLockOn(AppLifecycleState.paused);
    expect(policy.shouldLockOn(AppLifecycleState.resumed), isTrue);
    // Un segundo resumed sin pasar por segundo plano no bloquea de nuevo.
    expect(policy.shouldLockOn(AppLifecycleState.resumed), isFalse);
  });

  test('no bloquea justo después de un desbloqueo exitoso', () {
    policy.markUnlocked();
    policy.shouldLockOn(AppLifecycleState.paused);
    now = now.add(const Duration(milliseconds: 500));
    expect(policy.shouldLockOn(AppLifecycleState.resumed), isFalse);

    now = now.add(const Duration(minutes: 1));
    policy.shouldLockOn(AppLifecycleState.paused);
    expect(policy.shouldLockOn(AppLifecycleState.resumed), isTrue);
  });
}
