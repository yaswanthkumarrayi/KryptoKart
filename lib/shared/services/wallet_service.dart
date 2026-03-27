import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

/// WalletConnect V2 service for real MetaMask connection.
///
/// Opens MetaMask via deep link with a WalletConnect URI, awaits the user's
/// approval, and retrieves the actual Ethereum wallet address.
///
/// After the wallet address is retrieved, it is hardcoded/mapped to a UPI ID
/// on the backend side so that when a UPI QR is scanned and the user chooses
/// Crypto, the transaction uses this real wallet address.
class WalletService {
  // WalletConnect Project ID from https://cloud.walletconnect.com/
  static const _kProjectId = 'cbd61271817107b3fc4578e87d6d75b7';
  static const _kSessionKey = 'wc_session_topic';
  static const _kAddressKey = 'connected_wallet_address';
  static const _kWalletNameKey = 'connected_wallet_name';

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
            methods: ['eth_sendTransaction', 'eth_signTransaction', 'personal_sign'],
            events: ['chainChanged', 'accountsChanged'],
          ),
        },
      );

      // Build MetaMask deep link with the WC URI
      final Uri? uri = response.uri;
      if (uri == null) {
        throw Exception('Could not generate WalletConnect URI');
      }

      final deepLink = 'metamask://wc?uri=${Uri.encodeComponent(uri.toString())}';
      final parsed = Uri.parse(deepLink);

      if (await canLaunchUrl(parsed)) {
        await launchUrl(parsed, mode: LaunchMode.externalApplication);
      } else {
        // Fall back to the raw WC URI (opens any wallet that handles it)
        await launchUrl(uri, mode: LaunchMode.externalApplication);
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
}
