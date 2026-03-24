import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kryptokart/core/usecase/usecase.dart';
import 'package:kryptokart/features/payment/data/services/crypto_payment_service.dart';
import 'package:kryptokart/features/payment/data/services/wallet_service.dart';
import 'package:kryptokart/features/payment/domain/entities/payment_result.dart';
import 'package:kryptokart/features/payment/domain/usecases/get_live_crypto_price.dart';
import 'package:kryptokart/features/payment/domain/usecases/process_crypto_payment.dart';
import 'package:kryptokart/features/payment/domain/usecases/process_upi_payment.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final ProcessCryptoPayment processCryptoPayment;
  final ProcessUpiPayment processUpiPayment;
  final GetLiveCryptoPrice getLiveCryptoPrice;
  final WalletService walletService;

  PaymentBloc({
    required this.processCryptoPayment,
    required this.processUpiPayment,
    required this.getLiveCryptoPrice,
    required this.walletService,
  }) : super(PaymentInitial()) {
    on<ScanQrCodeEvent>(_onScanQrCode);
    on<SelectPaymentMethodEvent>(_onSelectPaymentMethod);
    on<ConnectWalletEvent>(_onConnectWallet);
    on<DisconnectWalletEvent>(_onDisconnectWallet);
    on<ProcessPaymentEvent>(_onProcessPayment);
    on<ResetPaymentEvent>(_onResetPayment);
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  void _onScanQrCode(ScanQrCodeEvent event, Emitter<PaymentState> emit) {
    final raw = event.rawQrData.trim();

    if (raw.startsWith('upi://') || raw.contains('@')) {
      // Extract UPI id from upi://pay?pa=foo@bar or raw "foo@bar"
      String upiId = raw;
      if (raw.startsWith('upi://')) {
        final uri = Uri.tryParse(raw);
        upiId = uri?.queryParameters['pa'] ?? raw;
      }
      emit(QrScannedUpi(upiId: upiId));
    } else if (raw.startsWith('0x') && raw.length == 42) {
      emit(QrScannedCrypto(ethAddress: raw));
    } else {
      emit(QrScannedUnknown());
    }
  }

  void _onSelectPaymentMethod(
      SelectPaymentMethodEvent event, Emitter<PaymentState> emit) {
    emit(PaymentMethodSelected(event.method));
  }

  Future<void> _onConnectWallet(
      ConnectWalletEvent event, Emitter<PaymentState> emit) async {
    emit(WalletConnecting());
    final result = await walletService.connectWallet();
    result.fold(
      (failure) => emit(PaymentFailure(failure.message)),
      (address) => emit(WalletConnected(address)),
    );
  }

  void _onDisconnectWallet(
      DisconnectWalletEvent event, Emitter<PaymentState> emit) {
    walletService.disconnectWallet();
    emit(WalletDisconnected());
  }

  Future<void> _onProcessPayment(
      ProcessPaymentEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentProcessing());

    if (event.isCrypto) {
      // Fetch live price first
      emit(FetchingCryptoRate());
      final priceResult = await getLiveCryptoPrice(NoParams());
      late Map<String, double> prices;
      bool priceFailed = false;
      priceResult.fold(
        (failure) {
          emit(PaymentFailure(failure.message));
          priceFailed = true;
        },
        (p) => prices = p,
      );
      if (priceFailed) return;

      final token = event.cryptoToken ?? CryptoToken.matic;
      final symbol = token == CryptoToken.eth ? 'ETH' : 'MATIC';
      final priceInr = prices[token == CryptoToken.eth ? 'eth' : 'matic'] ?? 0.0;
      final cryptoAmount = priceInr > 0
          ? (event.amountInr / priceInr).toStringAsFixed(6)
          : '0';

      emit(CryptoRateFetched(inrRate: priceInr, symbol: symbol));
      emit(PaymentProcessing());

      final result = await processCryptoPayment(CryptoPaymentParams(
        merchantEthAddress: event.merchantId,
        amountInr: event.amountInr,
        token: token,
      ));

      result.fold(
        (failure) => emit(PaymentFailure(failure.message)),
        (txHash) => emit(PaymentSuccess(PaymentResult(
          txId: txHash,
          method: PaymentMethod.crypto,
          amountInr: event.amountInr,
          cryptoAmount: cryptoAmount,
          cryptoSymbol: symbol,
          timestamp: DateTime.now(),
          merchantId: event.merchantId,
        ))),
      );
    } else {
      // UPI path
      final result = await processUpiPayment(UpiPaymentParams(
        merchantUpiId: event.merchantId,
        amountInr: event.amountInr,
      ));

      result.fold(
        (failure) => emit(PaymentFailure(failure.message)),
        (paymentId) => emit(PaymentSuccess(PaymentResult(
          txId: paymentId,
          method: PaymentMethod.upi,
          amountInr: event.amountInr,
          timestamp: DateTime.now(),
          merchantId: event.merchantId,
        ))),
      );
    }
  }

  void _onResetPayment(ResetPaymentEvent event, Emitter<PaymentState> emit) {
    emit(PaymentInitial());
  }
}
