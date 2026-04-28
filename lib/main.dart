import 'package:flutter/material.dart';
import 'package:sipam_foto/view/missao/missao.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
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
        listTileTheme: const ListTileThemeData(textColor: Colors.white),
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
        dropdownMenuTheme: DropdownMenuThemeData(menuStyle: const MenuStyle()),
        switchTheme: const SwitchThemeData(),
      ),

      home: const Missao(), // sua tela inicial
    );
  }
}
