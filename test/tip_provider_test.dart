import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/features/tips/tip_provider.dart';

void main() {
  test('TipProvider returns a tip', () {
    final TipProvider provider = TipProvider();
    expect(provider.todayTip.isNotEmpty, true);
  });
}
