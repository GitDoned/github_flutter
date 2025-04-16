import 'dart:async';
import 'dart:convert';

import 'package:github_flutter/src/common.dart';
import 'package:http/http.dart' as http;

/// Device Flow Helper
///
/// **Example**:
///
///
class DeviceFlow {
  /// Client ID
  final String clientId;

  /// Requested Scopes
  final List<String> scopes;

  /// Grant type
  final String? grantType;

  /// Device flow Base URL
  final String baseUrl;

  /// GitHub instance
  GitHub? github;

  Map<String, dynamic> _response = {};

  DeviceFlow(
    this.clientId, {
    this.scopes = const [],
    this.baseUrl = 'https://github.com',
    this.grantType = "urn:ietf:params:oauth:grant-type:device_code",
  });

  Future<String> fetchUserCode() async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'content-type': 'application/json',
    };

    final body = GitHubJson.encode(<String, dynamic>{
      'client_id': clientId,
      'scope': scopes.join(','),
    });

    final response = await (github == null ? http.Client() : github!.client)
        .post(
          Uri.parse("$baseUrl/login/device/code"),
          body: body,
          headers: headers,
        );

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    _response = json;

    if (json['error'] != null) {
      throw Exception(json['error']);
    }
    return json['user_code'];
  }

  /// Generates an Authorization URL
  ///
  /// This should be displayed to the user.
  String createAuthorizeUrl() {
    if (_response['verification_uri'] == null) {
      throw Error();
    }
    return '${_response['verification_uri']}?user_code=${_response['user_code']}';
  }

  /// Exchange `device code` after user verified for token
  Future<DeviceFlowExchangeResponse> exchange() {
    if (!_response.containsKey("device_code")) {
      throw Exception("Device code not found");
    }

    final headers = <String, String>{
      'Accept': 'application/json',
      'content-type': 'application/json',
    };

    final body = GitHubJson.encode(<String, dynamic>{
      'client_id': clientId,
      'device_code': _response['device_code'],
      'grant_type': grantType,
    });

    return (github == null ? http.Client() : github!.client)
        .post(
          Uri.parse('$baseUrl/login/oauth/access_token'),
          body: body,
          headers: headers,
        )
        .then((response) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          if (json['error'] != null) {
            throw Exception(json['error'] ?? "Unknown error");
          }
          return DeviceFlowExchangeResponse(
            json['access_token'],
            json['token_type'],
            (json['scope'] as String).split(','),
            json['interval'] ?? 0,
          );
        });
  }
}

/// Represents a response for exchanging a code for a token.
class DeviceFlowExchangeResponse {
  final String? token;
  final List<String> scopes;
  final String? tokenType;
  final int interval;

  DeviceFlowExchangeResponse(
    this.token,
    this.tokenType,
    this.scopes,
    this.interval,
  );
}
