import 'package:flutter_bloc/flutter_bloc.dart';
import 'upi_event.dart';
import 'upi_state.dart';

class UpiBloc extends Bloc<UpiEvent, UpiState> {
  UpiBloc() : super(const UpiState()) {
    on<UpiPayeeSetEvent>(_onPayeeSet);
    on<UpiAmountUpdatedEvent>(_onAmountUpdated);
    on<UpiPaymentProcessingEvent>(_onPaymentProcessing);
    on<UpiPaymentSuccessEvent>(_onPaymentSuccess);
    on<UpiPaymentFailureEvent>(_onPaymentFailure);
    on<UpiResetEvent>(_onReset);
  }

  void _onPayeeSet(UpiPayeeSetEvent event, Emitter<UpiState> emit) {
    emit(
      state.copyWith(
        status: UpiStatus.payeeSelected,
        payeeUpiId: event.upiId,
        payeeName: event.payeeName,
        clearError: true,
      ),
    );
  }

  void _onAmountUpdated(UpiAmountUpdatedEvent event, Emitter<UpiState> emit) {
    emit(state.copyWith(amount: event.amount, clearError: true));
  }

  void _onPaymentProcessing(
    UpiPaymentProcessingEvent event,
    Emitter<UpiState> emit,
  ) {
    emit(state.copyWith(status: UpiStatus.processing, clearError: true));
  }

  void _onPaymentSuccess(UpiPaymentSuccessEvent event, Emitter<UpiState> emit) {
    emit(
      state.copyWith(
        status: UpiStatus.success,
        amount: event.amount,
        paidAmount: event.amount,
        paidAt: event.paidAt,
        clearError: true,
      ),
    );
  }

  void _onPaymentFailure(UpiPaymentFailureEvent event, Emitter<UpiState> emit) {
    emit(
      state.copyWith(status: UpiStatus.failure, errorMessage: event.message),
    );
  }

  void _onReset(UpiResetEvent event, Emitter<UpiState> emit) {
    emit(const UpiState());
  }
}
