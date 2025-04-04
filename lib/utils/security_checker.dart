import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

Future<void> checkDeviceSecurity() async {
  bool isJailBroken = await FlutterJailbreakDetection.jailbroken;
  bool isInDeveloperMode = await FlutterJailbreakDetection.developerMode; // Android only

  if (isJailBroken || isInDeveloperMode) {
    // Handle the security risk appropriately
    print("Security risk detected!");
  } else {
    print("Device is secure.");
  }
}

