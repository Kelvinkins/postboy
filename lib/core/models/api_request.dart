class ApiRequest {
  final int? id;
  final String name;
  final String url;
  final String method;

  // Auth
  final String authType;               // none, basic, bearer, custom
  final String? username;              // for basic auth
  final String? password;              // for basic auth
  final String? token;                 // for bearer token
  final String? customHeaderKey;       // custom header
  final String? customHeaderValue;

  // Headers
  final String? headers;               // JSON encoded map (for extra headers)

  // Body
  final String? body;

  final String? createdAt;
  final int? environmentId;
  final String contentType;

  ApiRequest({
    this.id,
    required this.name,
    required this.url,
    required this.method,
    this.authType = "none",
    this.username,
    this.password,
    this.token,
    this.customHeaderKey,
    this.customHeaderValue,
    this.headers,
    this.body,
    this.createdAt,
    this.environmentId,
    required this.contentType,

  });

  ApiRequest copyWith({
    int? id,
    String? name,
    String? url,
    String? method,
    String? authType,
    String? username,
    String? password,
    String? token,
    String? customHeaderKey,
    String? customHeaderValue,
    String? headers,
    String? body,
    String? createdAt,
    int? collectionId,
    int? environmentId,
    String? contentType
  }) {
    return ApiRequest(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      method: method ?? this.method,
      authType: authType ?? this.authType,
      username: username ?? this.username,
      password: password ?? this.password,
      token: token ?? this.token,
      customHeaderKey: customHeaderKey ?? this.customHeaderKey,
      customHeaderValue: customHeaderValue ?? this.customHeaderValue,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      environmentId:environmentId??this.environmentId,
      contentType: contentType ?? this.contentType,


    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "url": url,
    "method": method,
    "auth_type": authType,
    "username": username,
    "password": password,
    "token": token,
    "custom_header_key": customHeaderKey,
    "custom_header_value": customHeaderValue,
    "headers": headers,
    "body": body,
    "created_at": createdAt ?? DateTime.now().toIso8601String(),
    "environment_id": environmentId,
    "content_type":contentType
  };

  factory ApiRequest.fromJson(Map<String, dynamic> json) => ApiRequest(
    id: json["id"],
    name: json["name"],
    url: json["url"],
    method: json["method"],
    authType: json["auth_type"] ?? "none",
    username: json["username"],
    password: json["password"],
    token: json["token"],
    customHeaderKey: json["custom_header_key"],
    customHeaderValue: json["custom_header_value"],
    headers: json["headers"],
    body: json["body"],
    createdAt: json["created_at"],
    environmentId: json["environment_id"],
      contentType:json["content_type"]
  );
}
