// import 'dart:convert';
import 'hush_wallet_services.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';


//setting up dependencies/tools we will use throughout the service!!!

class WalletService {
  final storage = FlutterSecureStorage(); //saves private key on the devices
  
  // Use Ethereum mainnet for testing - you should replace this with your own API key
  final String rpcUrl = "https://sepolia.infura.io/v3/235b57e865d249359ec1aebd2c620c39";
  final HushWalletService hushWalletService = HushWalletService();
  late Web3Client ethClient;
  late WalletConnect connector;
  SessionStatus? session;

  WalletService() {
    _initializeWeb3Client();
    _initializeWalletConnect();
  }

  void _initializeWeb3Client() {
    final httpClient = http.Client();
    ethClient = Web3Client(rpcUrl, httpClient);
  }

  void _initializeWalletConnect() {
    try {
      connector = WalletConnect(
        bridge: 'https://bridge.walletconnect.org',
        clientMeta: const PeerMeta(
          name: "Crypto Wallet",
          description: "A secure crypto wallet",
          url: "https://example.com",
          icons: ["https://your-app-url.com/icon.png"],
        ),
      );
      print("WalletConnect initialized successfully");
    } catch (e) {
      print("Error initializing WalletConnect: $e");
    }
  }

  Future<bool> _checkConnection() async {
    try {
      // Try to get the network ID as a connection test
      await ethClient.getNetworkId();
      return true;
    } catch (e) {
      print("Connection test failed: $e");
      return false;
    }
  }

  Future<void> _ensureConnection() async {
    if (!await _checkConnection()) {
      print("Reconnecting to Ethereum network...");
      _initializeWeb3Client();
      
      // Test the new connection
      if (!await _checkConnection()) {
        throw Exception("Failed to establish connection to Ethereum network");
      }
    }
  }

/// Creates a new main wallet and a backup HushWallet
  Future<void> setupNewWallet() async {
    print("Setting up a new wallet and backup HushWallet...");
    await hushWalletService.createWallet(isBackup: false);
    await hushWalletService.createWallet(isBackup: true);
  }



  /// Generates a 12-word mnemonic (seed phrase)
  String generateMnemonic() {
    return bip39.generateMnemonic();
  } //generating 12 seed phrases, here we are using the big39 package we included on the top of the code 

  /// Converts seed phrases to private key 
  String derivePrivateKey(String mnemonic) {
    final seed = bip39.mnemonicToSeed(mnemonic); //converts the 12 words into a binary seed
    final root = bip32.BIP32.fromSeed(seed); //creates a root key from binary key 
    final child = root.derivePath("m/44'/60'/0'/0/0"); //follows the path to get a unique private key 
    return HEX.encode(child.privateKey!); //converts the private key into a readable format 
  }

  /// Derives Ethereum (public) address from private key - this address is used perform transaction
  String getEthereumAddress(String privateKey) {
    final private = EthPrivateKey.fromHex(privateKey);
    return private.address.hexEip55;
  }

  /// Saves private key securely
  Future<void> savePrivateKey(String privateKey) async {
    await storage.write(key: "private_key", value: privateKey);
  }

  /// Reads the private key when needed in the future
  Future<String?> loadPrivateKey() async {
    return await storage.read(key: "private_key");
  }

  
  /// Saves the seed phrase securely
  Future<void> saveSeedPhrase(String mnemonic) async {
    await storage.write(key: "seed_phrase", value: mnemonic);
  }

  /// Reads the saved seed phrase when needed
  Future<String?> loadSeedPhrase() async {
    return await storage.read(key: "seed_phrase");
  }

  /// Connects to MetaMask via WalletConnect
  Future<void> connectMetaMask(Function(String) onConnected) async { // input here is the ethereum address of the user's wallet 
    if (!connector.connected) {    //checking if it is not already connected 
      try {
        session = await connector.createSession( //creating a wallet connect session to interact 
          chainId: 11155111, // Sepolia Testnet- these already fixed 
          onDisplayUri: (uri) async {
            print("WalletConnect URI: $uri"); //generates a connect walllet uri if needed - by scanning the QR code you can manually connect 
          },
        );

        if (session != null) { // checks if session was successful or not
          String address = session!.accounts[0];
          onConnected(address); //passes the user's wallet address back to the app
        }
      } catch (e) { // error handling
        print("Error connecting MetaMask: $e");
      }
    }
  }

  /// Disconnects MetaMask
  Future<void> disconnectMetaMask() async {
    if (connector.connected) {
      await connector.killSession();
      session = null;
    }
  }

  /// Connects to MetaMask, transfers all funds to the app's internal wallet, and disconnects
  /// Returns a map with success status and message
  Future<Map<String, dynamic>> connectAndTransferFromMetaMask() async {
    try {
      // Step 1: Connect to MetaMask
      String metamaskAddress = "";
      await connectMetaMask((address) {
        metamaskAddress = address;
      });
      
      // Check if connection was successful
      if (metamaskAddress.isEmpty || !connector.connected) {
        return {
          'success': false,
          'message': 'Failed to connect to MetaMask wallet'
        };
      }
      
      // Step 2: Get the app's internal wallet address
      String? privateKey = await loadPrivateKey();
      if (privateKey == null) {
        await disconnectMetaMask();
        return {
          'success': false,
          'message': 'App wallet not initialized'
        };
      }
      String appWalletAddress = getEthereumAddress(privateKey);
      
      // Step 3: Check MetaMask wallet balance
      // metamaskAddress is guaranteed to be non-null at this point
      EtherAmount metamaskBalance = await getBalance(metamaskAddress);
      if (metamaskBalance.getInWei <= BigInt.zero) {
        await disconnectMetaMask();
        return {
          'success': false,
          'message': 'MetaMask wallet has no funds to transfer'
        };
      }
      
      // Step 4: Get current gas price
      EtherAmount gasPrice;
      try {
        gasPrice = await ethClient.getGasPrice();
      } catch (e) {
        print("Error getting gas price, retrying...");
        await Future.delayed(const Duration(seconds: 2));
        gasPrice = await ethClient.getGasPrice();
      }
      
      // Step 5: Estimate gas needed for the transfer (typically 21000 for ETH transfer)
      BigInt estimatedGas = BigInt.from(21000);
      
      // Step 6: Calculate gas cost
      EtherAmount gasCost = EtherAmount.fromUnitAndValue(
        EtherUnit.wei,
        gasPrice.getInWei * estimatedGas
      );
      
      // Step 7: Calculate transfer amount (total balance minus gas cost)
      EtherAmount transferAmount = EtherAmount.fromUnitAndValue(
        EtherUnit.wei,
        metamaskBalance.getInWei - gasCost.getInWei
      );
      
      // Check if we have enough balance to cover transfer + gas
      if (transferAmount.getInWei <= BigInt.zero) {
        await disconnectMetaMask();
        return {
          'success': false,
          'message': 'Insufficient balance to cover gas costs'
        };
      }
      
      // Step 8: Initiate the transfer
      // Note: This is a simplified implementation. In a real-world scenario,
      // you would need to handle the signing of transactions through MetaMask's interface
      // since MetaMask manages its own private keys.
      // This would typically involve creating a transaction request that MetaMask would sign.
      try {
        // For demonstration purposes, we're assuming we can get the transaction hash
        // In reality, you would use WalletConnect to request the user to sign the transaction
        // in their MetaMask wallet
        final toAddress = EthereumAddress.fromHex(appWalletAddress);
        final transaction = Transaction(
          to: toAddress,
          value: transferAmount,
          gasPrice: gasPrice,
          maxGas: estimatedGas.toInt(),
        );
        
        // This is where you would typically send the transaction request to MetaMask
        // through WalletConnect for the user to approve
        // Use the correct WalletConnect method for sending transactions
        // WalletConnect doesn't have a direct sendTransaction method, so we need to use
        // the sendCustomRequest method with the proper parameters
        final params = [
          {
            'from': metamaskAddress,
            'to': appWalletAddress,
            'value': '0x${transferAmount.getInWei.toRadixString(16)}',
            'gas': '0x${estimatedGas.toRadixString(16)}',
            'gasPrice': '0x${gasPrice.getInWei.toRadixString(16)}',
          }
        ];
        String? txHash = await connector.sendCustomRequest(method: 'eth_sendTransaction', params: params);

        
        if (txHash == null) {
          throw Exception("Transaction was not approved or failed");
        }
        
        // Step 9: Wait for transaction confirmation
        bool confirmed = false;
        int attempts = 0;
        while (!confirmed && attempts < 45) {
          try {
            final receipt = await ethClient.getTransactionReceipt(txHash);
            if (receipt != null) {
              confirmed = true;
              print("Transaction confirmed on blockchain");
            } else {
              attempts++;
              await Future.delayed(const Duration(seconds: 2));
            }
          } catch (e) {
            print("Error checking transaction receipt, retrying...");
            attempts++;
            await Future.delayed(const Duration(seconds: 2));
          }
        }
        
        if (!confirmed) {
          throw Exception("Transaction not confirmed after 90 seconds");
        }
        
        // Step 10: Disconnect from MetaMask
        await disconnectMetaMask();
        
        return {
          'success': true,
          'message': 'Successfully transferred funds from MetaMask to app wallet',
          'txHash': txHash,
          'amount': transferAmount.getValueInUnit(EtherUnit.ether).toString()
        };
      } catch (e) {
        // Ensure we disconnect even if the transaction fails
        await disconnectMetaMask();
        return {
          'success': false,
          'message': 'Failed to transfer funds: ${e.toString()}'
        };
      }
    } catch (e) {
      // Catch any unexpected errors and ensure we disconnect
      try {
        await disconnectMetaMask();
      } catch (_) {}
      
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}'
      };
    }
  }



  /// Fetches ETH balance with proper error handling for Sepolia testnet
  Future<EtherAmount> getBalance(String address) async {
    try {
      await _ensureConnection();
      print("Fetching balance for address: $address");
      EthereumAddress ethAddress = EthereumAddress.fromHex(address);
      final balance = await ethClient.getBalance(ethAddress);
      print("Balance fetched successfully: ${balance.getValueInUnit(EtherUnit.ether)} SepoliaETH");
      return balance;
    } catch (e) {
      print("Error fetching balance: $e");
      return EtherAmount.zero();
    }
  }

  /// Sends ETH transaction
  Future<String> sendTransaction(
      String privateKey, String recipient, double amount) async {
    try {
      await _ensureConnection();
      final credentials = EthPrivateKey.fromHex(privateKey);
      final toAddress = EthereumAddress.fromHex(recipient);
      
      // Get current gas price with retry
      EtherAmount gasPrice;
      try {
        gasPrice = await ethClient.getGasPrice();
      } catch (e) {
        print("Error getting gas price, retrying...");
        await Future.delayed(const Duration(seconds: 2));
        gasPrice = await ethClient.getGasPrice();
      }
      
      // Estimate gas needed for the transfer (typically 21000 for ETH transfer)
      BigInt estimatedGas = BigInt.from(21000);

      final transaction = Transaction(
        to: toAddress,
        value: EtherAmount.fromUnitAndValue(EtherUnit.ether, amount),
        gasPrice: gasPrice,
        maxGas: estimatedGas.toInt(),
      );

      String txHash = await ethClient.sendTransaction(credentials, transaction);
      print("Transaction sent successfully. TxHash: $txHash");
      
      // Wait for transaction confirmation with increased timeout
      bool confirmed = false;
      int attempts = 0;
      while (!confirmed && attempts < 45) { // Increased to 90 seconds timeout
        try {
          final receipt = await ethClient.getTransactionReceipt(txHash);
          if (receipt != null) {
            confirmed = true;
            print("Transaction confirmed on blockchain");
          } else {
            attempts++;
            await Future.delayed(const Duration(seconds: 2));
          }
        } catch (e) {
          print("Error checking transaction receipt, retrying...");
          attempts++;
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      
      if (!confirmed) {
        throw Exception("Transaction not confirmed after 90 seconds");
      }
      
      return txHash;
    } catch (e) {
      print("Error sending transaction: $e");
      throw Exception("Failed to send transaction: $e");
    }
  }

  
  /// Self-destructs the main wallet, transfers assets to HushWallet, and creates a new backup HushWallet
  /// Returns a map with success status and message
  Future<Map<String, dynamic>> selfDestructWallet() async {
    print("Main wallet self-destruct initiated...");
    bool networkAvailable = false;
    
    try {
      // Step 1: Get main wallet and HushWallet details
      String? privateKey = await loadPrivateKey();
      String? seedPhrase = await loadSeedPhrase();
      String? backupAddress = await hushWalletService.getBackupWalletAddress();
      
      if (privateKey == null || seedPhrase == null) {
        return {
          'success': false,
          'message': 'Main wallet not found or not properly initialized'
        };
      }
      
      if (backupAddress == null) {
        return {
          'success': false,
          'message': 'HushWallet not found. Cannot proceed with self-destruct.'
        };
      }
      
      // Check network connectivity before attempting transfers
      try {
        await _ensureConnection();
        networkAvailable = true;
        print("Network connection established successfully");
      } catch (e) {
        print("Network connection failed: $e");
        print("Proceeding with wallet transition without fund transfer");
        networkAvailable = false;
      }
      
      // Step 2: Transfer all assets from main wallet to HushWallet (only if network is available)
      if (networkAvailable) {
        String mainAddress = getEthereumAddress(privateKey);
        print("Transferring all assets from $mainAddress to $backupAddress...");
        
        try {
          // Retry balance check up to 3 times
          EtherAmount balance = EtherAmount.zero();
          int retryCount = 0;
          bool balanceCheckSuccess = false;
          
          while (retryCount < 3 && !balanceCheckSuccess) {
            try {
              balance = await getBalance(mainAddress);
              balanceCheckSuccess = true;
            } catch (e) {
              retryCount++;
              print("Balance check attempt $retryCount failed: $e");
              if (retryCount < 3) {
                await Future.delayed(Duration(seconds: 2));
              }
            }
          }
          
          if (!balanceCheckSuccess) {
            print("Could not check balance after multiple attempts. Skipping fund transfer.");
          } else if (balance.getValueInUnit(EtherUnit.ether) > 0) {
            // Retry gas price check up to 3 times
            EtherAmount gasPrice;
            retryCount = 0;
            bool gasPriceCheckSuccess = false;
            
            while (retryCount < 3 && !gasPriceCheckSuccess) {
              try {
                gasPrice = await ethClient.getGasPrice();
                gasPriceCheckSuccess = true;
                
                // Estimate gas needed
                BigInt estimatedGas = BigInt.from(21000);
                
                // Calculate gas cost
                EtherAmount gasCost = EtherAmount.fromUnitAndValue(
                  EtherUnit.wei,
                  gasPrice.getInWei * estimatedGas
                );
                
                // Subtract gas cost from balance
                EtherAmount transferAmount = EtherAmount.fromUnitAndValue(
                  EtherUnit.wei,
                  balance.getInWei - gasCost.getInWei
                );

                // Only proceed if we have enough balance to cover transfer + gas
                if (transferAmount.getInWei > BigInt.zero) {
                  try {
                    await sendTransaction(
                      privateKey,
                      backupAddress,
                      transferAmount.getValueInUnit(EtherUnit.ether)
                    );
                    print("Funds transferred successfully to HushWallet");
                  } catch (e) {
                    print("Transaction failed: $e");
                    print("Continuing with wallet transition despite transaction failure");
                  }
                } else {
                  print("Insufficient balance to cover gas costs");
                }
              } catch (e) {
                retryCount++;
                print("Gas price check attempt $retryCount failed: $e");
                if (retryCount < 3) {
                  await Future.delayed(Duration(seconds: 2));
                }
              }
            }
            
            if (!gasPriceCheckSuccess) {
              print("Could not get gas price after multiple attempts. Skipping fund transfer.");
            }
          } else {
            print("No funds to transfer");
          }
        } catch (e) {
          print("Error during fund transfer process: $e");
          print("Continuing with wallet transition despite transfer failure");
        }
      }
      
      // Step 3: Promote HushWallet to become the new main wallet
      print("Promoting HushWallet to main wallet...");
      
      // Get HushWallet details before promotion
      String? hushPrivateKey = await hushWalletService.getHushWalletPrivateKey();
      String? hushSeed = await storage.read(key: "hush_wallet_seed");
      
      if (hushPrivateKey == null || hushSeed == null) {
        return {
          'success': false,
          'message': 'HushWallet details not found. Cannot promote to main wallet.'
        };
      }
      
      // Delete main wallet data
      await storage.delete(key: "private_key");
      await storage.delete(key: "seed_phrase");
      print("Main wallet data has been wiped.");
      
      // Save HushWallet data as the new main wallet
      await savePrivateKey(hushPrivateKey);
      await saveSeedPhrase(hushSeed);
      print("HushWallet has been promoted to main wallet.");
      
      // Step 4: Create a new empty HushWallet as backup
      print("Creating new backup HushWallet...");
      try {
        await hushWalletService.createWallet(isBackup: true);
        print("A new backup HushWallet has been created.");
      } catch (e) {
        print("Failed to create new backup HushWallet: $e");
        print("You should create a new backup wallet manually later.");
      }
      
      return {
        'success': true,
        'message': networkAvailable 
            ? 'Self-destruct completed successfully. HushWallet is now the main wallet.' 
            : 'Self-destruct completed with limited functionality due to network issues. HushWallet is now the main wallet, but fund transfer may not have occurred.'
      };
    } catch (e) {
      print("Error during wallet self-destruction: $e");
      return {
        'success': false,
        'message': 'Failed to complete wallet self-destruction: ${e.toString()}'
      };
    }
  }

  /// Gets all assets in the wallet with better error handling
  Future<List<Map<String, String>>> getAllAssets(String address) async {
    List<Map<String, String>> assets = [];
    try {
      print("Fetching assets for address: $address");
      
      // Fetch ETH balance
      EtherAmount ethBalance = await getBalance(address);
      double ethValue = ethBalance.getValueInUnit(EtherUnit.ether);
      
      // For Sepolia testnet, we'll use a fixed rate since it's test ETH
      double ethUsdValue = ethValue * 2000; // Using approximate ETH price

      assets.add({
        'symbol': 'SepoliaETH',
        'amount': ethValue.toStringAsFixed(4),
        'usd': ethUsdValue.toStringAsFixed(2),
      });

      print("Assets fetched successfully");
      return assets;
    } catch (e) {
      print("Error fetching assets: $e");
      return [{
        'symbol': 'SepoliaETH',
        'amount': '0.0000',
        'usd': '0.00',
      }];
    }
  }

}