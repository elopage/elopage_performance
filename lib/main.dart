import 'package:elopage_performance/src/pages/configurations_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'src/service_locator.dart';

const MaterialColor elopageGreen = MaterialColor(
  0xff7afba2,
  <int, Color>{
    50: Color(0xffb6fdcc),
    100: Color(0xffaffdc7),
    200: Color(0xffa2fcbe),
    300: Color(0xff95fcb5),
    400: Color(0xff87fbab),
    500: Color(0xff7afba2),
    600: Color(0xff6ee292),
    700: Color(0xff62c982),
    800: Color(0xff55b071),
    900: Color(0xff499761),
  },
);

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
    final theme = ThemeData(primarySwatch: elopageGreen, useMaterial3: true);
    return MaterialApp(
      home: const ConfigurationsPage(),
      title: 'elopage performance',
      debugShowCheckedModeBanner: false,
      theme: theme.copyWith(textTheme: GoogleFonts.latoTextTheme()),
    );
  }
}
