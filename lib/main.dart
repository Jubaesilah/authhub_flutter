import 'package:flutter/material.dart';
import 'views/auth/login.dart';
import 'views/profile.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = FlutterSecureStorage();
  String? refreshToken = await storage.read(key: 'refreshToken');
  String? accessToken = await storage.read(key: 'accessToken');

  runApp(MyApp(refreshToken: refreshToken, accessToken: accessToken));
}

class MyApp extends StatelessWidget {
  final String? refreshToken;
  final String? accessToken;

  const MyApp({super.key, this.refreshToken, this.accessToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Hub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: accessToken != null ? const UserPage() : (refreshToken != null ? const UserPage() : const LoginPage()),
    );
  }
}