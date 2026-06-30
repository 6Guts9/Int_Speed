import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'controllers/SpeedTestController.dart';
import 'screens/HomeScreen.dart';
import 'package:provider/provider.dart';

void main() {

  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
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
        home: const HomeScreen()


  ),
        );



  }
}