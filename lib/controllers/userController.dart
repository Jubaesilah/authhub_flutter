import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../models/userModel.dart';
import '../views/auth/login.dart';

class UserController {
  static const String baseUrl =
      'https://bf5d-182-3-36-24.ngrok-free.app/api/user-profile';
  static const String refreshTokenUrl =
      'https://bf5d-182-3-36-24.ngrok-free.app/api/auth/refresh-token';
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Function to get the user of the user
  static Future<UserModel?> getUser(BuildContext context,
      {VoidCallback? onTokenExpired}) async {
    try {
      String? accessToken = await _storage.read(key: 'accessToken');
      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == true) {
          return UserModel.fromJson(data);
        } else {
          throw Exception('Failed to fetch user');
        }
      } else if (response.statusCode == 403) {
        // Token expired or invalid, attempt to refresh the token
        final newAccessToken = await _refreshAccessToken(
            context: context, onTokenExpired: onTokenExpired);
        if (newAccessToken != null) {
          return await getUser(context, onTokenExpired: onTokenExpired);
        } else {
          // Here we log the error more thoroughly
          print('Error 403: Invalid or expired refresh token');
          throw Exception('Failed to refresh token, please login again.');
        }
      } else {
        throw Exception('Failed to fetch user');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Error occurred: $e');
    }
  }

  // Function to refresh the access token using the refresh token
  static Future<String?> _refreshAccessToken(
      {required BuildContext context, VoidCallback? onTokenExpired}) async {
    try {
      String? refreshToken = await _storage.read(key: 'refreshToken');
      if (refreshToken == null) {
        throw Exception('Refresh token not found');
      }

      final response = await http.post(
        Uri.parse(refreshTokenUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == true) {
          // Save the new access token in secure storage
          String newAccessToken = data['newAccessToken'];
          await _storage.write(key: 'accessToken', value: newAccessToken);
          return newAccessToken;
        } else {
          throw Exception('Failed to refresh token');
        }
      } else if (response.statusCode == 403) {
        // Forbidden error, reset tokens and invoke callback
        print('Received 403 error from refresh-token endpoint');
        await _resetTokens();
        onTokenExpired?.call(); // Trigger navigation callback
        
        // Additional logging to ensure clarity
        print('Refresh token invalid, redirecting to login...');
        
        throw Exception('Forbidden error, redirected to login');
      };
    } catch (e) {
      print('Error refreshing token: $e');
      throw Exception('Error refreshing token: $e');
    }
    return null;
  }

  // Function to reset tokens
  static Future<void> _resetTokens() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
  }

  // Function to load user with token expired handling
  static Future<void> loadUser(BuildContext context) async {
    try {
      final user = await UserController.getUser(
        context,
        onTokenExpired: () {
          // Navigasi ke halaman login jika token kadaluarsa
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        },
      );
      print('User loaded: ${user?.name}');
    } catch (e) {
      print('Error loading user: $e');
    }
  }
}
