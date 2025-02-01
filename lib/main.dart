import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:provider/provider.dart';
import 'dart:async';

void main() async {
  // Load env
  await dotenv.load(fileName: "../.env");

  // Load mongodb
  print("Connecting to mongodb");
  // await UserDB.inst.init();
  print("connected to mongodb");

  runApp(const MyApp());
}

class UserDB {
  late mongo.DbCollection user_info;

  UserDB._();

  static UserDB? _instance;
  static UserDB get inst => _instance ??= UserDB._();

  init () async {
    final connection_url = dotenv.env['CONNECTION_STRING']!;

    var db = await mongo.Db.create("mongodb+srv://henryliu714:z6HbUn0hlP5sQtUP@hackbrown.b8rd7.mongodb.net/?retryWrites=true&w=majority&appName=hackbrown&tls=true");
    await db.open();

    var status = db.serverStatus();
    print(status);
  
    print("done");

    user_info = db.collection('user_info');
  }
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

class MyAppState extends ChangeNotifier {
  // stuff
  dynamic retrieveUser(userId) async {
    var collection = UserDB.inst.user_info;
    var users = await collection.find(mongo.where.eq("user_id", userId)).toList();
    return users.first;
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
    var appState = context.watch<MyAppState>();
    var user_name = appState.retrieveUser("user_id")["name"];

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Score",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          Text(
            "$user_name"
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
