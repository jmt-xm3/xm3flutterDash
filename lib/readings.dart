import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Reading {
  final DateTime time;
  final double speed;

  const Reading({
    required this.time,
    required this.speed,
  });
}