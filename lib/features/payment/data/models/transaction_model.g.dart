// GENERATED CODE - DO NOT MODIFY BY HAND
// Manually written adapter since build_runner is not run at this step.
// Run `flutter pub run build_runner build` to regenerate.

part of 'transaction_model.dart';

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 2;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel(
      txId: fields[0] as String,
      method: fields[1] as String,
      amountInr: fields[2] as double,
      cryptoAmount: fields[3] as String?,
      cryptoSymbol: fields[4] as String?,
      timestamp: fields[5] as DateTime,
      merchantId: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.txId)
      ..writeByte(1)
      ..write(obj.method)
      ..writeByte(2)
      ..write(obj.amountInr)
      ..writeByte(3)
      ..write(obj.cryptoAmount)
      ..writeByte(4)
      ..write(obj.cryptoSymbol)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.merchantId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
