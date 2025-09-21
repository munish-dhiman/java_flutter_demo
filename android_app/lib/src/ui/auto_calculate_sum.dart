import 'dart:async';
import 'dart:math';
import 'package:fixnum/src/int64.dart';

import 'package:flutter/material.dart';

import '../remote/grpc/grpc_client.dart';
import '../../src/generated/hello.pb.dart';

class AutoCalculateSum extends StatefulWidget {
  const AutoCalculateSum({Key? key}) : super(key: key);

  @override
  _AutoCalculateSumState createState() => _AutoCalculateSumState();
}

class _AutoCalculateSumState extends State<AutoCalculateSum> {
  final _grpcClient = GrpcClient();
  final Random _random = Random();
  Timer? _timer;
  int _a = 0, _b = 0;
  String _result = "Auto Sum will be shown here";

  @override
  void initState() {
    super.initState();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => _generateAndSum());
  }

  Future<void> _generateAndSum() async {
    final a = _random.nextInt(100);
    final b = _random.nextInt(100);
    try {
      final request = SumRequest()
        ..argOne = Int64(a)
        ..argTwo = Int64(b);
      final sumClient = await _grpcClient.sumClient;
      final sum = await sumClient.sum(request);
      setResult(a, b, 'Sum: ${sum.result}');
    } catch (e) {
      setResult(a, b, 'Error calling Sum RPC: $e');
    }
  }

  void setResult(int a, int b, String e) {
    setState(() {
      _a = a;
      _b = b;
      _result = e;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Auto Sum (updates every second)"),
            Text("a = $_a, b = $_b"),
            Text("Sum = $_result"),
          ],
        ),
      ),
    );
  }
}
