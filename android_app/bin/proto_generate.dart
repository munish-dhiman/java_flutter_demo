// bin/proto_generate.dart
import 'dart:io';

void main(List<String> args) async {
  try {
    final protoDir = _findProtosDir();
    final outDir = _findOutDir();

    // collect proto files
    final protoFiles = protoDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.proto'))
        .map((f) => f.path)
        .toList();

    if (protoFiles.isEmpty) {
      stderr.writeln('No .proto files found under ${protoDir.path}');
      exit(0);
    }

    // Ensure output directory exists
    Directory(outDir).createSync(recursive: true);

    final argsList = [
      '-I${protoDir.path}',
      '--dart_out=grpc:${outDir}',
      ...protoFiles,
    ];

    print('Running protoc with args:');
    print('  ' + argsList.join(' '));

    final result = await Process.run('protoc', argsList);

    if (result.exitCode != 0) {
      stderr.writeln(
          'protoc failed (exit ${result.exitCode}):\n${result.stderr}');
      exit(result.exitCode);
    } else {
      stdout.writeln('Protobufs generated into $outDir');
      if (result.stdout != null && result.stdout.toString().trim().isNotEmpty) {
        stdout.writeln(result.stdout);
      }
    }
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

Directory _findProtosDir() {
  final cwd = Directory.current;
  final scriptFile = File(Platform.script.toFilePath());
  final scriptDir = scriptFile.parent;

  final candidates = <Directory>[
    Directory('${cwd.path}${Platform.pathSeparator}protos'),
    // projectRoot/protos
    Directory('${scriptDir.path}${Platform.pathSeparator}protos'),
    // scriptDir/protos
    Directory('${scriptDir.parent.path}${Platform.pathSeparator}protos'),
    // parentOfScript/protos (common when script in bin/)
  ];

  for (final d in candidates) {
    if (d.existsSync()) return d;
  }

  // If nothing found, show diagnostics
  final tried = candidates.map((d) => d.path).join('\n  ');
  throw StateError('Could not find a protos/ directory. Tried:\n  $tried\n'
      'Run this script from the project root or place protos/ next to your script.');
}

String _findOutDir() {
  // Prefer putting generated code inside the project working directory:
  final cwd = Directory.current;
  final outDefault =
      '${cwd.path}${Platform.pathSeparator}lib${Platform.pathSeparator}src${Platform.pathSeparator}generated';
  return outDefault;
}
