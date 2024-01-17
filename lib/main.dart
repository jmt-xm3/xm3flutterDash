import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  createTelemetryDatabase();
  return runApp(SpeedoWidget());
}
void createTelemetryDatabase() async {
  final database = openDatabase(
    join(await getDatabasesPath(), 'telemetry.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE telemetry (id TEXT PRIMARY KEY , speed REAL, altitude REAL)',
      );
    },
    version: 1,
  );
  final db = await database;
  await db.execute('DROP TABLE IF EXISTS telemetry'); // Reinitialise database every startup
  await db.execute('CREATE TABLE telemetry (time TEXT PRIMARY KEY , speed REAL, altitude REAL)');
}

class SpeedoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.purple,
          primaryColor: Colors.purple,
          textTheme: GoogleFonts.getTextTheme("Orbitron", const TextTheme(
            displayLarge: TextStyle(
              color: Colors.purple,
            ),
          )),
        ),
        home: const SpeedometerPage(),
    );
  }
}

class SpeedometerPage extends StatefulWidget {
  const SpeedometerPage({Key? key}) : super(key: key);

  @override
  _SpeedometerPageState createState() => _SpeedometerPageState();
}

class _SpeedometerPageState extends State<SpeedometerPage> {
  double _altitude = 0.0;
  var _time = "";
  double _speedMps = 0.0;
  var _speedMph = "";


  Future<void> _updatePosition() async {
    final database = await openDatabase(
        join(await getDatabasesPath(), 'telemetry.db'));
    final db = database;
    Position pos = await _checkLocationPermission();
      setState(() {
        Geolocator.getPositionStream().listen((pos) {
        });
        _speedMps = pos.speed; // Speed in metre's per second
        _altitude = pos.altitude;
        _time = DateTime.now().toString();
        _speedMph = (pos.speed * 2.237).round().toString();
      });
    await db.rawInsert('INSERT INTO telemetry(time,speed,altitude) VALUES(?,?,?)', [_time, _speedMps,_altitude]);
    }

  Future<Position> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }


  Widget _getSpeedo() {
    return SfRadialGauge(
        axes:
        <RadialAxis>[
          RadialAxis(minimum: 0,
              maximum: 100,
              ranges: <GaugeRange>[GaugeRange(startValue: 70,
                  endValue: 100,
                  color: Colors.red)],
              pointers: <GaugePointer>[
                NeedlePointer(value: _speedMps*2.237) // has to be double cant use _speedMph
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(angle: 90, positionFactor: 0.85, widget: Material(
                        child: Text('$_speedMph MPH',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 36.0)))
                )
              ])
        ]);
  }

  @override
  Widget build(BuildContext context) {
    _updatePosition();

    return Column(mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _getSpeedo(),
          ElevatedButton(
            onPressed: () {Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StatsPage()));},
            child: const Text('Stats Page'),)
        ],
    );
  }
}



class StatsPage extends StatefulWidget {
  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late double topSpeed;
  late double averageSpeed;
  late double averageAltitude;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    final Database db = await _openDatabase();

    final List<Map<String, dynamic>> result = await db.query('telemetry');
    if (result.isNotEmpty) {
      final List<double> speeds = result.map((row) => row['speed'] as double).toList();
      final List<double> altitudes = result.map((row) => row['altitude'] as double).toList();

      topSpeed = speeds.reduce((value, element) => value > element ? value : element);
      averageSpeed = speeds.isNotEmpty ? speeds.reduce((value, element) => value + element) / speeds.length : 0.0;
      averageAltitude = altitudes.isNotEmpty ? altitudes.reduce((value, element) => value + element) / altitudes.length : 0.0;
    } else {
      topSpeed = 0.0;
      averageSpeed = 0.0;
      averageAltitude = 0.0;
    }

    setState(() {});
  }

  Future<Database> _openDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'telemetry.db'),
      version: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stats Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Top Speed (Miles Per Hour): ${(topSpeed*2.237).toStringAsFixed(2)}'),
            Text('Top Speed (Kilometers per hour): ${(topSpeed*3.6).toStringAsFixed(2)}'),
            Text('Top Speed (Metres per second): ${topSpeed.toStringAsFixed(2)}'),
            Text('Average Speed (Miles Per Hour): ${(averageSpeed*2.237).toStringAsFixed(2)}'),
            Text('Average Speed (Kilometers per hour): ${(averageSpeed*3.6).toStringAsFixed(2)}'),
            Text('Average Speed (Metres per second): ${averageSpeed.toStringAsFixed(2)}'),
            Text('Average Altitude: ${averageAltitude.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}