import 'package:elopage_performance/src/pages/group_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'src/service_locator.dart';

void main() {
  serviceLocator.initializeDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(primarySwatch: Colors.teal);
    return MaterialApp(
      title: 'elopage performance',
      debugShowCheckedModeBanner: false,
      theme: theme.copyWith(textTheme: GoogleFonts.latoTextTheme()),
      home: const GroupPage(groupName: 'elopage_mobile'),
    );
  }
}
