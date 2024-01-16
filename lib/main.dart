import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {

  return runApp(GaugeApp());
}

/// Represents the GaugeApp class
class GaugeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
        brightness: Brightness.dark,
        ),
        ),
        home: MyHomePage(),
    );
  }
}

/// Represents MyHomePage class
class MyHomePage extends StatefulWidget {
  /// Creates the instance of MyHomePage
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _lat = "";
  var _long = "";
  var _alt = "";
  double _speedMps = 0.0;
  var _speedMph = "";

  Future<void> _updatePosition() async {
    Position pos = await _determinePosition();
      setState(() {
        Geolocator.getPositionStream().listen((pos) {
          _speedMps = pos.speed; // This is your speed
          print(_speedMps.toString());
        });
        _lat = pos.latitude.toString();
        _long = pos.longitude.toString();
        _alt = pos.altitude.toString();
        _speedMph = (pos.speed * 2.237).toString();
      });
    }
  Future<Position> _determinePosition() async {
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
              maximum: 150,
              pointers: <GaugePointer>[
                NeedlePointer(value: _speedMps*2.237)
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                    angle: 0,
                    axisValue: 200,
                    widget: Text(
                        'Current Speed: $_speedMph')
                )
              ])
        ]);
  }

  @override
  Widget build(BuildContext context) {
    _updatePosition();
    return Scaffold(
        body: _getRadialGauge());
  }
}