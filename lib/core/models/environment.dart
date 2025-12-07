class Environment {
  final int? id;
  final String name;

  final String authType;
  final String? username;
  final String? password;
  final String? token;
  final String? customHeaderKey;
  final String? customHeaderValue;

  Environment({
    this.id,
    required this.name,
    this.authType = "none",
    this.username,
    this.password,
    this.token,
    this.customHeaderKey,
    this.customHeaderValue,
  });

  Environment copyWith({
    int? id,
    String? name,
    String? authType,
    String? username,
    String? password,
    String? token,
    String? customHeaderKey,
    String? customHeaderValue,
  }) {
    return Environment(
      id: id ?? this.id,
      name: name ?? this.name,
      authType: authType ?? this.authType,
      username: username ?? this.username,
      password: password ?? this.password,
      token: token ?? this.token,
      customHeaderKey: customHeaderKey ?? this.customHeaderKey,
      customHeaderValue: customHeaderValue ?? this.customHeaderValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "auth_type": authType,
      "username": username,
      "password": password,
      "token": token,
      "custom_header_key": customHeaderKey,
      "custom_header_value": customHeaderValue,
    };
  }

  factory Environment.fromJson(Map<String, dynamic> json) {
    return Environment(
      id: json["id"],
      name: json["name"],
      authType: json["auth_type"] ?? "none",
      username: json["username"],
      password: json["password"],
      token: json["token"],
      customHeaderKey: json["custom_header_key"],
      customHeaderValue: json["custom_header_value"],
    );
  }
}
