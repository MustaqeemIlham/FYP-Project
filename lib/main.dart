import 'package:flutter/material.dart';
import 'package:weather_app/widget/app_router.dart'; 
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter, 
      title: 'FarmSmart',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          background: Colors.white,
        ),
      ),
    );
  }
}


