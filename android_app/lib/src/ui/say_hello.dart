import 'package:flutter/material.dart';
import '../remote/grpc/grpc_client.dart';
import '../../src/generated/hello.pb.dart';

class SayHello extends StatefulWidget {
  const SayHello({Key? key}) : super(key: key);

  @override
  _SayHelloState createState() => _SayHelloState();
}

class _SayHelloState extends State<SayHello> {
  final GrpcClient _grpcClient = GrpcClient();
  final TextEditingController _controller = TextEditingController();
  String _response = '';

  Future<void> _callSayHello() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    try {
      final helloRequest = HelloRequest(name: name);
      var helloClient = await _grpcClient.helloClient;
      final reply = await helloClient.sayHello(helloRequest);
      setState(() => _response = reply.message);
    } catch (e) {
      setState(() => 'Error calling Hello RPC: $e');
    }
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
            Text("Say Hello"),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: "Enter your name"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _callSayHello,
              child: const Text("Submit"),
            ),
            const SizedBox(height: 10),
            Text("Response: $_response"),
          ],
        ),
      ),
    );
  }
}
