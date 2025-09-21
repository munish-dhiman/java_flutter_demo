import 'package:fixnum/src/int64.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/generated/hello.pb.dart';
import '../remote/grpc/grpc_client.dart';

class CalculateSum extends StatefulWidget {
  const CalculateSum({super.key});

  @override
  State<CalculateSum> createState() => _CalculateSumState();
}

class _CalculateSumState extends State<CalculateSum> {
  final _grpcClient = GrpcClient();
  final _num1Controller = TextEditingController();
  final _num2Controller = TextEditingController();

  String _resultText = 'Result will be shown here';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _calculateSum() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    final num1 = int.tryParse(_num1Controller.text);
    final num2 = int.tryParse(_num2Controller.text);

    if (num1 == null || num2 == null) {
      setState(() {
        _resultText = 'Please enter valid integer values in both fields.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _resultText = 'Calculating...';
    });

    try {
      final request = SumRequest()
        ..argOne = Int64(num1)
        ..argTwo = Int64(num2);

      var sumClient = await _grpcClient.sumClient;
      final response = await sumClient.sum(request);

      setState(() {
        _resultText = 'Sum: ${response.result}';
      });
    } catch (e) {
      setState(() {
        _resultText = 'Error calling Sum RPC: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _num1Controller.dispose();
    _num2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _num1Controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'First Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _num2Controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Second Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _calculateSum,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Calculate Sum'),
            ),
            const SizedBox(height: 24),
            Text(
              _resultText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
