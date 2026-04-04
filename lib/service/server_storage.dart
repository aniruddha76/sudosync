import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/server.dart';

class ServerStorage {
  static const _serversKey = "servers";
  final _secure = const FlutterSecureStorage();

  Future<List<Server>> getServers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_serversKey);

    if (data == null) return [];

    List list = jsonDecode(data);
    List<Server> servers = [];

    for (var s in list) {
      String? pass = await _secure.read(key: "pass_${s["id"]}");

      if (pass != null) {
        servers.add(Server.fromJson(s, pass));
      }
    }

    return servers;
  }

  Future<void> saveServer(Server server) async {
    final prefs = await SharedPreferences.getInstance();
    List<Server> servers = await getServers();

    servers.add(server);

    List jsonList = servers.map((e) => e.toJson()).toList();

    await prefs.setString(_serversKey, jsonEncode(jsonList));

    await _secure.write(key: "pass_${server.id}", value: server.password);
  }

  Future<void> deleteServer(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_serversKey);

    if (data == null) return;

    List list = jsonDecode(data);

    // remove server from list
    list.removeWhere((s) => s["id"] == id);

    // save updated list
    await prefs.setString(_serversKey, jsonEncode(list));

    // delete password
    await _secure.delete(key: "pass_$id");
  }
}
