import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_fixed/core/theme/app_theme.dart';
import 'package:billing_fixed/core/usecase/usecase.dart';
import 'package:billing_fixed/features/payments/data/services/crypto_payment_service.dart';
import 'package:billing_fixed/features/payments/presentation/bloc/payment_bloc.dart';

class CryptoCheckoutScreen extends StatefulWidget {
  final String ethAddress;
  final double amountInr;

  const CryptoCheckoutScreen({
    super.key,
    required this.ethAddress,
    required this.amountInr,
  });

  @override
  State<CryptoCheckoutScreen> createState() => _CryptoCheckoutScreenState();
}

class _CryptoCheckoutScreenState extends State<CryptoCheckoutScreen> {
  CryptoToken _selectedToken = CryptoToken.matic;
  Map<String, double>? _prices;
  bool _loadingPrices = true;

  @override
  void initState() {
    super.initState();
    _fetchPrices();
  }

  Future<void> _fetchPrices() async {
    final result = await context
        .read<PaymentBloc>()
        .getLiveCryptoPrice(NoParams());
    result.fold(
      (_) {
        if (mounted) setState(() => _loadingPrices = false);
      },
      (prices) {
        if (mounted) setState(() {
          _prices = prices;
          _loadingPrices = false;
        });
      },
    );
  }

  String get _cryptoAmountDisplay {
    if (_prices == null) return '...';
    final key = _selectedToken == CryptoToken.eth ? 'eth' : 'matic';
    final price = _prices![key] ?? 0;
    if (price <= 0) return '0';
    return (widget.amountInr / price).toStringAsFixed(6);
  }

  String get _symbol =>
      _selectedToken == CryptoToken.eth ? 'ETH' : 'MATIC';

  static const _accentOrange = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentSuccess) {
          context.pushReplacement('/payment/receipt', extra: state.result);
        } else if (state is PaymentFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700),
          );
        }
      },
      builder: (context, state) {
        final isLoading =
            state is PaymentProcessing || state is FetchingCryptoRate;
        final walletAddress =
            context.read<PaymentBloc>().walletService.getConnectedAddress();
        final isConnected = walletAddress != null;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.chevron_left,
                  size: 28, color: Theme.of(context).primaryColor),
              onPressed: () => context.pop(),
            ),
            title: const Text('Crypto Checkout'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoCard(
                  label: 'To Address',
                  value: _truncate(widget.ethAddress),
                  icon: Icons.account_balance_wallet,
                  color: _accentOrange,
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  label: 'Amount',
                  value: '₹${widget.amountInr.toStringAsFixed(2)}',
                  icon: Icons.currency_rupee,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 20),
                const Text('Select Crypto',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _TokenChip(
                      label: 'MATIC',
                      icon: Icons.hexagon_outlined,
                      selected: _selectedToken == CryptoToken.matic,
                      onTap: () =>
                          setState(() => _selectedToken = CryptoToken.matic),
                    ),
                    const SizedBox(width: 12),
                    _TokenChip(
                      label: 'ETH',
                      icon: Icons.diamond_outlined,
                      selected: _selectedToken == CryptoToken.eth,
                      onTap: () =>
                          setState(() => _selectedToken = CryptoToken.eth),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _accentOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _accentOrange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('You Pay',
                          style: TextStyle(color: Colors.white70)),
                      _loadingPrices
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              '$_cryptoAmountDisplay $_symbol',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? const Color(0xFF45D483).withValues(alpha: 0.12)
                        : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isConnected
                          ? const Color(0xFF45D483).withValues(alpha: 0.4)
                          : AppTheme.cardBorderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isConnected ? Icons.check_circle : Icons.wallet,
                        color: isConnected
                            ? const Color(0xFF45D483)
                            : Colors.white54,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isConnected
                              ? _truncate(walletAddress)
                              : 'Wallet not connected',
                          style: TextStyle(
                              color: isConnected
                                  ? const Color(0xFF45D483)
                                  : Colors.white54,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (!isConnected)
                        TextButton(
                          onPressed: () => context
                              .read<PaymentBloc>()
                              .add(ConnectWalletEvent()),
                          child: const Text('Connect'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (!isLoading && isConnected && !_loadingPrices)
                        ? () => context.read<PaymentBloc>().add(
                              ProcessPaymentEvent(
                                amountInr: widget.amountInr,
                                merchantId: widget.ethAddress,
                                isCrypto: true,
                                cryptoToken: _selectedToken,
                              ),
                            )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentOrange,
                      disabledBackgroundColor:
                          _accentOrange.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            isConnected
                                ? 'Confirm & Pay'
                                : 'Connect Wallet to Pay',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _truncate(String s) {
    if (s.length < 12) return s;
    return '${s.substring(0, 6)}...${s.substring(s.length - 4)}';
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.white54)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TokenChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TokenChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE65100)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFFE65100)
                : AppTheme.cardBorderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? Colors.white : Colors.white54, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
