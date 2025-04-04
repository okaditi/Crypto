import 'hush_wallet_service.dart';
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
  final String rpcUrl = "https://sepolia.infura.io/v3/235b57e865d249359ec1aebd2c620c39"; // Infura API- intracting w blockchain using etherum node url which in this case is infura, an ethereum provider and i fucking forgot mine so i have to ask bhaiya
  // final HushWalletService hushWalletService = HushWalletService(); 
  late Web3Client ethClient; // lets us send transaction,get balance, interact with smart contracts
  late WalletConnect connector; //connects the metamask wallet to our app
  SessionStatus? session; //keep tracks of metamask wallet connection
}
