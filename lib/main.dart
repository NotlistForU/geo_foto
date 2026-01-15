import 'package:flutter/material.dart';
import 'package:sipam_foto/view/missao/missao.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // remove a faixa "debug"
      title: 'Meu App',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(
          255,
          25,
          35,
          55,
        ), // fundo azul escuro
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white, // cor do texto/ícones da AppBar
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color.fromARGB(255, 40, 50, 70),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
          contentTextStyle: TextStyle(
            color: Colors.white70,
          ), // fundo do AlertDialog
        ),
      ),
      home: const Missao(), // sua tela inicial
    );
  }
}
