import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/engine/engine_controller.dart';
import 'src/licenses.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(thirdPartyLicenses);
  final controller = EngineController();
  await controller.init();
  runApp(NoMosi9aApp(controller: controller));
}
