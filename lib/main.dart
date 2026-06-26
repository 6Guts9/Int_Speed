import 'package:flutter/material.dart';
import 'controllers/speedTestController.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
@override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SpeedTestController(),
      child: MaterialApp(
      title: 'SpeedTest',
      debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Text('SpeedTest app'),
          ),
  ),
        ),
    );


  }
}