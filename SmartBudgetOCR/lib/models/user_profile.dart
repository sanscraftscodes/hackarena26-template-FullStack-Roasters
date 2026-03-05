class UserProfile {
  final String id;
  final String? fullName;
  final String? phoneNumber;
  final DateTime? birthDate;
  final double? income;
  final double? monthlyBudget;

  const UserProfile({
    required this.id,
    this.fullName,
    this.phoneNumber,
    this.birthDate,
    this.income,
    this.monthlyBudget,
  });

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    DateTime? birthDate,
    double? income,
    double? monthlyBudget,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      income: income ?? this.income,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate'] as String) : null,
      income: (json['income'] as num?)?.toDouble(),
      monthlyBudget: (json['monthlyBudget'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'birthDate': birthDate?.toIso8601String(),
      'income': income,
      'monthlyBudget': monthlyBudget,
    };
  }
}

