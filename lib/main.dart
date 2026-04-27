import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const DeePMApp());
}

class DeePMApp extends StatelessWidget {
  const DeePMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeePM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080808),
        textTheme: GoogleFonts.dmSansTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const DeePMHome(),
    );
  }
}
