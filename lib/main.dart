import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 8, 142, 160)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const MetronomePage(),
    );
  }
}

class MetronomePage extends HookConsumerWidget {
  const MetronomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bpm = ref.watch(metronomeProvider);
    final isFlash = useState(false);

    useEffect(() {
      final subscribe =
          ref.watch(metronomeProvider.notifier).onFlash.listen((_) {
        isFlash.value = true;
      });
      return subscribe.cancel;
    }, [bpm]);

    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 10),
            decoration: BoxDecoration(
              color: isFlash.value
                  ? Colors.white
                  : Theme.of(context).colorScheme.surface,
            ),
            curve: Curves.easeOutExpo,
            onEnd: () {
              isFlash.value = false;
            },
          ),
          const Center(
            child: _Metronome(),
          ),
        ],
      ),
    );
  }
}

class _Metronome extends ConsumerWidget {
  const _Metronome({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bpm = ref.watch(metronomeProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('BPM', style: Theme.of(context).textTheme.displayMedium),
        Slider(
            min: 1,
            max: 300,
            divisions: 30,
            value: bpm.toDouble(),
            onChanged: (value) {
              ref.read(metronomeProvider.notifier).update(value.toInt());
            }),
        Text(
          '$bpm',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () {
              ref.read(metronomeProvider.notifier).play();
            },
            child: const Text('Start'),
          ),
        ),
      ],
    );
  }
}

final metronomeProvider =
    NotifierProvider<MetronomeController, int>(() => MetronomeController());

class MetronomeController extends Notifier<int> {
  Timer? timer;
  static const initBpm = 120;

  static int bpmToMs(int bpm) => (60 / bpm * 1000).ceil();

  final StreamController<void> _flashController =
      StreamController<void>.broadcast();

  Stream<void> get onFlash => _flashController.stream;

  @override
  int build() => initBpm;

  void play() {
    timer?.cancel();
    timer = Timer.periodic(
      Duration(milliseconds: bpmToMs(state)),
      (_) {
        _flashController.add(null);
      },
    );
  }

  void stop() {
    timer?.cancel();
  }

  void update(int int) {
    stop();
    state = int;
  }
}
