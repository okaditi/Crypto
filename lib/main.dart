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
      home: LoginScreen(),
    );
  }
}


// -------------------- LOGIN SCREEN --------------------
class LoginScreen extends StatelessWidget {
  final WalletService walletService = WalletService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Crypt", 
                style: TextStyle(
                  fontSize: 50, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 40,),
              Text(
                "Welcome back you've been missed!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {},
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[500],
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MainScreen(walletService: walletService),
                      ),
                    );
                  },
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      fontWeight: FontWeight.bold
                    ),
                    ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

