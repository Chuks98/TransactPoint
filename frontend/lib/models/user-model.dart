class User {
  String firstName;
  String lastName;
  String phoneNumber;
  String? email;
  String? password;
  String? bvn;
  String? walletId; // For wallet tracking
  double? walletBalance;
  List<String> history; // Could store transaction IDs or descriptions

  User({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.email,
    this.password,
    this.bvn,
    this.walletId = '',
    this.walletBalance = 0.0,
    List<String>? history,
  }) : history = history ?? [];

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'phoneNumber': phoneNumber,
    'email': email,
    'password': password,
    'bvn': bvn,
    'walletId': walletId,
    'walletBalance': walletBalance,
    'history': history,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    firstName: json['firstName'],
    lastName: json['lastName'],
    phoneNumber: json['phoneNumber'],
    email: json['email'],
    password: json['password'],
    bvn: json['bvn'],
    walletId: json['walletId'] ?? '',
    walletBalance: (json['walletBalance'] ?? 0).toDouble(),
    history: List<String>.from(json['history'] ?? []),
  );
}
