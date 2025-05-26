import 'package:flutter/material.dart';
import 'package:nutanvij_electricals/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Nutanvij Electricals',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0XFF0D6EFD)),
          useMaterial3: true,
        ),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child!,
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}


