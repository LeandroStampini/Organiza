import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('appBox'); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Controle de Estoque',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, 
        dialogBackgroundColor: Colors.white,    
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,        
          foregroundColor: Color(0xFF2B4479),   
          elevation: 1,
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(
          background: Colors.white,             
        ),
      ),
      initialRoute: '/',
      routes: appRoutes,
    );
  }
}
