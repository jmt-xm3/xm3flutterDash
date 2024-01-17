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
  return runApp(GaugeApp());
}
void createTelemetryDatabase() async {
  final database = openDatabase(
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    join(await getDatabasesPath(), 'telemetry.db'),
    onCreate: (db, version) {
      // Run the CREATE TABLE statement on the database.
      return db.execute(
        'CREATE TABLE telemetry (id TEXT PRIMARY KEY , speed REAL, altitude REAL)',
      );
    },
    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    version: 1,
  );
  final db = await database;
  await db.execute('DROP TABLE IF EXISTS telemetry');
  await db.execute('CREATE TABLE telemetry (time TEXT PRIMARY KEY , speed REAL, altitude REAL)');
}
/// Represents the GaugeApp class
class GaugeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.green,
          primaryColor: Colors.green,
          textTheme: GoogleFonts.getTextTheme("Orbitron", TextTheme(
            displayLarge: TextStyle(
              color: Colors.green,
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

  Future<int> _retrieveAverageSpeed() async {
  final database = await openDatabase(
  join(await getDatabasesPath(), 'telemetry.db'));
  final db = database;
  var speedData = await db.rawQuery('SELECT speed FROM telemetry');
  List<double> listOfDoubles = speedData.map((map) => map['speed'] as double).toList();
  double sum = listOfDoubles.reduce((value, element) => value + element);
  double average = sum / listOfDoubles.length;
  return average.round();
  }

  Future<void> _updatePosition() async {
    final database = await openDatabase(
        join(await getDatabasesPath(), 'telemetry.db'));
    final db = database;
    Position pos = await _checkLocationPermission();
      setState(() {
        Geolocator.getPositionStream().listen((pos) {
        });
        _speedMps = pos.speed; // This is your speed
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


  Widget _getRadialGauge() {
    return SfRadialGauge(
        axes:
        <RadialAxis>[
          RadialAxis(minimum: 0,
              maximum: 100,
              pointers: <GaugePointer>[
                NeedlePointer(value: _speedMps*2.237)
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                    angle: 90,
                    positionFactor: 0.85,
                    widget: Material(
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
          _getRadialGauge(),
          ElevatedButton(
            onPressed: () {Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsPage()));},
            child: const Text('Stats Page'),)
        ],
    );
  }
}



class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [ElevatedButton(
      onPressed: () {Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SpeedometerPage()));},child: const Text('Speedo Page'),)]);
  }
}