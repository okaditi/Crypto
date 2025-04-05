// ignore_for_file: unused_import
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/threat_analysis_service.dart';
import 'package:flutter/material.dart';
import 'package:crypto_wallet/utils/encryption_helper.dart';
import 'package:crypto_wallet/utils/security_checker.dart';
import 'package:crypto_wallet/services/threat_logger.dart';
import 'services/wallet_services.dart';
import 'services/hush_wallet_services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'screens/personal_details_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/hush_wallet_creation_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load encryption key when the app starts
  await EncryptionHelper.loadKey();

  //Load the dot env file when the app starts
  
  await dotenv.load();


  runApp(CryptoWalletApp());
}

class CryptoWalletApp extends StatelessWidget {
  const CryptoWalletApp({super.key});

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

// -------------------- LOGIN SCREEN -------------------------
class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final WalletService walletService = WalletService();
  final _storage = const FlutterSecureStorage();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Hash password using SHA-256 for verification
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _verifyAndLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get stored credentials
      final storedUsername = await _storage.read(key: 'wallet_username');
      final storedPasswordHash = await _storage.read(key: 'password_hash');

      // Check if user exists
      if (storedUsername == null || storedPasswordHash == null) {
        setState(() {
          _errorMessage = 'No registered user found. Please register first.';
          _isLoading = false;
        });
        return;
      }

      // Verify credentials
      final inputPasswordHash = _hashPassword(_passwordController.text);
      
      if (_usernameController.text != storedUsername || inputPasswordHash != storedPasswordHash) {
        setState(() {
          _errorMessage = 'Invalid username or password';
          _isLoading = false;
        });
        return;
      }

      // Credentials verified, proceed to main screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(walletService: walletService),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication error: $e';
        _isLoading = false;
      });
    }
  }

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
              const Text(
                "Crypt", 
                style: TextStyle(
                  fontSize: 50, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 40,),
              const Text(
                "Welcome back you've been missed!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegistrationScreen(
                          walletService: walletService,
                        ),
                      ),
                    );
                  }, 
                  child: const Text(
                    'New user?',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[500],
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: _isLoading ? null : _verifyAndLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
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


//--------------------- MainScreen to handle navigation -----------------------------
class MainScreen extends StatefulWidget {
  final WalletService walletService;
  const MainScreen({super.key, required this.walletService});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeContent(),
      WalletScreen(walletService: widget.walletService),
      SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.deepPurple[500],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// --------------------- HomeContent with Threat Analysis Integration ---------------------
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  bool _isLoading = false;
  String _riskLevel = 'Unknown';
  String _threatExplanation = '';
  Color _riskColor = Colors.grey;
  IconData _riskIcon = Icons.help_outline;

  // Initialize the threat analysis service
  late ThreatAnalysisService _threatAnalysisService;
  
  // Controller for search input
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await dotenv.load(); // Load environment variables
      _threatAnalysisService = ThreatAnalysisService();
    } catch (e) {
      print("Failed to initialize ThreatAnalysisService: $e");
      // Show a message to the user that this feature is unavailable
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Threat analysis feature unavailable: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateRiskVisuals(String riskLevel) {
    setState(() {
      _riskLevel = riskLevel;
      
      // Set risk color and icon based on risk level
      switch (riskLevel.toLowerCase()) {
        case 'high':
          _riskColor = Colors.red;
          _riskIcon = Icons.warning_rounded;
          break;
        case 'medium':
          _riskColor = Colors.orange;
          _riskIcon = Icons.security_update_warning;
          break;
        case 'low':
          _riskColor = Colors.yellow;
          _riskIcon = Icons.info_outline;
          break;
        case 'none':
          _riskColor = Colors.green;
          _riskIcon = Icons.verified_user;
          break;
        default:
          _riskColor = Colors.grey;
          _riskIcon = Icons.help_outline;
          break;
      }
    });
  }

  Future<void> _analyzeInput(String input) async {
    if (input.isEmpty) return;
    
    // Determine input type (simplified logic - could be improved)
    ThreatInputType inputType = ThreatInputType.generalText;
    
    if (input.startsWith('0x') && input.length == 42) {
      inputType = ThreatInputType.walletAddress;
    } else if (input.startsWith('0x') && input.length > 60) {
      inputType = ThreatInputType.transactionHash;
    } else if (input.contains('.') && (input.contains('http') || !input.contains(' '))) {
      inputType = ThreatInputType.url;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await _threatAnalysisService.analyzeForThreat(
        inputData: input,
        inputType: inputType,
      );
      
      _updateRiskVisuals(result['riskLevel']);
      setState(() {
        _threatExplanation = result['explanation'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _riskLevel = 'Error';
        _threatExplanation = 'Analysis failed: ${e.toString()}';
        _riskColor = Colors.grey;
        _riskIcon = Icons.error_outline;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Crypt',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 30),
            // Search bar for threat analysis
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter address, URL, or text to analyze',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.deepPurple[500]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.deepPurple[500]!, width: 2),
                ),
              ),
              onSubmitted: _analyzeInput,
            ),
            const SizedBox(height: 20),
            // Analysis action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple[500],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _isLoading 
                  ? null 
                  : () => _analyzeInput(_searchController.text),
                child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Analyze for Threats'),
              ),
            ),
            const SizedBox(height: 40),
            // Risk level indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: _riskColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _riskColor, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _riskIcon,
                        color: _riskColor,
                        size: 40,
                      ),
                      const SizedBox(width: 15),
                      Text(
                        'Risk Level: $_riskLevel',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _riskColor,
                        ),
                      ),
                    ],
                  ),
                  if (_threatExplanation.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    Text(
                      _threatExplanation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[300],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Tips based on risk level
            if (_riskLevel != 'Unknown' && _riskLevel != 'Error') ...[
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getRiskTip(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _getRiskTip() {
    switch (_riskLevel.toLowerCase()) {
      case 'high':
        return '🚨 Whoa there! This looks dangerous. Avoid any interaction with this address or URL!';
      case 'medium':
        return '⚠️ Proceed with extreme caution. Double-check all details before proceeding.';
      case 'low':
        return '🔍 Minor concerns detected. Review carefully before proceeding.';
      case 'none':
        return '✅ Looks good! No threats detected in our analysis.';
      default:
        return '🤔 Something went wrong with the analysis. Try again later.';
    }
  }
}
// ---------------------------- SettingsScreen ----------------------------
class SettingsScreen extends StatelessWidget {
  final HushWalletService hushWalletService = HushWalletService();
  final WalletService walletService = WalletService();

  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Handle profile tap
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Security'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Handle security tap
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Handle notifications tap
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('HushWallet'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HushWalletScreen(hushWalletService: hushWalletService, walletService: walletService),
                  ),
                );
              },
            ),
            Divider(color: Colors.grey[800]),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out? This will delete your wallet data for the demo.'),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.pop(context),
                        ),
                        TextButton(
                          child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                          onPressed: () async {
                            await walletService.storage.delete(key: "private_key");
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                              (Route<dynamic> route) => false,
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Panel'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- WALLET SCREEN --------------------
class WalletScreen extends StatefulWidget {
  final WalletService walletService;
  const WalletScreen({super.key, required this.walletService});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String balance = 'Fetching...';
  String? walletAddress;
  List<Map<String, String>> assets = [];
  bool isLoading = true;
  bool hasWallet = false;

  @override
  void initState() {
    super.initState();
    _checkWallet();
  }

  Future<void> _checkWallet() async {
    setState(() => isLoading = true);
    String? privateKey = await widget.walletService.loadPrivateKey();
    setState(() {
      hasWallet = privateKey != null;
      isLoading = false;
    });
    
    if (hasWallet) {
      _loadWalletData();
    }
  }

  Future<void> _loadWalletData() async {
    try {
      String? privateKey = await widget.walletService.loadPrivateKey();
      if (privateKey != null) {
        String address = widget.walletService.getEthereumAddress(privateKey);
        setState(() => walletAddress = address);

        EtherAmount ethBalance = await widget.walletService.getBalance(address);
        double ethValue = ethBalance.getValueInUnit(EtherUnit.ether);
        // double ethUsdValue = ethValue * 2000; // Using approximate ETH price for Sepolia testnet

        List<Map<String, String>> fetchedAssets = await widget.walletService.getAllAssets(address);

        setState(() {
          balance = ethValue.toStringAsFixed(4);
          assets = fetchedAssets;
        });
      } else {
        setState(() => balance = '0.0000');
      }
    } catch (e) {
      print("Error in _loadWalletData: $e");
      setState(() => balance = '0.0000');
    }
  }

  Widget _walletActionButton(IconData icon, String label, {VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showSendDialog() {
    final TextEditingController recipientController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Send ETH'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: recipientController,
                decoration: const InputDecoration(labelText: 'Recipient Address'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount (ETH)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Send'),
              onPressed: () async {
                final recipient = recipientController.text;
                final amount = double.tryParse(amountController.text);

                if (recipient.isNotEmpty && amount != null) {
                  try {
                    String? privateKey = await widget.walletService.loadPrivateKey();
                    if (privateKey != null) {
                      await widget.walletService.sendTransaction(privateKey, recipient, amount);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction sent successfully!')),
                      );
                      _loadWalletData(); // Refresh the balance after sending
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No private key found.')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error sending transaction: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid details.')),
                  );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showReceiveDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Receive ETH'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your wallet address:'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  walletAddress ?? 'No address available',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Share this address to receive ETH'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showSwapDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Swap Tokens'),
          content: const Text('Token swap functionality coming soon!'),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Wallet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (!hasWallet) {
      return CreateWalletScreen(
        walletService: widget.walletService,
        onWalletCreated: () {
          setState(() {
            hasWallet = true;
          });
          _loadWalletData();
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Wallet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const Text('Total Balance', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text('$balance ETH', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  Text('\$${assets.isNotEmpty ? assets[0]['usd'] : '0.00'} USD', style: const TextStyle(fontSize: 18, color: Colors.greenAccent)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      walletAddress ?? "No wallet address",
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _walletActionButton(Icons.download, 'Receive', onPressed: _showReceiveDialog),
                _walletActionButton(Icons.arrow_upward, 'Send', onPressed: _showSendDialog),
                _walletActionButton(Icons.swap_horiz, 'Swap', onPressed: _showSwapDialog),
              ],
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Assets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Activity', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
            const Divider(color: Colors.grey),
            // Expanded(
            //   child: ListView.builder(
            //     itemCount: assets.length,
            //     itemBuilder: (context, index) {
            //       final asset = assets[index];
            //       return ListTile(
            //         leading: CircleAvatar(
            //           backgroundColor: Colors.grey[800],
            //           child: Text(asset['symbol'] ?? '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            //         ),
            //         title: Text('${asset['amount']} ${asset['symbol']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            //         subtitle: Text('\$${asset['usd']} USD', style: const TextStyle(color: Colors.grey)),
            //         trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            //       );
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

// -------------------- CREATE WALLET SCREEN --------------------
class CreateWalletScreen extends StatefulWidget {
  final WalletService walletService;
  final VoidCallback onWalletCreated;
  final Map<String, String>? promotedWalletDetails;
  
  const CreateWalletScreen({super.key, 
    required this.walletService, 
    required this.onWalletCreated,
    this.promotedWalletDetails,
  });
  
  @override
  _CreateWalletScreenState createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  bool isCreating = false;
  bool showingSeedPhrase = false;
  String? mnemonic;
  String? privateKey;
  String? walletAddress;
  List<String> mnemonicWords = [];
  
  @override
  void initState() {
    super.initState();
    if (widget.promotedWalletDetails != null) {
      // If we have promoted wallet details, use them
      _usePromotedWallet();
    }
  }

  void _usePromotedWallet() async {
    setState(() {
      isCreating = true;
    });

    try {
      // Save the promoted wallet details
      await widget.walletService.savePrivateKey(
        widget.promotedWalletDetails!["mainWalletPrivateKey"]!
      );
      
      // Create new backup wallet
      await widget.walletService.hushWalletService.createWallet(isBackup: true);
      
      widget.onWalletCreated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error setting up promoted wallet: $e'))
      );
    }
    
    setState(() {
      isCreating = false;
    });
  }
  
  void _startWalletCreation() async {
    setState(() {
      isCreating = true;
    });
    
    // Generate the seed phrase
    final newMnemonic = widget.walletService.generateMnemonic();
    final newPrivateKey = widget.walletService.derivePrivateKey(newMnemonic);
    final newAddress = widget.walletService.getEthereumAddress(newPrivateKey);
    
    setState(() {
      mnemonic = newMnemonic;
      privateKey = newPrivateKey;
      walletAddress = newAddress;
      mnemonicWords = newMnemonic.split(' ');
      showingSeedPhrase = true;
      isCreating = false;
    });
  }
  
  void _finishWalletCreation() async {
    setState(() {
      isCreating = true;
    });
    
    try {
      // First save the seed phrase and private key for the main wallet
      await widget.walletService.saveSeedPhrase(mnemonic!);
      await widget.walletService.savePrivateKey(privateKey!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet created successfully!'))
      );
      
      // Navigate to HushWallet creation screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HushWalletCreationScreen(
            hushWalletService: widget.walletService.hushWalletService,
            walletService: widget.walletService,
            onHushWalletCreated: widget.onWalletCreated,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating wallet: $e'))
      );
      setState(() {
        isCreating = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // If we have promoted wallet details, skip the UI and process directly
    if (widget.promotedWalletDetails != null && !isCreating) {
      _usePromotedWallet();
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Setting up promoted wallet...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Main Wallet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: isCreating 
        ? const Center(child: CircularProgressIndicator())
        : showingSeedPhrase
          ? _buildSeedPhraseScreen()
          : _buildWelcomeScreen(),
    );
  }
  
  Widget _buildWelcomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 100,
            color: Colors.deepPurple[400],
          ),
          const SizedBox(height: 30),
          const Text(
            'Welcome to Crypt',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'It looks like you don\'t have a wallet yet. Create one to get started with cryptocurrencies!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple[500],
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _startWalletCreation,
              child: const Text(
                'Create Wallet',
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
  
  Widget _buildSeedPhraseScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Recovery Phrase',
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
                    'Write these words down in the correct order and keep them safe. You will NEVER see them again. Anyone with these words can access your wallet.',
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
                itemCount: mnemonicWords.length,
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
                            mnemonicWords[index],
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
                    walletAddress ?? 'Error generating address',
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
                    privateKey ?? 'Error generating private key',
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
              onPressed: _finishWalletCreation,
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
//------------------------ HushWallet Screen ------------------------
class HushWalletScreen extends StatefulWidget {
  final HushWalletService hushWalletService;
  final WalletService walletService;
  const HushWalletScreen({super.key, 
    required this.hushWalletService,
    required this.walletService,
  });
  
  @override
  _HushWalletScreenState createState() => _HushWalletScreenState();
}

class _HushWalletScreenState extends State<HushWalletScreen> {
  Map<String, String?> walletDetails = {
    "mainWalletAddress": null,
    "mainWalletPrivateKey": null,
    "backupWalletAddress": null,
    "backupWalletPrivateKey": null,
  };
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWalletDetails();
  }

  Future<void> _loadWalletDetails() async {
    setState(() => isLoading = true);
    try {
      Map<String, String?> details = await widget.hushWalletService.getAllWalletDetails();
      setState(() {
        walletDetails = details;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading wallet details: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _triggerSelfDestruct() async {
    try {
      // Show confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Self-Destruct'),
            content: const Text(
              'This will permanently delete your current wallet and activate your HushWallet. '
              'Make sure you have backed up your HushWallet details. '
              'This action cannot be undone.'
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Confirm'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirm != true) {
        return;
      }

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Activating Hushwallet...'),
                  SizedBox(height: 8),
                  Text('This may take a few moments', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        },
      );

      // Trigger self-destruct and get updated wallet info
      Map<String, String> updatedWallets = await widget.hushWalletService.triggerSelfDestruct();

      // Close progress dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'HushWallet activated successfully!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green[600],
        ),
      );

      // Navigate to MainScreen directly with updated wallet
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(walletService: widget.walletService),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      // Close progress dialog if it's open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to activate HushWallet: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HushWallet'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HushWallet is a backup wallet that can be activated if your main wallet is compromised.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  _buildWalletCard(
                    'Current Wallet',
                    walletDetails["mainWalletAddress"] ?? 'Not available',
                  ),
                  const SizedBox(height: 16),
                  _buildWalletCard(
                    'Backup HushWallet',
                    walletDetails["backupWalletAddress"] ?? 'Not available',
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _triggerSelfDestruct,
                      child: const Text(
                        'Activate HushWallet (Self-Destruct)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWalletCard(String title, String address) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              address,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

