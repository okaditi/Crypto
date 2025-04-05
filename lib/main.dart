import 'package:flutter/material.dart';
import 'package:crypto_wallet/utils/encryption_helper.dart';
import 'package:crypto_wallet/utils/security_checker.dart';
import 'package:crypto_wallet/services/threat_logger.dart';
import 'services/wallet_services.dart';
import 'services/hush_wallet_services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Future<void> main() async {
//   // Load environment variables before app starts
//   await dotenv.load(fileName: ".env");

//   runApp(MyApp()); // or whatever your app entry is
// }


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); 
  //calling encryption helper
  await EncryptionHelper.loadKey(); 
  await checkDeviceSecurity();


  // Check if device is jailbroken/rooted
  bool isRooted = await FlutterJailbreakDetection.jailbroken;
  if (isRooted) {
    await ThreatLogger.log('⚠️ Device is jailbroken or rooted!');
  } else {
    await ThreatLogger.log('✅ Device integrity check passed.');
  }

  // Log that the app has started
  await ThreatLogger.log('App started – threat logger is active ✅');

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


//--------------------- MainScreen to handle navigation -----------------------------
class MainScreen extends StatefulWidget {
  final WalletService walletService;
  MainScreen({required this.walletService});

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

// --------------------- HomeContent ---------------------
class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Crypt',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }
}

// ---------------------------- SettingsScreen ----------------------------
class SettingsScreen extends StatelessWidget {
  final HushWalletService hushWalletService = HushWalletService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Profile'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Handle profile tap
              },
            ),
            ListTile(
              leading: Icon(Icons.security),
              title: Text('Security'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Handle security tap
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications_outlined),
              title: Text('Notifications'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Handle notifications tap
              },
            ),
            ListTile(
              leading: Icon(Icons.backup_outlined),
              title: Text('HushWallet'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HushWalletScreen(hushWalletService: hushWalletService),
                  ),
                );
              },
            ),
            Divider(color: Colors.grey[800]),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Sign Out'),
                      content: Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          child: Text('Cancel'),
                          onPressed: () => Navigator.pop(context),
                        ),
                        TextButton(
                          child: Text('Sign Out', style: TextStyle(color: Colors.red)),
                          onPressed: () {
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
          ],
        ),
      ),
    );
  }
}

// -------------------- WALLET SCREEN --------------------
class WalletScreen extends StatefulWidget {
  final WalletService walletService;
  WalletScreen({required this.walletService});

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
        double ethToUsd = await widget.walletService.getEthToUsdRate();
        double ethUsdValue = ethValue * ethToUsd;

        List<Map<String, String>> fetchedAssets = await widget.walletService.getAllAssets(address);

        setState(() {
          balance = ethValue.toStringAsFixed(4);
          assets = fetchedAssets;
        });
      } else {
        setState(() => balance = 'No wallet found');
      }
    } catch (e) {
      setState(() => balance = 'Error fetching balance');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('Wallet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(child: CircularProgressIndicator()),
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
        title: Text('Wallet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text('Total Balance', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 5),
                  Text('$balance ETH', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  Text('\$${assets.isNotEmpty ? assets[0]['usd'] : '0.00'} USD', style: TextStyle(fontSize: 18, color: Colors.greenAccent)),
                ],
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.grey),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${walletAddress ?? "No wallet address"}',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _walletActionButton(Icons.download, 'Receive'),
                _walletActionButton(Icons.arrow_upward, 'Send'),
                _walletActionButton(Icons.swap_horiz, 'Swap'),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Assets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Activity', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
            Divider(color: Colors.grey),
            Expanded(
              child: ListView.builder(
                itemCount: assets.length,
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[800],
                      child: Text(asset['symbol'] ?? '?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text('${asset['amount']} ${asset['symbol']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    subtitle: Text('\$${asset['usd']} USD', style: TextStyle(color: Colors.grey)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _walletActionButton(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blue,
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// -------------------- CREATE WALLET SCREEN --------------------
class CreateWalletScreen extends StatefulWidget {
  final WalletService walletService;
  final VoidCallback onWalletCreated;
  
  CreateWalletScreen({required this.walletService, required this.onWalletCreated});
  
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
      
      // Now creating the backup HushWallet
      await widget.walletService.hushWalletService.createWallet(isBackup: true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wallet created successfully!'))
      );
      
      widget.onWalletCreated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating wallet: $e'))
      );
    }
    
    setState(() {
      isCreating = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Create Wallet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: isCreating 
        ? Center(child: CircularProgressIndicator())
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
          SizedBox(height: 30),
          Text(
            'Welcome to Crypt',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            'It looks like you don\'t have a wallet yet. Create one to get started with cryptocurrencies!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple[500],
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _startWalletCreation,
              child: Text(
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
          Text(
            'Your Recovery Phrase',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[900]?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[900]!, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[300]),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Write these words down in the correct order and keep them safe. You will NEVER see them again. Anyone with these words can access your wallet.',
                    style: TextStyle(fontSize: 12, color: Colors.red[100]),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: mnemonicWords.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            mnemonicWords[index],
                            style: TextStyle(fontWeight: FontWeight.bold),
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
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple[500],
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _finishWalletCreation,
              child: Text(
                'I\'ve Saved My Recovery Phrase',
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
  HushWalletScreen({required this.hushWalletService});
  
  @override
  _HushWalletScreenState createState() => _HushWalletScreenState();
}

class _HushWalletScreenState extends State<HushWalletScreen> {
  String? currentWalletAddress;
  String? backupWalletAddress;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadWalletAddresses();
  }
  
  Future<void> _loadWalletAddresses() async {
    setState(() {
      isLoading = true;
    });
    
    currentWalletAddress = await widget.hushWalletService.getCurrentWalletAddress();
    backupWalletAddress = await widget.hushWalletService.getBackupWalletAddress();
    
    setState(() {
      isLoading = false;
    });
  }
  
  Future<void> _triggerSelfDestruct() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Self-Destruct Wallet'),
          content: Text(
            'This will destroy your main wallet and activate your HushWallet. '
            'All funds will be transferred to your HushWallet before destruction. '
            'This action cannot be undone. Are you sure you want to proceed?'
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Proceed', style: TextStyle(color: Colors.red)),
              onPressed: (){
                Navigator.of(context).pop(true);
                widget.hushWalletService.triggerSelfDestruct();
                _loadWalletAddresses();
              } 
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      await widget.hushWalletService.triggerSelfDestruct();
      await _loadWalletAddresses();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HushWallet'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: isLoading ?
          Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HushWallet is a backup wallet that can be activated if your main wallet is compromised.',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  Card(
                    color: Colors.grey[900],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Wallet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            currentWalletAddress ?? 'Not available',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    color: Colors.grey[900],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Backup HushWallet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            backupWalletAddress ?? 'Not available',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _triggerSelfDestruct,
                      child: Text(
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
}
