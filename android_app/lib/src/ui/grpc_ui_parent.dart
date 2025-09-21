import 'package:android_app/src/ui/calculate_sum.dart';
import 'package:android_app/src/ui/say_hello.dart';
import 'package:flutter/material.dart';

import 'auto_calculate_sum.dart';

class GrpcUiParent extends StatelessWidget {
  const GrpcUiParent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("gRPC UI Demo")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AutoCalculateSum(),
            CalculateSum(),
            SayHello(),
          ],
        ),
      ),
    );
  }
}
