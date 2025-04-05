// File: lib/wallet_services.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/web3dart.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

// Import dependent services
import 'hush_wallet_services.dart';
import 'threat_analysis_service.dart';

class WalletService {
  final storage = FlutterSecureStorage();
  // IMPORTANT: Replace with your actual RPC URL
  final String rpcUrl = "https://sepolia.infura.io/v3/YOUR_INFURA_KEY";
  final HushWalletService hushWalletService = HushWalletService();
  // Instantiate Threat Analysis Service (ensure API key is handled securely inside it)
  late final ThreatAnalysisService threatAnalysisService;

  late Web3Client ethClient;
  late WalletConnect connector;
  SessionStatus? session;

  // Flag to indicate if initialization was successful
  bool _isInitialized = false;
  String? _initializationError;

  WalletService() {
    try {
      // Initialize Threat Analysis Service first, as it might throw an error
      threatAnalysisService = ThreatAnalysisService();

      ethClient = Web3Client(rpcUrl, http.Client());

      // Initialize WalletConnect
      connector = WalletConnect(
        bridge: 'https://bridge.walletconnect.org',
        clientMeta: PeerMeta(
          name: "Crypt Wallet", // Your App Name
          description: "An AI-driven secure crypto wallet.",
          url: "https://your-app-url.com", // Replace with your app/project URL
          icons: ["https://your-app-url.com/icon.png"], // Replace with your app icon URL
        ),
      );

      // Listen to WalletConnect events (optional but recommended)
      _setupWalletConnectListeners();

      _isInitialized = true;
      print("WalletService initialized successfully.");

      // Note: setupNewWallet() is NOT called here automatically anymore.
      // It should be triggered by user action (e.g., "Create Wallet" button)

    } catch (e) {
      _isInitialized = false;
      _initializationError = "Error initializing WalletService: $e";
      print(_initializationError);
      // Consider how to communicate this failure to the UI layer
    }
  }

  /// Check if the service initialized correctly
  bool get isInitialized => _isInitialized;
  String? get initializationError => _initializationError;

  /// Sets up listeners for WalletConnect events
  void _setupWalletConnectListeners() {
     connector.on('connect', (sessionStatus) {
      print("WalletConnect connected: ${sessionStatus?.accounts[0]}");
      session = sessionStatus as SessionStatus?; // Cast needed
      // Notify UI or relevant parts of the app
    });

    connector.on('session_update', (payload) {
      print("WalletConnect session updated.");
      session = payload as SessionStatus?;
      // Update UI or state
    });

    connector.on('disconnect', (sessionStatus) {
      print("WalletConnect disconnected.");
      session = null;
      // Update UI or state
    });
  }


  /// Creates a new main wallet AND its corresponding backup HushWallet.
  /// This should likely be called explicitly after user interaction (e.g., clicking 'Create New Wallet').
  /// Returns the mnemonic of the *main* wallet for the user to backup.
  Future<String?> setupNewMainWallet() async {
     if (!isInitialized) {
        print("WalletService not initialized. Cannot setup wallet.");
        return null;
     }
     print("Setting up a new main wallet and backup HushWallet...");
     try {
       // Create main wallet first (isBackup: false)
       Map<String, String> mainWalletDetails = await hushWalletService.createWallet(isBackup: false);
       print("Main wallet created. Address: ${mainWalletDetails['address']}");

       // Backup wallet is created automatically within createWallet(isBackup: false) now
       // So no need to call createWallet(isBackup: true) separately here.

       print("Backup HushWallet created automatically.");

       // Return the MAIN wallet's mnemonic for the user to save
       return mainWalletDetails['mnemonic'];
     } catch (e) {
       print("Error during setupNewMainWallet: $e");
       return null;
     }
  }

  /// Generates a 12-word mnemonic (seed phrase)
  /// Note: This is used internally by createWallet now, but can be exposed if needed.
  String generateMnemonic() {
    return bip39.generateMnemonic();
  }

  /// Derives private key from mnemonic using standard BIP44 path for Ethereum
  /// Note: This is used internally by createWallet now.
  String derivePrivateKey(String mnemonic) {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    // Standard Ethereum derivation path
    final child = root.derivePath("m/44'/60'/0'/0/0");
    if (child.privateKey == null) {
       throw Exception("Could not derive private key. Null private key generated.");
    }
    return HEX.encode(child.privateKey!);
  }

  /// Derives Ethereum (public) address from a private key
  EthereumAddress getEthereumAddress(String privateKey) {
    final private = EthPrivateKey.fromHex(privateKey);
    return private.address;
  }

   /// Loads the currently active MAIN private key from secure storage.
  Future<String?> loadMainPrivateKey() async {
     if (!isInitialized) return null;
     // Key name should match what hushWalletService uses for the active main key
     return await storage.read(key: "main_wallet_private_key");
  }

  /// Loads the currently active MAIN seed phrase from secure storage.
  Future<String?> loadMainSeedPhrase() async {
     if (!isInitialized) return null;
     // Key name should match what hushWalletService uses for the active main key
     return await storage.read(key: "main_wallet_seed");
  }

   /// Loads the currently active MAIN wallet address from secure storage.
  Future<String?> loadMainWalletAddress() async {
     if (!isInitialized) return null;
     // Key name should match what hushWalletService uses for the active main key
     return await storage.read(key: "main_wallet_address");
  }


  /// Connects to MetaMask via WalletConnect
  Future<void> connectMetaMask(Function(String?) onConnected, Function(String) onDisplayUri) async {
    if (!isInitialized) {
       print("WalletService not initialized.");
       onConnected(null); // Indicate failure
       return;
    }
    if (!connector.connected) {
      try {
        session = await connector.createSession(
          chainId: 11155111, // Sepolia Testnet chainId
          onDisplayUri: (uri) {
             print("WalletConnect URI: $uri");
             onDisplayUri(uri); // Pass URI to UI to display QR code
          },
        );

        if (session != null && session!.accounts.isNotEmpty) {
          String address = session!.accounts[0];
          print("MetaMask connected: $address");
          onConnected(address); // Pass address back to the app
        } else {
           print("MetaMask connection session failed or returned no accounts.");
           onConnected(null);
        }
      } catch (e) {
        print("Error connecting MetaMask: $e");
        onConnected(null); // Indicate failure
      }
    } else {
       // Already connected, return current address
       print("Already connected to MetaMask: ${session?.accounts[0]}");
       onConnected(session?.accounts[0]);
    }
  }

  /// Disconnects MetaMask session
  Future<void> disconnectMetaMask() async {
    if (!isInitialized) return;
    if (connector.connected) {
      try {
         await connector.killSession();
         session = null;
         print("MetaMask session killed.");
      } catch (e) {
         print("Error disconnecting MetaMask: $e");
      }
    }
  }

  /// Fetches ETH balance for a given Ethereum address string
  Future<EtherAmount> getBalance(String addressHex) async {
    if (!isInitialized) return EtherAmount.zero();
    try {
       EthereumAddress ethAddress = EthereumAddress.fromHex(addressHex);
       return await ethClient.getBalance(ethAddress);
    } catch (e) {
       print("Error fetching balance for $addressHex: $e");
       return EtherAmount.zero(); // Return zero on error
    }
  }

  /// Sends ETH transaction with pre-send threat analysis.
  /// Requires the private key of the sender.
  /// Returns the transaction hash if successful and confirmed, null otherwise.
  Future<String?> sendTransactionWithAnalysis(
      String privateKey, String recipientHex, double amount) async {
    if (!isInitialized) {
      print("WalletService not initialized.");
      return null;
    }

    print("Analyzing recipient address: $recipientHex");
    final analysisResult = await threatAnalysisService.analyzeForThreat(
      inputData: recipientHex,
      inputType: ThreatInputType.walletAddress,
    );

    print("Threat Analysis Result: $analysisResult");

    bool proceed = true;
    if (analysisResult['isThreat'] == true) {
      // --- IMPORTANT: User Interaction Needed ---
      // TODO: Implement UI Dialog
      // Example: proceed = await showConfirmationDialog(
      //   title: "Security Warning",
      //   message: "AI analysis indicates this address might be risky.\nRisk: ${analysisResult['riskLevel']} (${analysisResult['threatType']})\nReason: ${analysisResult['explanation']}\n\nDo you want to proceed with the transaction?",
      //   confirmText: "Proceed Anyway",
      //   cancelText: "Cancel Transaction"
      // );
      print("⚠️ WARNING: Potential threat detected for address $recipientHex. Type: ${analysisResult['threatType']}, Risk: ${analysisResult['riskLevel']}.");
      proceed = false; // Default to cancel without explicit user confirmation UI
    }

    if (!proceed) {
      print("Transaction cancelled due to threat analysis or user decision.");
      return null; // Indicate cancellation
    }

    // --- Proceed with Transaction Logic ---
    print("Proceeding with transaction to $recipientHex...");
    final credentials = EthPrivateKey.fromHex(privateKey);
    final senderAddress = credentials.address;
    final toAddress = EthereumAddress.fromHex(recipientHex);
    final valueToSend = EtherAmount.fromUnitAndValue(EtherUnit.ether, amount);

    try {
       // Recommended: Estimate gas before sending
       /* BigInt estimatedGas = await ethClient.estimateGas(
          sender: senderAddress,
          to: toAddress,
          value: valueToSend,
       );
       EtherAmount gasPrice = await ethClient.getGasPrice();
       BigInt maxGas = (estimatedGas * BigInt.from(12) / BigInt.from(10)); // Add 20% buffer */

       final transaction = Transaction(
          to: toAddress,
          value: valueToSend,
          // gasPrice: gasPrice, // Use fetched gas price
          // maxGas: maxGas.toInt(), // Use calculated max gas
          // nonce: await ethClient.getTransactionCount(senderAddress), // Recommended for reliability
       );

       final txHash = await ethClient.sendTransaction(
          credentials,
          transaction,
          chainId: 11155111, // Explicitly add chainId (Sepolia) for safety
       );
       print("Transaction submitted successfully: $txHash");
       // TODO: Optionally wait for transaction receipt for confirmation
       return txHash;
    } catch (e) {
       print("Error sending transaction: $e");
       // TODO: Provide more specific error feedback to user (e.g., insufficient funds)
       return null; // Indicate failure
    }
  }

  /// Initiates the self-destruct sequence for the main wallet.
  /// Attempts to transfer funds to the backup HushWallet before wiping keys.
  Future<void> selfDestructWallet() async {
    if (!isInitialized) {
       print("WalletService not initialized. Cannot self-destruct.");
       return;
    }

    print("SELF-DESTRUCT INITIATED for main wallet...");

    // --- User Confirmation ---
    // TODO: Implement UI Dialog
    // bool confirmed = await showConfirmationDialog(
    //    title: "Confirm Self-Destruct",
    //    message: "This action is IRREVERSIBLE. It will attempt to transfer funds to your backup wallet (if available and analysis passes) and then permanently wipe the keys for your current main wallet from this device. Are you absolutely sure?",
    //    confirmText: "Yes, Self-Destruct",
    //    cancelText: "Cancel"
    // );
    // if (!confirmed) {
    //    print("Self-destruct cancelled by user.");
    //    return;
    // }

    String? mainPrivateKey = await loadMainPrivateKey();
    String? backupAddress = await hushWalletService.getBackupWalletAddress();

    if (mainPrivateKey == null) {
       print("Error: Main private key not found. Cannot proceed with self-destruct.");
       // Maybe the wallet was already wiped? Or storage error?
       return;
    }

    EthereumAddress mainAddress = getEthereumAddress(mainPrivateKey);
    print("Main wallet address: ${mainAddress.hexEip55}");

    bool transferAttempted = false;
    bool transferSuccessful = false;

    if (backupAddress != null) {
       print("Backup wallet address found: $backupAddress");

       // Optional but Recommended: Analyze backup address before sending funds
       print("Analyzing backup wallet address for threats...");
       final backupAnalysis = await threatAnalysisService.analyzeForThreat(
          inputData: backupAddress,
          inputType: ThreatInputType.walletAddress,
       );

       if (backupAnalysis['isThreat'] == true) {
          print("⚠️ CRITICAL WARNING: Backup address flagged by analysis: ${backupAnalysis['explanation']}. Transfer ABORTED.");
          // TODO: Notify user prominently about this critical failure.
          // Do NOT proceed with transfer. Decide if wipe should still happen? Risky.
          // For safety, maybe abort the whole self-destruct here?
          print("Self-destruct aborted due to risky backup address.");
          return; // Abort full process for safety
       } else {
          print("Backup address analysis passed. Proceeding with fund transfer attempt.");
          try {
             EtherAmount balance = await getBalance(mainAddress.hexEip55);
             print("Current main wallet balance: ${balance.getValueInUnit(EtherUnit.ether)} ETH");

             // --- Precise Gas Calculation Needed Here ---
             // You MUST calculate the gas cost for the transfer and subtract it
             // from the balance to determine the actual transferable amount.
             // Sending the full balance will fail due to insufficient gas.
             // This is a simplified check:
             if (balance.getInWei > BigInt.from(21000 * 5e9)) { // Rough check if balance > basic gas * some gwei
               // TODO: Replace with actual gas estimation and calculation
               double amountToSend = balance.getValueInUnit(EtherUnit.ether) - 0.001; // FAKE CALCULATION - REPLACE
               if (amountToSend > 0) {
                  print("Attempting to transfer ~$amountToSend ETH to backup wallet...");
                  transferAttempted = true;
                  String? txHash = await sendTransactionWithAnalysis(mainPrivateKey, backupAddress, amountToSend);
                  if (txHash != null) {
                     transferSuccessful = true;
                     print("Fund transfer transaction submitted: $txHash. Waiting for confirmation might be needed.");
                  } else {
                     print("Fund transfer failed during self-destruct sequence.");
                  }
               } else {
                  print("Calculated amount to send is zero or negative after estimated gas. Skipping transfer.");
               }
             } else {
                print("Insufficient balance for transfer gas fees. Skipping transfer.");
             }
          } catch (e) {
             print("Error during fund transfer in self-destruct: $e");
             // Log error, but continue to wipe phase as per irreversible action
          }
       }
    } else {
       print("No backup wallet address found. Cannot transfer funds.");
       // TODO: Inform user funds will be lost if they proceed without backup setup.
       // Confirmation dialog should have made this clear.
    }

    // --- Wipe Phase ---
    // Proceed with wiping regardless of transfer success (as per irreversibility)
    // Unless a critical issue like risky backup address aborted the whole process.
    print("Wiping main wallet keys...");
    await storage.delete(key: "main_wallet_private_key");
    await storage.delete(key: "main_wallet_seed");
    await storage.delete(key: "main_wallet_address");
    // TODO: Consider wiping any other sensitive data associated with the main wallet

    print("Main wallet keys wiped from secure storage.");

    // --- Activation Phase ---
    // Tell HushWalletService to promote the backup to main
    // and setup the creation of a *new* backup.
    await hushWalletService.activateHushWallet(); // This handles the promotion and setup for new backup creation
    print("HushWallet activation process initiated. Follow prompts if needed to create new backup.");

    // TODO: Navigate user back to onboarding or appropriate screen in the UI.
  }

  // --- Additional Helper Methods ---

  /// Fetches the ETH to USD conversion rate using CoinGecko API
  Future<double> getEthToUsdRate() async {
    if (!isInitialized) return 0.0;
    final url = Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd');
    try {
       final response = await http.get(url);
       if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['ethereum'] != null && data['ethereum']['usd'] != null) {
             return data['ethereum']['usd'].toDouble();
          } else {
             print("Unexpected response format from CoinGecko.");
             return 0.0;
          }
       } else {
          print("Failed to fetch ETH price. Status code: ${response.statusCode}");
          return 0.0; // Return 0 on error
       }
    } catch (e) {
       print("Error fetching ETH price: $e");
       return 0.0; // Return 0 on error
    }
  }

  /// Gets assets (currently just ETH) in the main wallet
  /// Assumes main wallet address is loaded or available.
  Future<List<Map<String, String>>> getAllAssets() async {
     if (!isInitialized) return [];

     String? address = await loadMainWalletAddress();
     if (address == null) {
        print("No main wallet address found to fetch assets.");
        return [];
     }

     List<Map<String, String>> assets = [];
     try {
        // Fetch ETH balance
        EtherAmount ethBalance = await getBalance(address);
        double ethValue = ethBalance.getValueInUnit(EtherUnit.ether);
        double ethToUsdRate = await getEthToUsdRate();
        double ethUsdValue = ethValue * ethToUsdRate;

        assets.add({
           'symbol': 'ETH',
           'name': 'Ethereum', // Add full name
           'amount': ethValue.toStringAsFixed(6), // Show more precision
           'usd_value': ethUsdValue.toStringAsFixed(2),
           'usd_rate': ethToUsdRate.toStringAsFixed(2), // Show current rate
        });

        // TODO: Add logic here to fetch balances for other tokens (ERC20)
        // This would involve interacting with ERC20 contract ABIs.

     } catch (e) {
        print("Error fetching assets: $e");
        // Return empty or partial list on error
     }
     return assets;
  }
}