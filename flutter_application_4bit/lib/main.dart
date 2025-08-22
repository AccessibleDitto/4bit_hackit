import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'calendar_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar CRUD App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CalendarPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}