import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kryptokart/core/theme/app_theme.dart';
import 'package:kryptokart/features/payment/data/models/transaction_model.dart';
import 'package:kryptokart/features/payment/presentation/bloc/payment_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ----- App bar / hero header -----
            SliverToBoxAdapter(
              child: _buildHeader(context, theme),
            ),
            // ----- Wallet status card -----
            SliverToBoxAdapter(
              child: _WalletCard(),
            ),
            // ----- Action buttons -----
            SliverToBoxAdapter(
              child: _buildActions(context),
            ),
            // ----- Recent transactions -----
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Recent Transactions',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ),
            _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF9C94FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.currency_bitcoin,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('KryptoKart',
                  style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              Text('Crypto & UPI Payments',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white70)),
            ],
          ),
          const Spacer(),
          IconButton(
            icon:
                const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          // Scan to Pay
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToScanner(context),
              icon: const Icon(Icons.qr_code_scanner, size: 24),
              label: const Text('Scan to Pay',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Send Money
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/payment/picker'),
              icon: const Icon(Icons.send_rounded),
              label: const Text('Send Money',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _navigateToScanner(BuildContext context) async {
    // The scanner page pops with a raw QR string
    final raw = await context.push<String>('/scanner');
    if (raw != null && context.mounted) {
      final rawTrimmed = raw.trim();
      
      // Determine QR type and navigate appropriately
      final isUpi = rawTrimmed.startsWith('upi://') || rawTrimmed.contains('@');
      final isCrypto = rawTrimmed.startsWith('0x') && rawTrimmed.length == 42;

      if (isUpi) {
        String upiId = rawTrimmed;
        if (rawTrimmed.startsWith('upi://')) {
          final uri = Uri.tryParse(rawTrimmed);
          upiId = uri?.queryParameters['pa'] ?? rawTrimmed;
        }
        context.push('/payment/upi', extra: {'upiId': upiId, 'amountInr': 0.0});
      } else if (isCrypto) {
        context.push('/payment/crypto', extra: {'ethAddress': rawTrimmed, 'amountInr': 0.0});
      } else {
        // Unknown QR — go to picker so the user can manually enter amount
        context.push('/payment/picker');
      }
    }
  }

  Widget _buildTransactionList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: ValueListenableBuilder(
        valueListenable:
            Hive.box<TransactionModel>('transactions').listenable(),
        builder: (context, Box<TransactionModel> box, _) {
          final all = box.values.toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          final recent = all.take(5).toList();

          if (recent.isEmpty) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('No transactions yet',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _TxTile(tx: recent[i]),
              childCount: recent.length,
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wallet status card widget
// ---------------------------------------------------------------------------
class _WalletCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        final connected =
            state is WalletConnected || context.read<PaymentBloc>().walletService.isConnected;
        final address = connected
            ? (state is WalletConnected
                ? state.address
                : (context.read<PaymentBloc>().walletService.getConnectedAddress() ?? ''))
            : null;

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: connected
                  ? [const Color(0xFF00C9A7), const Color(0xFF00838A)]
                  : [Colors.grey.shade200, Colors.grey.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (connected ? const Color(0xFF00C9A7) : Colors.grey)
                    .withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                connected ? Icons.account_balance_wallet : Icons.wallet,
                color: connected ? Colors.white : Colors.grey.shade600,
                size: 32,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connected ? 'Wallet Connected' : 'Wallet Not Connected',
                      style: TextStyle(
                        color: connected ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (connected && address != null)
                      Text(
                        _truncateAddress(address),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12),
                      ),
                  ],
                ),
              ),
              connected
                  ? TextButton(
                      onPressed: () =>
                          context.read<PaymentBloc>().add(DisconnectWalletEvent()),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.white),
                      child: const Text('Disconnect'),
                    )
                  : ElevatedButton(
                      onPressed: () =>
                          context.read<PaymentBloc>().add(ConnectWalletEvent()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Connect'),
                    ),
            ],
          ),
        );
      },
    );
  }

  String _truncateAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}

// ---------------------------------------------------------------------------
// Transaction tile
// ---------------------------------------------------------------------------
class _TxTile extends StatelessWidget {
  final TransactionModel tx;
  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCrypto = tx.method == 'crypto';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isCrypto ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
          child: Icon(
            isCrypto ? Icons.currency_bitcoin : Icons.payment,
            color: isCrypto ? Colors.orange : Colors.green,
          ),
        ),
        title: Text(tx.merchantId,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(tx.timestamp),
            style: const TextStyle(fontSize: 11)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${tx.amountInr.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            if (isCrypto && tx.cryptoAmount != null)
              Text(
                  '${tx.cryptoAmount} ${tx.cryptoSymbol ?? ''}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
