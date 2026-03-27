import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:equatable/equatable.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/utils/date_formatter.dart';

// BLoC
abstract class TransactionsEvent extends Equatable { @override List<Object?> get props => []; }
class LoadTransactions extends TransactionsEvent {}
class FilterTransactions extends TransactionsEvent { final String filter; FilterTransactions(this.filter); @override List<Object> get props => [filter]; }

abstract class TransactionsState extends Equatable { @override List<Object?> get props => []; }
class TransactionsInitial extends TransactionsState {}
class TransactionsLoading extends TransactionsState {}
class TransactionsLoaded extends TransactionsState { final List<TransactionModel> transactions; final String activeFilter; TransactionsLoaded(this.transactions, {this.activeFilter = 'All'}); @override List<Object> get props => [transactions, activeFilter]; }
class TransactionsError extends TransactionsState { final String message; TransactionsError(this.message); @override List<Object> get props => [message]; }

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final ApiService _apiService;
  TransactionsBloc(this._apiService) : super(TransactionsInitial()) { on<LoadTransactions>(_onLoad); on<FilterTransactions>(_onFilter); }
  Future<void> _onLoad(LoadTransactions event, Emitter<TransactionsState> emit) async {
    emit(TransactionsLoading());
    try { final data = await _apiService.getTransactions(limit: 50); final txns = (data['transactions'] as List).map((j) => TransactionModel.fromJson(j)).toList(); emit(TransactionsLoaded(txns)); } catch (e) { emit(TransactionsError('Failed to load transactions')); }
  }
  Future<void> _onFilter(FilterTransactions event, Emitter<TransactionsState> emit) async {
    emit(TransactionsLoading());
    try { final type = event.filter.toLowerCase() == 'all' ? null : event.filter.toLowerCase(); final data = await _apiService.getTransactions(type: type, limit: 50); final txns = (data['transactions'] as List).map((j) => TransactionModel.fromJson(j)).toList(); emit(TransactionsLoaded(txns, activeFilter: event.filter)); } catch (e) { emit(TransactionsError('Failed to load transactions')); }
  }
}

// Screen
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Activity'), actions: [IconButton(icon: const Icon(Icons.filter_list), onPressed: () {})]),
      body: BlocBuilder<TransactionsBloc, TransactionsState>(builder: (context, state) {
        if (state is TransactionsLoading) return Padding(padding: const EdgeInsets.all(16), child: ShimmerLoader.list(count: 6));
        if (state is TransactionsError) return KkErrorWidget(message: state.message, onRetry: () => context.read<TransactionsBloc>().add(LoadTransactions()));
        if (state is TransactionsLoaded) return _content(context, state);
        return const SizedBox();
      }),
    );
  }

  Widget _content(BuildContext context, TransactionsLoaded state) {
    final filters = ['All', 'UPI', 'Crypto', 'Shopping'];
    final grouped = <String, List<TransactionModel>>{};
    for (final txn in state.transactions) { final key = DateFormatter.groupHeader(txn.createdAt); grouped.putIfAbsent(key, () => []).add(txn); }

    return Column(children: [
      SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: filters.map((f) => Padding(padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(label: Text(f), selected: state.activeFilter == f, selectedColor: AppColors.accent.withValues(alpha: 0.2),
          onSelected: (_) => context.read<TransactionsBloc>().add(FilterTransactions(f)),
          side: BorderSide(color: state.activeFilter == f ? AppColors.accent : AppColors.border),
          labelStyle: TextStyle(color: state.activeFilter == f ? AppColors.accent : AppColors.textSecondary, fontWeight: FontWeight.w500)))).toList())),
      const SizedBox(height: 8),
      Expanded(child: state.transactions.isEmpty ? const KkEmptyWidget(message: 'No transactions yet', icon: Icons.receipt_long_outlined)
          : RefreshIndicator(color: AppColors.accent, onRefresh: () async => context.read<TransactionsBloc>().add(LoadTransactions()),
              child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: grouped.length, itemBuilder: (_, si) {
                final header = grouped.keys.elementAt(si); final txns = grouped[header]!;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(header, style: AppTextStyles.captionMedium)),
                  ...txns.map((t) => TransactionTile(transaction: t, onTap: () => context.push('/transaction/${t.id}'))),
                ]);
              }))),
    ]);
  }
}
