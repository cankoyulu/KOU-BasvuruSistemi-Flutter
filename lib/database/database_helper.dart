//@dart=2.9
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:json_object_lite/json_object_lite.dart' as jsonobject;

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

  /// Low-level HTTP request returning a response object compatible with
  /// the old Wilt interface (jsonCouchResponse, error, etc.).
  Future<dynamic> _request(String method, String url,
      {String body, Map<String, String> extraHeaders}) async {
    final completer = Completer<dynamic>();

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
        final response = jsonobject.JsonObjectLite<dynamic>();
        response.error = false;
        response.errorCode = xhr.status;
        response.responseText = xhr.responseText;
        response.method = method;

        if (xhr.status >= 200 && xhr.status < 300) {
          try {
            response.jsonCouchResponse =
                jsonobject.JsonObjectLite<dynamic>.fromJsonString(xhr.responseText);
          } catch (e) {
            response.error = true;
            final err = jsonobject.JsonObjectLite<dynamic>();
            err.error = 'json Decode Error';
            err.reason = e.toString();
            response.jsonCouchResponse = err;
          }
        } else {
          response.error = true;
          try {
            response.jsonCouchResponse =
                jsonobject.JsonObjectLite<dynamic>.fromJsonString(xhr.responseText);
          } catch (e) {
            final err = jsonobject.JsonObjectLite<dynamic>();
            err.error = 'HTTP ${xhr.status}';
            err.reason = xhr.statusText ?? 'Request failed';
            response.jsonCouchResponse = err;
          }
        }

        if (!completer.isCompleted) {
          completer.complete(response);
        }
      });

      xhr.onError.listen((_) {
        final response = jsonobject.JsonObjectLite<dynamic>();
        response.error = true;
        response.errorCode = 0;
        response.method = method;
        final err = jsonobject.JsonObjectLite<dynamic>();
        err.error = 'Network error';
        err.reason = 'HTTP request failed';
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
      final response = jsonobject.JsonObjectLite<dynamic>();
      response.error = true;
      response.errorCode = 0;
      response.method = method;
      final err = jsonobject.JsonObjectLite<dynamic>();
      err.error = 'Exception';
      err.reason = e.toString();
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
  Future<dynamic> getDocument(String id) async {
    final url = _buildUrl(id);
    return _request('GET', url);
  }

  /// GET a raw path (e.g. a view URL).
  Future<dynamic> get(String path) async {
    final url = _buildUrl(path);
    return _request('GET', url);
  }

  /// POST a document (CouchDB generates a random _id).
  Future<dynamic> postDocument(jsonobject.JsonObjectLite<dynamic> document,
      {String path}) async {
    var urlPath = path != null ? '/$path' : '/';
    final url = _buildUrl(urlPath);
    return _request('POST', url,
        body: json.encode(document),
        extraHeaders: {'Content-Type': 'application/json'});
  }

  /// PUT a document with a specific _id.
  Future<dynamic> putDocument(
      String id, jsonobject.JsonObjectLite<dynamic> document,
      [String rev]) async {
    var urlPath = id;
    if (rev != null) {
      urlPath = '$id?rev=$rev';
    }
    final url = _buildUrl(urlPath);
    String jsonData;
    if (rev != null) {
      jsonData = json.encode(document);
    } else {
      jsonData = json.encode(document);
    }
    return _request('PUT', url,
        body: jsonData,
        extraHeaders: {'Content-Type': 'application/json'});
  }
}
