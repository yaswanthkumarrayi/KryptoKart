class UserModel {
  final String id;
  final String name;
  final String phone;
  final String upiId;
  final String dob;
  final String walletAddress;
  final String kycStatus;
  final double portfolioValue;
  final double cryptoBalanceInr;
  final double upiBalance;
  final String avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.upiId = '',
    this.dob = '',
    this.walletAddress = '',
    this.kycStatus = 'pending',
    this.portfolioValue = 0,
    this.cryptoBalanceInr = 0,
    this.upiBalance = 0,
    this.avatarUrl = '',
  });

  /// Handles both `{ "user": { ... } }` and a flat user map from `/profile`.
  factory UserModel.fromProfileApiResponse(Map<String, dynamic> json) {
    final raw = json['user'];
    if (raw is Map<String, dynamic>) {
      return UserModel.fromJson(raw);
    }
    return UserModel.fromJson(json);
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      upiId: json['upiId'] ?? '',
      dob: json['dob'] ?? '',
      walletAddress: json['walletAddress'] ?? '',
      kycStatus: json['kycStatus'] ?? 'pending',
      portfolioValue: (json['portfolioValue'] ?? 0).toDouble(),
      cryptoBalanceInr: (json['cryptoBalanceInr'] ?? 0).toDouble(),
      upiBalance: (json['upiBalance'] ?? 0).toDouble(),
      avatarUrl: json['avatarUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'upiId': upiId,
    'dob': dob,
    'walletAddress': walletAddress,
    'kycStatus': kycStatus,
    'portfolioValue': portfolioValue,
    'cryptoBalanceInr': cryptoBalanceInr,
    'upiBalance': upiBalance,
    'avatarUrl': avatarUrl,
  };

  UserModel copyWith({
    String? name,
    String? phone,
    String? upiId,
    String? dob,
    String? walletAddress,
    String? kycStatus,
    double? portfolioValue,
    double? cryptoBalanceInr,
    double? upiBalance,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      upiId: upiId ?? this.upiId,
      dob: dob ?? this.dob,
      walletAddress: walletAddress ?? this.walletAddress,
      kycStatus: kycStatus ?? this.kycStatus,
      portfolioValue: portfolioValue ?? this.portfolioValue,
      cryptoBalanceInr: cryptoBalanceInr ?? this.cryptoBalanceInr,
      upiBalance: upiBalance ?? this.upiBalance,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
