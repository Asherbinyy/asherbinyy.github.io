import 'dart:convert';
import 'dart:io';

/// Writes `assets/build_facts.json` from artifacts this repository produces.
///
/// `/how-it-was-built` states coverage and test counts publicly, so those
/// numbers have to be true on the day they are shown. Hard-coding them would
/// make the page stale the first time a test was added — and a page whose
/// whole argument is "this was built carefully" cannot afford a wrong number
/// about itself.
///
/// Every figure here is read from something the build already generates:
/// coverage from `coverage/lcov.info`, test counts from a machine-readable
/// test run, and the Lighthouse floors from the CI workflow itself. Nothing is
/// supplied by hand, so nothing can drift.
///
/// Run: `fvm dart run tool/generate_build_facts.dart`
Future<void> main(List<String> arguments) async {
  final root = Directory.current;
  final facts = <String, Object?>{
    'generatedAt': DateTime.now().toUtc().toIso8601String().split('T').first,
    ...await _coverage(File('${root.path}/coverage/lcov.info')),
    ...await _tests(root),
    ..._lighthouse(File('${root.path}/.github/workflows/ci.yml')),
  };

  final output = File('${root.path}/assets/build_facts.json');
  await output.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(facts)}\n',
  );
  stdout.writeln('Wrote ${output.path}');
  for (final entry in facts.entries) {
    stdout.writeln('  ${entry.key}: ${entry.value}');
  }
}

/// Line coverage, summed straight from the lcov records.
Future<Map<String, Object?>> _coverage(File lcov) async {
  if (!lcov.existsSync()) return const {'coveragePercent': null};

  var found = 0;
  var hit = 0;
  for (final line in await lcov.readAsLines()) {
    if (line.startsWith('LF:')) found += int.parse(line.substring(3));
    if (line.startsWith('LH:')) hit += int.parse(line.substring(3));
  }
  if (found == 0) return const {'coveragePercent': null};

  return {
    'coveragePercent': double.parse((hit / found * 100).toStringAsFixed(2)),
    'coveredLines': hit,
    'totalLines': found,
  };
}

/// Test counts, from a JSON test run rather than a parsed summary line.
Future<Map<String, Object?>> _tests(Directory root) async {
  // Locally every command goes through FVM so the pinned SDK is used. CI
  // installs that same version directly and has no `fvm` on PATH, so fall
  // back rather than making the workflow special-case this one tool.
  final hasFvm = (await Process.run('which', ['fvm'])).exitCode == 0;
  final result = await Process.run(hasFvm ? 'fvm' : 'flutter', [
    if (hasFvm) 'flutter',
    'test',
    '--reporter',
    'json',
  ], workingDirectory: root.path);

  var dart = 0;
  for (final line in const LineSplitter().convert(result.stdout.toString())) {
    if (!line.startsWith('{')) continue;
    final Object? event = jsonDecode(line);
    if (event is! Map<String, dynamic>) continue;
    // Every finished test reports once; group and suite events do not.
    if (event['type'] == 'testDone' && event['hidden'] != true) dart++;
  }

  final worker = await Process.run('node', [
    '--test',
    'worker/test/index.test.js',
  ], workingDirectory: root.path);
  final workerMatch = RegExp(
    r'^# pass (\d+)$',
    multiLine: true,
  ).firstMatch(worker.stdout.toString());

  return {
    'dartTests': dart,
    'workerTests': int.tryParse(workerMatch?.group(1) ?? '') ?? 0,
  };
}

/// The floors CI actually enforces, read from the workflow rather than retyped.
Map<String, Object?> _lighthouse(File workflow) {
  if (!workflow.existsSync()) return const {};
  final source = workflow.readAsStringSync();

  double? floor(String category) => double.tryParse(
    RegExp('categories:$category="error\\|minScore:([0-9.]+)"')
            .firstMatch(source)
            ?.group(1) ??
        '',
  );

  return {
    'lighthousePerformanceFloor': floor('performance'),
    'lighthouseAccessibilityFloor': floor('accessibility'),
  };
}
