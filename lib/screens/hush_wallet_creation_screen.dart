import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'dart:convert';
import '../services/hush_wallet_services.dart';
import '../services/wallet_services.dart';

class HushWalletCreationScreen extends StatefulWidget {
  final HushWalletService hushWalletService;
  final WalletService walletService;
  final VoidCallback onHushWalletCreated;

  const HushWalletCreationScreen({
    Key? key,
    required this.hushWalletService,
    required this.walletService,
    required this.onHushWalletCreated,
  }) : super(key: key);

  @override
  _HushWalletCreationScreenState createState() => _HushWalletCreationScreenState();
}

class _HushWalletCreationScreenState extends State<HushWalletCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  bool _showingSeedPhrase = false;
  String? _mnemonic;
  String? _privateKey;
  String? _walletAddress;
  List<String> _mnemonicWords = [];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _createHushWallet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Store HushWallet username and hashed password
      await _storage.write(key: 'hush_wallet_username', value: _usernameController.text);
      await _storage.write(key: 'hush_wallet_password_hash', value: _hashPassword(_passwordController.text));

      // Generate the seed phrase and wallet details
      final walletDetails = await widget.hushWalletService.createWallet(isBackup: true);
      
      setState(() {
        _mnemonic = walletDetails['mnemonic'];
        _privateKey = walletDetails['privateKey'];
        _walletAddress = walletDetails['address'];
        _mnemonicWords = _mnemonic!.split(' ');
        _showingSeedPhrase = true;
        _isSubmitting = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating HushWallet: $e'))
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _finishHushWalletCreation() {
    widget.onHushWalletCreated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('HushWallet Setup', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isSubmitting 
        ? const Center(child: CircularProgressIndicator())
        : _showingSeedPhrase
          ? _buildSeedPhraseScreen()
          : _buildCredentialsForm(),
    );
  }

  Widget _buildCredentialsForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create HushWallet Credentials',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[900]?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[900]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[300]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'HushWallet is a backup wallet that can be activated if your main wallet is compromised. Create separate credentials for added security.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[100]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'HushWallet Username',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'HushWallet Password',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple[500],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _createHushWallet,
                child: const Text(
                  'Create HushWallet',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedPhraseScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your HushWallet Recovery Phrase',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[900]?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[900]!, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[300]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Write these words down in the correct order and keep them safe. You will NEVER see them again. Anyone with these words can access your HushWallet.',
                    style: TextStyle(fontSize: 12, color: Colors.red[100]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _mnemonicWords.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${index + 1}.',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _mnemonicWords[index],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Display public and private keys
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[900]?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[900]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red[300]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'IMPORTANT: Your public and private keys are shown below. This is the ONLY time you will see them. Save them securely.',
                        style: TextStyle(fontSize: 12, color: Colors.red[100], fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Public Address:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _walletAddress ?? 'Error generating address',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Private Key:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _privateKey ?? 'Error generating private key',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple[500],
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _finishHushWalletCreation,
              child: const Text(
                'I\'ve Saved My Recovery Phrase and Keys',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}