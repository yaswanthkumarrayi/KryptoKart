import 'package:equatable/equatable.dart';

class Merchant extends Equatable {
  final String name;
  final String? upiId;
  final String? ethereumAddress;
  final bool acceptsCrypto;
  final bool acceptsUpi;

  const Merchant({
    required this.name,
    this.upiId,
    this.ethereumAddress,
    this.acceptsCrypto = false,
    this.acceptsUpi = false,
  });

  @override
  List<Object?> get props =>
      [name, upiId, ethereumAddress, acceptsCrypto, acceptsUpi];
}
