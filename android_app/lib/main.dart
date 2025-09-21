import 'package:android_app/src/ui/grpc_ui_parent.dart';
import 'package:flutter/material.dart';

import '/src/config/env_loader.dart';

void main() async {
  await loadEnv();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      home: const GrpcUiParent(),
    );
  }
}
