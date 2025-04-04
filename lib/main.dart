import 'package:flutter/material.dart';

// ignore_for_file: unused_local_variable
import 'package:flutter/material.dart';
import 'services/wallet_services.dart';
import 'services/hush_wallet_service.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crypt',
      theme: ThemeData.dark(),
      // home: LoginScreen(),
    );
  }
}
