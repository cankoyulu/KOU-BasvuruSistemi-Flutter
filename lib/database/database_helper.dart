//@dart=2.9
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:json_object_lite/json_object_lite.dart';

/// Response object compatible with the old Wilt interface.
/// Uses real fields instead of JsonObjectLite dot-notation setters.
class CouchResponse {
  bool error;
  int errorCode;
  String method;
  String responseText;
  JsonObjectLite<dynamic> jsonCouchResponse;

  /// Alias for jsonCouchResponse (some code paths access .json).
  JsonObjectLite<dynamic> get json => jsonCouchResponse;
}

/// Lightweight CouchDB client for Flutter Web using dart:html HttpRequest.
/// Replaces the Wilt library which was unreliable in the browser
/// (http.Client could hang silently; postDocument ignored _id fields).
class DatabaseHelper {
  String _dbName = 'kou-database';
  static const String _user = 'admin';
  static const String _password = '123321k';

  /// Builds the full URL for a CouchDB path, prepending the database name
  /// when the path doesn't already include it.
  String _buildUrl(String path) {
    final host = html.window.location.hostname;
    final portStr = html.window.location.port;
    final ssl = html.window.location.protocol == 'https:';
    final port = portStr.isNotEmpty ? int.parse(portStr) : (ssl ? 443 : 80);
    final scheme = ssl ? 'https' : 'http';

    // Normalise path
    if (path == null || path.isEmpty) {
      path = '/';
    }
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    return '$scheme://$host:$port/$_dbName$path';
  }

  /// Returns the Basic auth header value.
  String get _authHeader {
    final credentials = '$_user:$_password';
    final encoded = html.window.btoa(credentials);
    return 'Basic $encoded';
  }

  /// Low-level HTTP request returning a CouchResponse object.
  Future<CouchResponse> _request(String method, String url,
      {String body, Map<String, String> extraHeaders}) async {
    final completer = Completer<CouchResponse>();

    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': _authHeader,
    };
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    try {
      final xhr = html.HttpRequest();
      xhr.open(method, url);
      headers.forEach((k, v) => xhr.setRequestHeader(k, v));

      xhr.onLoad.listen((_) {
        final response = CouchResponse();
        response.errorCode = xhr.status;
        response.responseText = xhr.responseText;
        response.method = method;

        if (xhr.status >= 200 && xhr.status < 300) {
          response.error = false;
          try {
            response.jsonCouchResponse =
                JsonObjectLite<dynamic>.fromJsonString(xhr.responseText);
          } catch (e) {
            response.error = true;
            final err = JsonObjectLite<dynamic>();
            err['error'] = 'json Decode Error';
            err['reason'] = e.toString();
            response.jsonCouchResponse = err;
          }
        } else {
          response.error = true;
          try {
            response.jsonCouchResponse =
                JsonObjectLite<dynamic>.fromJsonString(xhr.responseText);
          } catch (e) {
            final err = JsonObjectLite<dynamic>();
            err['error'] = 'HTTP ${xhr.status}';
            err['reason'] = xhr.statusText ?? 'Request failed';
            response.jsonCouchResponse = err;
          }
        }

        if (!completer.isCompleted) {
          completer.complete(response);
        }
      });

      xhr.onError.listen((_) {
        final response = CouchResponse();
        response.error = true;
        response.errorCode = 0;
        response.method = method;
        final err = JsonObjectLite<dynamic>();
        err['error'] = 'Network error';
        err['reason'] = 'HTTP request failed';
        response.jsonCouchResponse = err;

        if (!completer.isCompleted) {
          completer.complete(response);
        }
      });

      if (body != null) {
        xhr.send(body);
      } else {
        xhr.send();
      }
    } catch (e) {
      final response = CouchResponse();
      response.error = true;
      response.errorCode = 0;
      response.method = method;
      final err = JsonObjectLite<dynamic>();
      err['error'] = 'Exception';
      err['reason'] = e.toString();
      response.jsonCouchResponse = err;

      if (!completer.isCompleted) {
        completer.complete(response);
      }
    }

    return completer.future;
  }

  /// Creates and returns a DatabaseHelper instance (compatible with old
  /// code that expected a Wilt-like object from Connection()).
  DatabaseHelper Connection() => this;

  /// GET a document by id.
  Future<CouchResponse> getDocument(String id) async {
    final url = _buildUrl(id);
    return _request('GET', url);
  }

  /// GET a raw path (e.g. a view URL).
  Future<CouchResponse> get(String path) async {
    final url = _buildUrl(path);
    return _request('GET', url);
  }

  /// POST a document (CouchDB generates a random _id).
  Future<CouchResponse> postDocument(JsonObjectLite<dynamic> document,
      {String path}) async {
    var urlPath = path != null ? '/$path' : '/';
    final url = _buildUrl(urlPath);
    return _request('POST', url,
        body: json.encode(document),
        extraHeaders: {'Content-Type': 'application/json'});
  }

  /// PUT a document with a specific _id.
  Future<CouchResponse> putDocument(
      String id, JsonObjectLite<dynamic> document,
      [String rev]) async {
    var urlPath = id;
    if (rev != null) {
      urlPath = '$id?rev=$rev';
    }
    final url = _buildUrl(urlPath);
    final jsonData = json.encode(document);
    return _request('PUT', url,
        body: jsonData,
        extraHeaders: {'Content-Type': 'application/json'});
  }
}
