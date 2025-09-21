import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> loadEnv() async {
  final env = const String.fromEnvironment('ENV', defaultValue: 'dev');
  await dotenv.load(fileName: '.env.$env');
}
