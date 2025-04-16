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
  /// OAuth2 Client ID
  final String clientId;

  /// Requested Scopes
  final List<String> scopes;

  /// Grant type
  final String? grantType;

  /// State
  final String? state;

  /// Device flow Base URL
  final String baseUrl;

  Map<String, dynamic> _response = {};

  GitHub? github;

  DeviceFlow(
    this.clientId, {
    this.scopes = const [],
    this.state,
    this.github,
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
    return '${_response['verification_uri']}?user_code=${_response['user_code']}';
  }

  /// Exchange `device code` after user verified for token
  Future<ExchangeResponse> exchange() {
    if (!_response.containsKey("deviceCode")) {
      throw Error();
    }

    final headers = <String, String>{
      'Accept': 'application/json',
      'content-type': 'application/json',
    };

    final body = GitHubJson.encode(<String, dynamic>{
      'client_id': clientId,
      'device_code': _response['deviceCode'],
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
            throw Exception(json['error']);
          }
          return ExchangeResponse(
            json['access_token'],
            json['token_type'],
            (json['scope'] as String).split(','),
          );
        });
  }
}

/// Represents a response for exchanging a code for a token.
class ExchangeResponse {
  final String? token;
  final List<String> scopes;
  final String? tokenType;

  ExchangeResponse(this.token, this.tokenType, this.scopes);
}
