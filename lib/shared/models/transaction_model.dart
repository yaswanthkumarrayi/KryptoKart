class TransactionModel {
  final String id;
  final String txnId;
  final String type;
  final double amountInr;
  final String? cryptoCoin;
  final double? cryptoAmount;
  final String recipientName;
  final String recipientAddress;
  final String status;
  final String? txnHash;
  final List<String> itemIds;
  final double networkFee;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.txnId,
    required this.type,
    required this.amountInr,
    this.cryptoCoin,
    this.cryptoAmount,
    required this.recipientName,
    this.recipientAddress = '',
    this.status = 'success',
    this.txnHash,
    this.itemIds = const [],
    this.networkFee = 0,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'] ?? json['id'] ?? '',
      txnId: json['txnId'] ?? '',
      type: json['type'] ?? 'upi',
      amountInr: (json['amountInr'] ?? 0).toDouble(),
      cryptoCoin: json['cryptoCoin'],
      cryptoAmount: json['cryptoAmount'] != null
          ? (json['cryptoAmount']).toDouble()
          : null,
      recipientName: json['recipientName'] ?? '',
      recipientAddress: json['recipientAddress'] ?? '',
      status: json['status'] ?? 'pending',
      txnHash: json['txnHash'],
      itemIds: json['itemIds'] != null
          ? List<String>.from(json['itemIds'])
          : [],
      networkFee: (json['networkFee'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'txnId': txnId,
        'type': type,
        'amountInr': amountInr,
        'cryptoCoin': cryptoCoin,
        'cryptoAmount': cryptoAmount,
        'recipientName': recipientName,
        'recipientAddress': recipientAddress,
        'status': status,
        'txnHash': txnHash,
        'itemIds': itemIds,
        'networkFee': networkFee,
      };

  bool get isCrypto => type == 'crypto';
  bool get isUpi => type == 'upi';
  bool get isShopping => type == 'shopping';
  bool get isSuccess => status == 'success';
}
