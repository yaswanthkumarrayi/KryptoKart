import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kryptokart/core/error/failure.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

// Get your project ID from https://cloud.walletconnect.com/
// Replace this with your actual WalletConnect project ID
const _kProjectId = 'cbd61271817107b3fc4578e87d6d75b7';
const _kSessionKey = 'wc_session_topic';

class WalletService {
  Web3App? _web3app;
  SessionData? _session;
  final FlutterSecureStorage _storage;

  WalletService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> _init() async {
    if (_web3app != null) return;
    
    // Check if project ID is configured
    if (_kProjectId == 'YOUR_WALLETCONNECT_PROJECT_ID' || _kProjectId.isEmpty) {
      debugPrint('⚠️ WalletConnect: Project ID not configured!');
      debugPrint('Get your project ID from https://cloud.walletconnect.com/');
      return;
    }
    
    _web3app = await Web3App.createInstance(
      projectId: _kProjectId,
      metadata: const PairingMetadata(
        name: 'KryptoKart',
        description: 'KryptoKart — Pay with crypto',
        url: 'https://kryptokart.app',
        icons: ['https://kryptokart.app/icon.png'],
      ),
    );

    // Try restoring saved session
    try {
      final savedTopic = await _storage.read(key: _kSessionKey);
      if (savedTopic != null) {
        final sessions = _web3app!.getActiveSessions();
        _session = sessions[savedTopic];
      }
    } catch (_) {}
  }

  Future<Either<Failure, String>> connectWallet() async {
    try {
      // Check if project ID is configured
      if (_kProjectId == 'YOUR_WALLETCONNECT_PROJECT_ID' || _kProjectId.isEmpty) {
        return const Left(ServerFailure(
          'WalletConnect not configured. Please set your Project ID in wallet_service.dart. '
          'Get one from https://cloud.walletconnect.com/',
        ));
      }
      
      await _init();
      
      if (_web3app == null) {
        return const Left(ServerFailure('Failed to initialize WalletConnect'));
      }

      final ConnectResponse response = await _web3app!.connect(
        requiredNamespaces: {
          'eip155': const RequiredNamespace(
            chains: ['eip155:137'], // Polygon mainnet
            methods: ['eth_sendTransaction', 'eth_signTransaction'],
            events: ['chainChanged', 'accountsChanged'],
          ),
        },
      );

      final Uri? uri = response.uri;
      if (uri == null) {
        return const Left(ServerFailure('Could not generate WalletConnect URI'));
      }

      final deepLink = 'metamask://wc?uri=${Uri.encodeComponent(uri.toString())}';
      final parsed = Uri.parse(deepLink);
      if (await canLaunchUrl(parsed)) {
        await launchUrl(parsed, mode: LaunchMode.externalApplication);
      } else {
        // Fall back to opening the raw WC URI (Trust Wallet, etc.)
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      _session = await response.session.future;
      await _storage.write(key: _kSessionKey, value: _session!.topic);

      final address = getConnectedAddress();
      return address != null
          ? Right(address)
          : const Left(ServerFailure('Wallet connected but no address found'));
    } catch (e) {
      debugPrint('WalletService.connectWallet error: $e');
      return Left(ServerFailure('Wallet connection failed: $e'));
    }
  }

  String? getConnectedAddress() {
    if (_session == null) return null;
    try {
      final accounts = _session!.namespaces['eip155']?.accounts;
      if (accounts == null || accounts.isEmpty) return null;
      // Format: eip155:137:0xABCD...
      return accounts.first.split(':').last;
    } catch (_) {
      return null;
    }
  }

  Future<void> disconnectWallet() async {
    if (_web3app == null || _session == null) return;
    try {
      await _web3app!.disconnectSession(
        topic: _session!.topic,
        reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
      );
    } catch (_) {}
    _session = null;
    await _storage.delete(key: _kSessionKey);
  }

  bool get isConnected => getConnectedAddress() != null;
  
  // Check if WalletConnect is properly configured
  bool get isConfigured => _kProjectId != 'YOUR_WALLETCONNECT_PROJECT_ID' && _kProjectId.isNotEmpty;
}
