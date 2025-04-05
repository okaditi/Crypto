import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // Keys for storing credentials
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';
  static const String _isLoggedInKey = 'is_logged_in';
  
  // Save user credentials
  Future<void> saveCredentials(String username, String password) async {
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _passwordKey, value: password);
    await _storage.write(key: _isLoggedInKey, value: 'true');
    print('Credentials saved successfully');
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    String? isLoggedIn = await _storage.read(key: _isLoggedInKey);
    return isLoggedIn == 'true';
  }
  
  // Get saved username
  Future<String?> getSavedUsername() async {
    return await _storage.read(key: _usernameKey);
  }
  
  // Get saved password
  Future<String?> getSavedPassword() async {
    return await _storage.read(key: _passwordKey);
  }
  
  // Get both username and password
  Future<Map<String, String?>> getSavedCredentials() async {
    return {
      'username': await getSavedUsername(),
      'password': await getSavedPassword(),
    };
  }
  
  // Clear saved credentials (for logout)
  Future<void> clearCredentials() async {
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
    await _storage.write(key: _isLoggedInKey, value: 'false');
    print('Credentials cleared successfully');
  }
  
  // Validate credentials (this would connect to your actual authentication logic)
  Future<bool> validateCredentials(String username, String password) async {
    String? savedUsername = await getSavedUsername();
    String? savedPassword = await getSavedPassword();
    
    if (savedUsername == null || savedPassword == null) {
      return false;
    }
    
    return username == savedUsername && password == savedPassword;
  }
}