import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

/// Transaction result containing status and hash
class CryptoTransactionResult {
  final bool success;
  final String? transactionHash;
  final String? errorMessage;

  CryptoTransactionResult({
    required this.success,
    this.transactionHash,
    this.errorMessage,
  });
}

/// WalletConnect V2 service for real MetaMask connection and transactions.
///
/// Opens MetaMask via deep link with a WalletConnect URI, awaits the user's
/// approval, and retrieves the actual Ethereum wallet address.
///
/// Supports sending real ETH transactions via eth_sendTransaction.
class WalletService {
  // WalletConnect Project ID from https://cloud.walletconnect.com/
  static const _kProjectId = 'cbd61271817107b3fc4578e87d6d75b7';
  static const _kSessionKey = 'wc_session_topic';
  static const _kAddressKey = 'connected_wallet_address';
  static const _kWalletNameKey = 'connected_wallet_name';

  // Default receiver wallet for crypto payments (your merchant wallet)
  static const _kDefaultReceiverWallet =
      '0x742d35Cc6634C0532925a3b844Bc9e7595f4A1D2';

  Web3App? _web3app;
  SessionData? _session;
  String? _connectedAddress;
  String? _walletName;

  final FlutterSecureStorage _storage;

  WalletService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Initialize the service and restore any saved session.
  Future<void> init() async {
    try {
      // Restore saved address from secure storage
      _connectedAddress = await _storage.read(key: _kAddressKey);
      _walletName = await _storage.read(key: _kWalletNameKey);
      if (_connectedAddress != null) {
        debugPrint('[WalletService] Restored wallet: $_connectedAddress');
      }
    } catch (e) {
      debugPrint('[WalletService] init error: $e');
    }
  }

  /// Initialize the Web3App instance (lazy).
  Future<void> _initWeb3App() async {
    if (_web3app != null) return;

    _web3app = await Web3App.createInstance(
      projectId: _kProjectId,
      metadata: const PairingMetadata(
        name: 'KryptoKart',
        description: 'KryptoKart — Pay with crypto',
        url: 'https://kryptokart.app',
        icons: ['https://kryptokart.app/icon.png'],
      ),
    );

    // Try to restore existing session
    try {
      final savedTopic = await _storage.read(key: _kSessionKey);
      if (savedTopic != null) {
        final sessions = _web3app!.getActiveSessions();
        _session = sessions[savedTopic];
        if (_session != null) {
          _connectedAddress = _getAddressFromSession();
        }
      }
    } catch (_) {}
  }

  /// Connect to MetaMask wallet via WalletConnect V2.
  ///
  /// Opens MetaMask app, waits for the user to approve, then returns
  /// the actual wallet address.
  Future<String> connectMetaMask() async {
    try {
      await _initWeb3App();

      if (_web3app == null) {
        throw Exception('Failed to initialize WalletConnect');
      }

      // Request a new connection session
      final ConnectResponse response = await _web3app!.connect(
        requiredNamespaces: {
          'eip155': const RequiredNamespace(
            chains: ['eip155:1'], // Ethereum mainnet
            methods: [
              'eth_sendTransaction',
              'eth_signTransaction',
              'personal_sign',
            ],
            events: ['chainChanged', 'accountsChanged'],
          ),
        },
      );

      // Build MetaMask deep link with the WC URI
      final Uri? uri = response.uri;
      if (uri == null) {
        throw Exception('Could not generate WalletConnect URI');
      }

      // Using the Universal Link for MetaMask for better reliability on mobile
      final encodedUri = Uri.encodeComponent(uri.toString());
      final universalLink = 'https://metamask.app.link/wc?uri=$encodedUri';
      final nativeLink = 'metamask://wc?uri=$encodedUri';

      final universalUri = Uri.parse(universalLink);
      final nativeUri = Uri.parse(nativeLink);

      // Try Universal Link first (best for iOS/Android)
      if (await canLaunchUrl(universalUri)) {
        await launchUrl(universalUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(nativeUri)) {
        // Fallback to custom scheme
        await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(uri)) {
        // Fallback to raw WalletConnect URI
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('MetaMask is not installed or could not be opened');
      }

      // Wait for user to approve in MetaMask — this future resolves
      // when they tap "Connect" in the MetaMask popup.
      _session = await response.session.future;
      _connectedAddress = _getAddressFromSession();
      _walletName = 'MetaMask';

      // Persist the session and address
      await _storage.write(key: _kSessionKey, value: _session!.topic);
      if (_connectedAddress != null) {
        await _storage.write(key: _kAddressKey, value: _connectedAddress!);
        await _storage.write(key: _kWalletNameKey, value: _walletName!);
      }

      debugPrint('[WalletService] MetaMask connected: $_connectedAddress');

      if (_connectedAddress == null) {
        throw Exception('Wallet connected but no address found');
      }

      return _connectedAddress!;
    } catch (e) {
      debugPrint('[WalletService] connectMetaMask error: $e');
      rethrow;
    }
  }

  /// Extract the Ethereum address from the active session.
  String? _getAddressFromSession() {
    if (_session == null) return null;
    try {
      final accounts = _session!.namespaces['eip155']?.accounts;
      if (accounts == null || accounts.isEmpty) return null;
      // Format: eip155:1:0xABCD...
      return accounts.first.split(':').last;
    } catch (_) {
      return null;
    }
  }

  /// Disconnect the current wallet session.
  Future<void> disconnect() async {
    if (_web3app != null && _session != null) {
      try {
        await _web3app!.disconnectSession(
          topic: _session!.topic,
          reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
        );
      } catch (_) {}
    }
    _session = null;
    _connectedAddress = null;
    _walletName = null;
    await _storage.delete(key: _kSessionKey);
    await _storage.delete(key: _kAddressKey);
    await _storage.delete(key: _kWalletNameKey);
    debugPrint('[WalletService] Wallet disconnected');
  }

  /// The currently connected wallet address, or null.
  String? get connectedAddress => _connectedAddress;

  /// The name of the connected wallet (e.g. "MetaMask").
  String? get walletName => _walletName;

  /// Whether a wallet is currently connected.
  bool get isConnected =>
      _connectedAddress != null && _connectedAddress!.isNotEmpty;

  /// The default receiver wallet address for payments
  String get defaultReceiverWallet => _kDefaultReceiverWallet;

  /// Send a real ETH transaction via MetaMask.
  /// 
  /// [toAddress] - The recipient wallet address
  /// [amountInEth] - Amount in ETH (e.g., 0.001 for 0.001 ETH)
  /// [data] - Optional hex data for smart contracts
  /// 
  /// Returns a [CryptoTransactionResult] with success status and transaction hash
  Future<CryptoTransactionResult> sendTransaction({
    required String toAddress,
    required double amountInEth,
    String? data,
  }) async {
    try {
      // Ensure wallet is connected
      if (!isConnected || _session == null || _web3app == null) {
        // Try to connect first
        await connectMetaMask();
        if (!isConnected || _session == null) {
          return CryptoTransactionResult(
            success: false,
            errorMessage: 'Please connect your MetaMask wallet first',
          );
        }
      }

      // Convert ETH to Wei (1 ETH = 10^18 Wei)
      final amountInWei = BigInt.from(amountInEth * 1e18);
      final hexAmount = '0x${amountInWei.toRadixString(16)}';

      // Build the transaction request
      final transaction = {
        'from': _connectedAddress,
        'to': toAddress,
        'value': hexAmount,
        'gas': '0x5208', // 21000 gas for standard ETH transfer
      };

      // Add data if provided (for smart contracts)
      if (data != null && data.isNotEmpty) {
        transaction['data'] = data;
      }

      debugPrint('[WalletService] Sending transaction: $transaction');

      // Open MetaMask to confirm the transaction
      final deepLink = 'metamask://';
      final parsed = Uri.parse(deepLink);
      if (await canLaunchUrl(parsed)) {
        await launchUrl(parsed, mode: LaunchMode.externalApplication);
      }

      // Send the transaction request via WalletConnect
      final result = await _web3app!.request(
        topic: _session!.topic,
        chainId: 'eip155:1', // Ethereum mainnet
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: [transaction],
        ),
      );

      // Result should be the transaction hash
      final txHash = result?.toString();
      debugPrint('[WalletService] Transaction hash: $txHash');

      return CryptoTransactionResult(
        success: txHash != null && txHash.isNotEmpty,
        transactionHash: txHash,
      );
    } on JsonRpcError catch (e) {
      debugPrint('[WalletService] JSON-RPC error: ${e.message}');
      
      // User rejected the transaction
      if (e.code == 4001 || (e.message?.toLowerCase().contains('reject') ?? false)) {
        return CryptoTransactionResult(
          success: false,
          errorMessage: 'Transaction was rejected by user',
        );
      }
      
      return CryptoTransactionResult(
        success: false,
        errorMessage: e.message ?? 'Transaction failed',
      );
    } catch (e) {
      debugPrint('[WalletService] sendTransaction error: $e');
      
      // Check for common error patterns
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('reject') || errorStr.contains('denied')) {
        return CryptoTransactionResult(
          success: false,
          errorMessage: 'Transaction was rejected by user',
        );
      }
      if (errorStr.contains('insufficient')) {
        return CryptoTransactionResult(
          success: false,
          errorMessage: 'Insufficient funds for transaction',
        );
      }
      if (errorStr.contains('network') || errorStr.contains('timeout')) {
        return CryptoTransactionResult(
          success: false,
          errorMessage: 'Network error. Please check your connection and try again.',
        );
      }
      
      return CryptoTransactionResult(
        success: false,
        errorMessage: 'Transaction failed: ${e.toString()}',
      );
    }
  }

  /// Convenience method to pay a specific amount in INR converted to crypto.
  /// 
  /// [cryptoAmount] - The amount of crypto to send (already converted from INR)
  /// [receiverWallet] - Optional custom receiver wallet (defaults to merchant wallet)
  Future<CryptoTransactionResult> payWithCrypto({
    required double cryptoAmount,
    String? receiverWallet,
  }) async {
    return sendTransaction(
      toAddress: receiverWallet ?? _kDefaultReceiverWallet,
      amountInEth: cryptoAmount,
    );
  }

  /// Check if the current session is still valid
  Future<bool> checkSessionValid() async {
    if (_session == null || _web3app == null) return false;
    try {
      final sessions = _web3app!.getActiveSessions();
      return sessions.containsKey(_session!.topic);
    } catch (e) {
      debugPrint('[WalletService] Session check error: $e');
      return false;
    }
  }
}
