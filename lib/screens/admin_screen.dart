import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _storage = const FlutterSecureStorage();
  Map<String, String> _credentials = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadAllCredentials();
  }
  
  Future<void> _loadAllCredentials() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Retrieve all items from secure storage
      final allItems = await _storage.readAll();
      
      setState(() {
        _credentials = allItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading credentials: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Admin Panel', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllCredentials,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _credentials.isEmpty
              ? const Center(child: Text('No credentials found'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stored Credentials',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _credentials.length,
                          itemBuilder: (context, index) {
                            final key = _credentials.keys.elementAt(index);
                            final value = _credentials[key];
                            
                            // Highlight user credential entries
                            final bool isUserCredential = key == 'wallet_username' || 
                                                         key == 'password_hash' ||
                                                         key.contains('username') ||
                                                         key.contains('password');
                            
                            return Card(
                              color: isUserCredential ? Colors.deepPurple[900] : Colors.grey[900],
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Key: $key',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Value: $value'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}