import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ao_flutter_iap/ao_flutter_iap_method_channel.dart';

void main() {
  MethodChannelAoFlutterIap platform = MethodChannelAoFlutterIap();
  const MethodChannel channel = MethodChannel('ao_flutter_iap');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
