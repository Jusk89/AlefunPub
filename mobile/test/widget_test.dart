import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_loyalty_mobile/main.dart';

void main() {
  testWidgets('LoyaltyApp can be constructed', (WidgetTester tester) async {
    expect(const LoyaltyApp(), isA<Widget>());
  });
}
