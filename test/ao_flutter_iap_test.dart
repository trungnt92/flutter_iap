import 'package:flutter_test/flutter_test.dart';
import 'package:ao_flutter_iap/ao_flutter_iap.dart';
import 'package:ao_flutter_iap/ao_flutter_iap_platform_interface.dart';
import 'package:ao_flutter_iap/ao_flutter_iap_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAoFlutterIapPlatform 
    with MockPlatformInterfaceMixin
    implements AoFlutterIapPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AoFlutterIapPlatform initialPlatform = AoFlutterIapPlatform.instance;

  test('$MethodChannelAoFlutterIap is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAoFlutterIap>());
  });

  test('getPlatformVersion', () async {
    AoFlutterIap aoFlutterIapPlugin = AoFlutterIap();
    MockAoFlutterIapPlatform fakePlatform = MockAoFlutterIapPlatform();
    AoFlutterIapPlatform.instance = fakePlatform;
  
    expect(await aoFlutterIapPlugin.getPlatformVersion(), '42');
  });
}
