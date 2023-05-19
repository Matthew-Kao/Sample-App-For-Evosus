import 'dart:convert';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var history = <WordPair>[];

  GlobalKey? historyListKey;

  //The getNext function is called whenever the User wants to generate a new random word
  void getNext() {
    history.insert(0, current);
    var animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  //The toggleFavorite function is used to add/remove a word from the favorites list from inside the Generator Page 
  void toggleFavorite([WordPair? pair]) {
    pair = pair ?? current;
    if (favorites.contains(pair)) {
      favorites.remove(pair);
    } else {
      favorites.add(pair);
    }
    notifyListeners();
  }

  //The removeFavorite is used to remove a word from the favorites list from inside the Favorites Page
  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    Widget page;
    
    //Used to navigate between the Generator and Favorites pages.
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    // The container for the current page, with its background color and subtle switching animation
    var mainArea = ColoredBox(
      color: colorScheme.surfaceVariant,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: page,
      ),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 450) {
            // Used to allow a more mobile-friendly layout with BottomNavigationBar on narrow screens such as Mobile Phones
            return Column(
              children: [
                Expanded(child: mainArea),
                SafeArea(
                  child: BottomNavigationBar(
                    items: [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.pool_rounded),
                        label: 'Favorites',
                      ),
                    ],
                    currentIndex: selectedIndex,
                    onTap: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                  ),
                ),
              ],
            );
          } else {
            // Used to accomodate larger screens such as a Laptop
            return Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    extended: constraints.maxWidth >= 600,
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(Icons.home),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.pool_outlined),
                        label: Text('Favorites'),
                      ),
                    ],
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                  ),
                ),
                Expanded(child: mainArea),
              ],
            );
          }
        },
      ),
    );
  }
}

class GeneratorPage extends StatefulWidget {

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  WeatherService weatherService = WeatherService();

  Weather weather = Weather();

  String currentWeather = "";

  double tempC = 0;

  double tempF = 0;

  final textController = TextEditingController();

  //Our default weather to show to the Client is Washington
  @override
  void initState(){
    super.initState();
    getWeather('Washington');
  }

  //The getWeather function grabs the current temperature (IN CELCIUS) for a given city
  void getWeather(String city) async {
    weather = await weatherService.getWeatherData(city);

    setState(() {
      currentWeather = weather.condition;
      tempC = weather.temperatureC;
    });
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
  
    //Change the icon according to whether the User presses the Like button
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: HistoryListView(),
          ),
          SizedBox(height: 10),
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: 'Press like to add to your favorites',
                child: ElevatedButton.icon(
                  onPressed: () {
                    appState.toggleFavorite();
                  },
                  style: ElevatedButton.styleFrom(
                  primary: Colors.orangeAccent, // Background color
                  ),
                  icon: Icon(icon),
                  label: Text('Like'),
                  
                ),
              ),
              SizedBox(width: 10),
              Tooltip(
                message: "Press next to generate a new random text",
                child: ElevatedButton(
                  onPressed: () {
                    appState.getNext();
                  },
                  style: ElevatedButton.styleFrom(
                  primary: Colors.orangeAccent, // Background color
                  ),
                  child: Text('Next'),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.only(left: MediaQuery.of(context).size.width/8, right: MediaQuery.of(context).size.width/8),
            child: TextField(
            controller: textController,
            obscureText: false,
            decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Enter location to install pool',
              ),
            ),
          ),
          Tooltip(
          message: 'Press Submit to confirm your location for Pool Installation',
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
            primary: Colors.orangeAccent, // Set the background color here
          ),
            child: Container(
              child: Text(
                'Submit',
                style: TextStyle(color: Colors.blueGrey),
              ),
            ),
          onPressed: () {
            getWeather(textController.toString());
              },
            ),
          ),    
          Container(
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              currentWeather,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ),
          Text(
            tempC.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getTemperatureColor(tempC),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height/16),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    Key? key,
    required this.pair,
  }) : super(key: key);

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedSize(
          duration: Duration(milliseconds: 200),
          child: MergeSemantics(
            child: Wrap(
              children: [
                Text(
                  pair.first,
                  style: style.copyWith(fontWeight: FontWeight.w200),
                ),
                Text(
                  pair.second,
                  style: style.copyWith(fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var appState = context.watch<MyAppState>();

    //If the user has not added anything to favorites, display a message telling them so
    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(50),
          child: Center(
            child: Text('You have '
                '${appState.favorites.length} favorites:'),
          ),
        ),
        Expanded(
          // Make better use of wide windows with a grid.
          child: GridView(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 400 / 80,
            ),
            children: [
              for (var pair in appState.favorites)
                ListTile(
                  leading: IconButton(
                    icon: Icon(Icons.delete_outline, semanticLabel: 'Delete'),
                    color: theme.colorScheme.primary,
                    tooltip: 'Remove ${pair.asPascalCase} from favorites',
                    onPressed: () {
                      appState.removeFavorite(pair);
                    },
                  ),
                  title: Text(
                    pair.asLowerCase,
                    semanticsLabel: pair.asPascalCase,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class HistoryListView extends StatefulWidget {
  const HistoryListView({Key? key}) : super(key: key);

  @override
  State<HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends State<HistoryListView> {
  /// Needed so that [MyAppState] can tell [AnimatedList] below to animate new items.
  final _key = GlobalKey();

  /// Used to "fade out" the history items at the top, to suggest continuation.
  static const Gradient _maskingGradient = LinearGradient(
    // This gradient goes from fully transparent to fully opaque black...
    colors: [Colors.transparent, Colors.black],
    stops: [0.0, 0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    appState.historyListKey = _key;

    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
      // This blend mode takes the opacity of the shader (i.e. our gradient)
      // and applies it to the destination (i.e. our animated list).
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        key: _key,
        reverse: true,
        padding: EdgeInsets.only(top: 100),
        initialItemCount: appState.history.length,
        itemBuilder: (context, index, animation) {
          final pair = appState.history[index];
          return SizeTransition(
            sizeFactor: animation,
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  appState.toggleFavorite(pair);
                },
                icon: appState.favorites.contains(pair)
                    ? Icon(Icons.favorite, size: 12)
                    : SizedBox(),
                label: Text(
                  pair.asLowerCase,
                  semanticsLabel: pair.asPascalCase,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// This class calls the WeatherAPI and returns the weather at a given location (City)
class WeatherService {
  Future <Weather> getWeatherData(String place) async {
    //336f653a239949e09e2175107231805
    try {
      final queryParameters = {
        'key': '336f653a239949e09e2175107231805',
        'q': place,
      };
      final uri = Uri.http('api.weatherapi.com', '/v1/current.json', queryParameters);
      final response = await http.get(uri);
      if(response.statusCode == 200){
        return Weather.fromJson(jsonDecode(response.body));
      } else {
        //If the call fails, throw an exception to let the user know that the given city is invalid
        throw Exception("The weather is unavailabe");
      } 
    } catch(e) {
      rethrow;
    }
  }
}

///This class stores the information that we received from calling the WeatherAPI
class Weather{
  final double temperatureC;
  final double temperatureF;
  final String condition;

  Weather({
    this.temperatureC = 0,
    this.temperatureF = 0,
    this.condition = 'Sunny',
  });

  factory Weather.fromJson(Map <String, dynamic> json){
    return Weather(
      temperatureC: json['current']['temp_c'],
      temperatureF: json['current']['temp_f'],
      condition: json['current']['condition']['text'],
    );
  }
}

//Change the color of the text according to the temperature received
Color _getTemperatureColor(double temperature) {
  if (temperature < 20) {
    return Colors.blue;
  } else if (temperature >= 20 && temperature <= 30) {
    return Colors.purple;
  } else {
    return Colors.red;
  }
}

