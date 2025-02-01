import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}


// Main App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stopwatch App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const StartScreen(),
    );
  }
}


// Start Screen 
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Start Stopwatch")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StopwatchScreen()),
            );
          },
          child: const Text("Start"),
        ),
      ),
    );
  }
}
// State for Start State
class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}


// Second Screen for StopWatch to show timer as well as end Button 
class _StopwatchScreenState extends State<StopwatchScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  int elapsedTime = 0;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {}); // Updates the timer display
    });
  }

  void endTimer() {
    _timer.cancel();
    _stopwatch.stop();
    setState(() {
      elapsedTime = _stopwatch.elapsedMilliseconds;
    });

    // TODO
    // Go to third page or store
    Navigator.pop(context, elapsedTime);
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Score",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            "${_stopwatch.elapsed.inSeconds}.${(_stopwatch.elapsedMilliseconds % 1000) ~/ 100}",
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: endTimer,
            child: const Text("End"),
          ),
        ],
      ),
    );
  }
}
