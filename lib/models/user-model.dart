class User {
  String firstName;
  String lastName;
  String phoneNumber;
  String? email;
  String? password;
  String? walletId; // For wallet tracking
  double? walletBalance;
  List<String> history; // Could store transaction IDs or descriptions

  User({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.email,
    this.password,
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
    walletId: json['walletId'] ?? '',
    walletBalance: (json['walletBalance'] ?? 0).toDouble(),
    history: List<String>.from(json['history'] ?? []),
  );
}
