import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ao_flutter_iap_platform_interface.dart';

/// An implementation of [AoFlutterIapPlatform] that uses method channels.
class MethodChannelAoFlutterIap extends AoFlutterIapPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ao_flutter_iap');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
