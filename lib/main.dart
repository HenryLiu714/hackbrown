import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:core';

import 'constants.dart';
import 'dart:math';
import 'dart:developer';

class CurrentUser {
  static final int user_id = 1;
  late Map<String, dynamic> user;
  late List<Map<String, dynamic>> friends;

  CurrentUser._();
  static CurrentUser? _instance;
  static CurrentUser get inst => _instance ??= CurrentUser._();
  init() async {
    user = await fetchUser(user_id);
    friends = [];

    for (var friendId in user['friends']) {
      friends.add(await fetchUser(friendId));
    }
  }
}

void main() async {
  await CurrentUser.inst.init();
  runApp(const MyApp());
}

dynamic fetchUser(userId) async {
  final String url = 'http://127.0.0.1:5000/items?user_id=$userId';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      Map<String, dynamic> user = json.decode(response.body)[0];

      user['restaurant_times'] = {};

      for (Map<String, dynamic> restaurant in user['restaurants']) {
        final start  = DateTime.parse(restaurant['time_visited']);
        final end = DateTime.parse(restaurant['time_left']);

        final difference = end.difference(start).inSeconds;
        
        if (user['restaurant_times'].containsKey(restaurant['name'])) {
          user['restaurant_times'][restaurant['name']] += difference;
        } else {
          user['restaurant_times'][restaurant['name']] = difference;
        }
      }

      int totalRestaurantTime() {
        var sum = 0;
        for (var time in user['restaurant_times'].values) {
          sum += time as int;
        }

        return sum;
      }

      user['total_restaurant_time'] = totalRestaurantTime();

      return user;

    } else {
      throw Exception('Failed to load user');
    }
  } catch (e) {
    print('Error: $e');
  }
}

// Main App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    fetchUser(1);
    return MaterialApp(
      title: 'henry and eggs',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Arcade'
      ),
      home: HomeScreen(),
    );
  }
}

class MyAppState extends ChangeNotifier {
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 1);
  }

  final PageController _controller2 = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
  children: [
     Positioned.fill(
            child: Image.asset(
              '../assets/main_background.png', // Replace with your image asset
              fit: BoxFit.cover,
            ),
          ),
    PageView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      children: [
        RecommendationScreen(),
        PageView(
          controller: _controller2,
          scrollDirection: Axis.vertical,
          children: [
            StartScreen(),
            Screen1(),
            Screen2(),
          ],
        ),
      ],
    ),
  ],
      )
);

  }
}


// Restaurant Wrapped!
class Screen1 extends StatefulWidget {
  const Screen1({super.key});

  @override
  State<Screen1> createState() => Screen1State(); 
}

class Screen1State extends State<Screen1> with SingleTickerProviderStateMixin {
  late dynamic user;
  late List<dynamic> friends;
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    user = CurrentUser.inst.user;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
      reverseDuration: Duration(seconds: 2),
    );

    _widthAnimation = Tween<double>(begin: 100, end: 110)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _heightAnimation = Tween<double>(begin: 100, end: 110)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);
  }

  Map<String, dynamic> topRestaurant() {
    var maxValue = -1;
    var maxRest = "";
    for (var restaurant in user['restaurant_times'].entries) {
      if (restaurant.value > maxValue) {
        maxValue = restaurant.value;
        maxRest = restaurant.key;
      }
    }

    return {"restaurant": maxRest, "time": maxValue};
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = topRestaurant();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Quest Complete',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 130, maxHeight: 130),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return SizedBox(
                        width: _widthAnimation.value,
                        height: _heightAnimation.value,
                        child: child,
                      );
                    },
                  child: Image.asset(
                    '../assets/star.png',
                    width: 100,
                    height: 100,
                  ),),
                ),
              )),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Text(
                    "Score: ${user['total_restaurant_time']}",
                    style: TextStyle(
                      fontSize: 54,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,)),
                    Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 400),
                    child: Text(
                      "Favorite spot: ${top['restaurant']} \n Time spent: ${top['time'] ~/ 60} min",
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,),
                  ))
                ] 
              ),
            ]),
        ),
      );
  }

}

// Leaderboard!
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
class StartScreen extends StatefulWidget  {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState(); 

  
}

class _StartScreenState extends State<StartScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
      reverseDuration: Duration(seconds: 2),
    );

    _widthAnimation = Tween<double>(begin: 280, end: 300)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _heightAnimation = Tween<double>(begin: 140, end: 150)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
    backgroundColor: Colors.transparent, 
  body: Center(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: _widthAnimation.value,
          height: _heightAnimation.value,
          child: child,
        );
      },
      child: IconButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StopwatchScreen()),
          );
        },
        icon: Image.asset("../assets/start.png"),
        style: IconButton.styleFrom(
          fixedSize: Size(300, 150),
          padding: const EdgeInsets.all(0.0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shadowColor: Colors.transparent,
          elevation: 0.0,
          hoverColor: Colors.transparent,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        enableFeedback: false,
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
    // print(formattedAddress);

    // Step 2: Use Find Place API to get restaurant name
    String? placeName = await _findPlace(formattedAddress);
    setState(() {
      placemarkText = placeName ?? "No place found.";
    });
    
    // print(placeName);

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
      double latitude = 41.829528;
      double longitude = -71.401000;

      String? formattedAddress = await _reverseGeocode(latitude, longitude);
      if (formattedAddress == null) {
        setState(() {
          recommendedRestaurant = "No address found.";
        });
        return;
      }
      print("FORMAT RESTOOOOOO");
      print(formattedAddress);

      String? placeName = await _findPlace(formattedAddress);
      setState(() {
        recommendedRestaurant = placeName ?? "No place found.";
      });
  }

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

// Function to find place (Address -> Place Names)
  Future<String?> _findPlace(String address) async {
  final String key = GOOGLE_API_KEY ?? '';

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
      List<String> restaurantList = [];
      for (var place in data['places']) {
        restaurantList.add(place['displayName']['text']);
      }

      if (restaurantList.isNotEmpty) {
        final randomIndex = Random().nextInt(restaurantList.length);
        return restaurantList[randomIndex];
      } else {
        print('No restaurants available.');
        return null;
      }
    } else {
      print("No places found.");
      return null;
    }
  } else {
    print('Request failed with status: ${response.statusCode}.');
    return null;
  }
  
  return null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      
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