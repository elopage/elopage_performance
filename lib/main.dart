import 'package:elopage_performance/src/pages/configurations_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'src/service_locator.dart';

void main() async {
  await Hive.initFlutter();
  serviceLocator.initializeDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(primarySwatch: Colors.teal, useMaterial3: true);
    return MaterialApp(
      home: const ConfigurationsPage(),
      title: 'elopage performance',
      debugShowCheckedModeBanner: false,
      theme: theme.copyWith(textTheme: GoogleFonts.latoTextTheme()),
    );
  }
}
