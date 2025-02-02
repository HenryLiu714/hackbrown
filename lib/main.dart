import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'constants.dart';
import 'dart:math';

void main() async {
  // Load env
 //  await dotenv.load(fileName: "../.env");
  // await dotenv.load(fileName: "../.env");

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
      title: 'henry and eggs',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(),
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

class HomeScreen extends StatelessWidget {
  final _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        scrollDirection: Axis.vertical,
        controller: _controller,
        children: [
          StartScreen(),
          Screen1(),
          Screen2()
        ],
      ),
    );
  }
}

class Screen1 extends StatelessWidget {
  const Screen1({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
    );
  }
}

class Screen2 extends StatelessWidget {
  const Screen2({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange,
    );
  }
}

// Start Screen 
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("../images/main_background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child:Center(
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
  // var appState = context.watch<MyAppState>;

  final Stopwatch _stopwatch = Stopwatch();
  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  late Timer _timer;
  int elapsedTime = 0;
  String placemarkText = "Fetching location....";

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    
  
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {}); // Updates the timer display
    });

    _getLocation();

  }

  Future<void> _getLocation() async {
  try {
    double latitude = 41.829528;
    double longitude = -71.401000;

    String? formattedAddress = await _reverseGeocode(latitude, longitude);
    if (formattedAddress == null) {
      setState(() {
        placemarkText = "No address found.";
      });
      return;
    }
    print(formattedAddress);

    // Step 2: Use Find Place API to get restaurant name
    String? placeName = await _findPlace(formattedAddress);
    setState(() {
      placemarkText = placeName ?? "No place found.";
    });
    
    print(placeName);

  } catch (e) {
    print("Error fetching location: $e");
    setState(() {
      placemarkText = "Error fetching location: $e";
    });
  }
}

// Function to reverse geocode (LatLng -> Address)
Future<String?> _reverseGeocode(double lat, double lng) async {
  final String key = GOOGLE_API_KEY ?? '';
  final response = await http.get(Uri.parse(
    'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$key'
  ));

  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    if (data['results'].isNotEmpty) {
      return data['results'][0]['formatted_address'];
    }
  }
  return null;
}

// Function to find place (Address -> Place Name)
Future<String?> _findPlace(String address) async {
  final String key = GOOGLE_API_KEY ?? '';

  String passing_string = "Restaurant within 10 feet of  " + address;
  final response = await http.post(
    Uri.parse('https://places.googleapis.com/v1/places:searchText'),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'X-Goog-FieldMask' : 'places.displayName,places.formattedAddress,places.priceLevel',
      'X-Goog-Api-Key' : key,
    },
    body: jsonEncode(<String, String>{
      'textQuery' : passing_string,
    }),
  );

  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    if (data['places'] != null && data['places'].isNotEmpty) {
      String placeName = data['places'][0]['displayName']['text'];
      print("Place Name: $placeName"); // Use setState if in a Flutter app
      return placeName;
    } else {
      print("No place found.");
    }
  }
  return null;
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
          const SizedBox(height: 20),
          Text(
            placemarkText, // Display location/restaurant name here
            style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
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


class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({Key? key}) : super(key: key);

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  List<String> restaurantList = [];
  String recommendedRestaurant = 'Press the button to get a recommendation';

  Future<void> _getRecommendation() async {
    try {
      double latitude = 41.829528;
      double longitude = -71.401000;

      String? formattedAddress = await _reverseGeocode(latitude, longitude);
      if (formattedAddress == null) {
        setState(() {
          recommendedRestaurant = "No address found.";
        });
        return;
      }
      print(formattedAddress);

      String? placeName = await _findPlace(formattedAddress);
      setState(() {
        recommendedRestaurant = placeName ?? "No place found.";
      });
      
      print(placeName);

    } catch (e) {
      print("Error fetching location: $e");
      setState(() {
        recommendedRestaurant = "Error fetching location: $e";
      });
    }
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
  final String key = dotenv.env['GOOGLE_API_KEY'] ?? '';
  final response = await http.get(Uri.parse(
    'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$key'
  ));

  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    if (data['results'].isNotEmpty) {
      return data['results'][0]['formatted_address'];
    }
  }
  return null;
}

// Function to find place (Address -> Place Names)
  Future<String?> _findPlace(String address) async {
  final String key = dotenv.env['GOOGLE_API_KEY'] ?? '';

  String passing_string = "Restaurants within 10 miles of  " + address;
  final response = await http.post(
    Uri.parse('https://places.googleapis.com/v1/places:searchText'),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'X-Goog-FieldMask' : 'places.displayName,places.formattedAddress,places.priceLevel',
      'X-Goog-Api-Key' : key,
    },
    body: jsonEncode(<String, String>{
      'textQuery' : passing_string,
    }),
  );
  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    if (data['places'] != null && data['places'].isNotEmpty) {
      for (var place in data['places']) {
        restaurantList.add(place['displayName']['text']);
      }
    }
    else {
      print("No places found.");
    }
  }

  if (restaurantList.isNotEmpty) {
      final randomIndex = Random().nextInt(restaurantList.length);
      setState(() {
        recommendedRestaurant = restaurantList[randomIndex];
      });
    } else {
      setState(() {
        recommendedRestaurant = 'No restaurants available.';
      });
    }
  return null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Recommendation'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              recommendedRestaurant,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getRecommendation,
              child: const Text('Recommend'),
            ),
          ],
        ),
      ),
    );
  }
}