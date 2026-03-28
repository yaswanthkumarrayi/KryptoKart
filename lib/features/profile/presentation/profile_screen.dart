import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kk_button.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/wallet_service.dart';
import '../../../core/service_locator.dart';
import '../../../core/utils/wallet_display.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../scanner/presentation/scanner_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = sl<ApiService>();
  UserModel? _user;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  static const _guestUser = UserModel(
    id: 'local',
    name: 'KryptoKart User',
    phone: '',
    kycStatus: 'pending',
  );

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth is Authenticated) {
      _user = auth.user;
      _isLoading = false;
    }
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_user == null && mounted) {
      setState(() => _isLoading = true);
    }

    UserModel? nextUser = _user;
    Map<String, dynamic> nextStats = _stats;

    try {
      final profileData = await _apiService.getProfile().timeout(
        const Duration(seconds: 4),
      );
      nextUser = UserModel.fromProfileApiResponse(profileData);
    } catch (_) {
      if (!mounted) return;
      final auth = context.read<AuthBloc>().state;
      if (auth is Authenticated) {
        nextUser = auth.user;
      }
    }

    try {
      final statsData = await _apiService.getTransactionStats().timeout(
        const Duration(seconds: 4),
      );
      if (statsData.isNotEmpty) {
        nextStats = Map<String, dynamic>.from(statsData);
      }
    } catch (_) {
      // Stats are optional — keep previous / zeros
    }

    if (!mounted) return;
    setState(() {
      _user = nextUser ?? _guestUser;
      _stats = nextStats;
      _isLoading = false;
    });
  }

  void _showReportDialog() {
    final messageController = TextEditingController();
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(
                      Icons.flag_rounded,
                      color: AppColors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Report an Issue',
                        style: AppTextStyles.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Describe the issue you are facing. Our team will get back to you within 24 hours.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Write your message here...',
                    hintStyle: AppTextStyles.caption,
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 20),
                KkButton(
                  label: 'Send Report',
                  icon: Icons.send,
                  isLoading: isSending,
                  height: 48,
                  onTap: () async {
                    if (messageController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please write a message'),
                          backgroundColor: AppColors.red,
                        ),
                      );
                      return;
                    }
                    setSheetState(() => isSending = true);
                    try {
                      await _apiService.createTransaction({
                        'txnId': 'RPT-${DateTime.now().millisecondsSinceEpoch}',
                        'type': 'report',
                        'amountInr': 0,
                        'recipientName': 'KryptoKart Support',
                        'recipientAddress': messageController.text.trim(),
                        'status': 'pending',
                      });
                    } catch (_) {}

                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Report submitted! We\'ll get back to you soon.',
                          ),
                          backgroundColor: AppColors.green,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUpiDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.send_rounded, color: AppColors.accent, size: 40),
              const SizedBox(height: 12),
              Text('UPI Details', style: AppTextStyles.titleSmall),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  children: [
                    _detailRow('Name', _user?.name ?? 'N/A'),
                    const Divider(color: AppColors.border),
                    _detailRow('Phone', _user?.phone ?? 'N/A'),
                    const Divider(color: AppColors.border),
                    _detailRow('UPI ID', () {
                      final upi = _user?.upiId ?? '';
                      return upi.isEmpty ? 'Not set' : upi;
                    }()),
                    const Divider(color: AppColors.border),
                    _detailRow(
                      'Balance',
                      CurrencyFormatter.formatInr(_user?.upiBalance ?? 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showConnectedWallets() {
    final walletService = sl<WalletService>();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.accent,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'Connected Wallets',
                  style: AppTextStyles.titleSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    children: [
                      _walletRow(
                        walletService.walletName ?? 'MetaMask',
                        Icons.account_balance_wallet_rounded,
                        walletService.isConnected
                            ? shortenWalletAddress(
                                walletService.connectedAddress,
                              )
                            : 'Not connected',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                KkButton(
                  label: walletService.isConnected
                      ? 'Disconnect'
                      : 'Connect MetaMask',
                  icon: walletService.isConnected
                      ? Icons.link_off
                      : Icons.account_balance_wallet_outlined,
                  outlined: walletService.isConnected,
                  height: 44,
                  onTap: () async {
                  if (walletService.isConnected) {
                    await walletService.disconnect();
                  } else {
                    await walletService.connectMetaMask();
                    if (walletService.isConnected &&
                        _apiService.isAuthenticated) {
                      try {
                        await _apiService.updateWallet(
                          walletService.connectedAddress!,
                        );
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Wallet saved: ${shortenWalletAddress(walletService.connectedAddress)}',
                              ),
                              backgroundColor: AppColors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Could not save wallet to account: $e'),
                              backgroundColor: AppColors.red,
                            ),
                          );
                        }
                      }
                    }
                  }
                  setSheetState(() {}); // Refresh the bottom sheet
                  setState(() {}); // Refresh the profile screen
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.end,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletRow(String name, IconData icon, String status) {
    final connected = status != 'Not connected';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            color: connected ? AppColors.accent : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (connected ? AppColors.green : AppColors.textSecondary)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              connected ? 'Connected' : 'Off',
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: connected ? AppColors.green : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = _user ?? _guestUser;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: _isLoading && _user == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async => _loadProfile(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile card
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.surface2,
                            child: Text(
                              u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                              style: AppTextStyles.display.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(u.name, style: AppTextStyles.title),
                          Text(
                            u.phone.isEmpty ? '—' : u.phone,
                            style: AppTextStyles.caption,
                          ),
                          if (u.upiId.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              u.upiId,
                              style: AppTextStyles.captionMedium.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(),

                    const SizedBox(height: 20),

                    // Quick stats (real data from API)
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'Sent',
                            CurrencyFormatter.formatInrCompact(
                              (_stats['totalSent'] ?? 0).toDouble(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            'Received',
                            CurrencyFormatter.formatInrCompact(
                              (_stats['totalReceived'] ?? 0).toDouble(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard('Txns', '${_stats['count'] ?? 0}'),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 20),

                    // Menu items — real-time actions
                    _menuItem(
                      Icons.inventory_2_outlined,
                      'Manage Products',
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const _ManageProductsPage(),
                          ),
                        );
                      },
                    ),
                    _menuItem(
                      Icons.send_rounded,
                      'UPI Details',
                      _showUpiDetails,
                    ),
                    _menuItem(
                      Icons.account_balance_wallet_rounded,
                      'Connected Wallets',
                      _showConnectedWallets,
                    ),
                    _menuItem(
                      Icons.flag_rounded,
                      'Report',
                      _showReportDialog,
                      color: AppColors.yellow,
                    ),
                    _menuItem(Icons.logout_rounded, 'Logout', () {
                      context.read<AuthBloc>().add(LogoutRequested());
                      context.go('/login');
                    }, color: AppColors.red),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(String label, String value) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.accent, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(color: color),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Manage Products Page — accessible from Profile
class _ManageProductsPage extends StatefulWidget {
  const _ManageProductsPage();
  @override
  State<_ManageProductsPage> createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<_ManageProductsPage> {
  final _api = sl<ApiService>();
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.getProducts();
      setState(() {
        _products = (data['products'] as List)
            .map((j) => ProductModel.fromJson(j))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(String id) async {
    try {
      await _api.deleteProduct(id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  void _openScanner() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => const ScannerScreen(productMode: true),
          ),
        )
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: _openScanner,
            tooltip: 'Scan Barcode',
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : _products.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products yet',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      KkButton(
                        label: 'Scan',
                        width: 130,
                        height: 44,
                        icon: Icons.qr_code_scanner,
                        onTap: _openScanner,
                      ),
                      KkButton(
                        label: 'Add',
                        width: 130,
                        height: 44,
                        outlined: true,
                        icon: Icons.add,
                        onTap: _showAddDialog,
                      ),
                    ],
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async => _load(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _products.length,
                itemBuilder: (_, i) {
                  final p = _products[i];
                  return Dismissible(
                    key: Key(p.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(
                            'Delete ${p.name}?',
                            style: AppTextStyles.titleSmall,
                          ),
                          content: Text(
                            'This cannot be undone.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                'Delete',
                                style: TextStyle(color: AppColors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) => _deleteProduct(p.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete, color: AppColors.red),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: AppTextStyles.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Barcode: ${p.barcode}  •  ${p.category}',
                                  style: AppTextStyles.caption,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Text(
                              CurrencyFormatter.formatInr(p.priceInr),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.accent,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: AppColors.background),
      ),
    );
  }

  void _showAddDialog() {
    final nameC = TextEditingController();
    final priceC = TextEditingController();
    final barcodeC = TextEditingController();
    final categoryC = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Product', style: AppTextStyles.titleSmall),
            const SizedBox(height: 16),
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (INR)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: barcodeC,
                    decoration: const InputDecoration(labelText: 'Barcode'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    color: AppColors.accent,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openScanner();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryC,
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
              ),
            ),
            const SizedBox(height: 20),
            KkButton(
              label: 'Add Product',
              onTap: () async {
                if (nameC.text.isEmpty) return;
                try {
                  await _api.createProduct({
                    'name': nameC.text,
                    'priceInr': double.tryParse(priceC.text) ?? 0,
                    'barcode': barcodeC.text.isNotEmpty
                        ? barcodeC.text
                        : DateTime.now().millisecondsSinceEpoch
                              .toString()
                              .substring(0, 10),
                    'category': categoryC.text.isNotEmpty
                        ? categoryC.text
                        : 'General',
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    _load();
                  }
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.red,
                      ),
                    );
                }
              },
              height: 48,
            ),
            ],
          ),
        ),
      ),
    );
  }
}
