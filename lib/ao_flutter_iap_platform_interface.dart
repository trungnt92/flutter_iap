import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ao_flutter_iap_method_channel.dart';

abstract class AoFlutterIapPlatform extends PlatformInterface {
  /// Constructs a AoFlutterIapPlatform.
  AoFlutterIapPlatform() : super(token: _token);

  static final Object _token = Object();

  static AoFlutterIapPlatform _instance = MethodChannelAoFlutterIap();

  /// The default instance of [AoFlutterIapPlatform] to use.
  ///
  /// Defaults to [MethodChannelAoFlutterIap].
  static AoFlutterIapPlatform get instance => _instance;
  
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AoFlutterIapPlatform] when
  /// they register themselves.
  static set instance(AoFlutterIapPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
