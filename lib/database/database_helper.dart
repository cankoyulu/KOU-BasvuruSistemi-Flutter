//@dart=2.9
import 'dart:html' as html;
import 'package:balancedtrees/bplustree/bplustree.dart';
import 'package:balancedtrees/comparators/comparators.dart';
import 'package:balancedtrees/util/util.dart';
import 'package:wilt/wilt.dart';


class DatabaseHelper {
  dynamic Connection() {
    final host = html.window.location.hostname;
    final portStr = html.window.location.port;
    final ssl = html.window.location.protocol == 'https:';
    final port = portStr.isNotEmpty ? int.parse(portStr) : (ssl ? 443 : 80);

    final db = Wilt(host, port: port, useSSL: ssl);
    db.login("admin", "123321k");
    db.db = 'kou-database';

    return db;
  }
}