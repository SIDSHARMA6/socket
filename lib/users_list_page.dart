import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api.dart';
import 'chat_page.dart';

class UsersListPage extends StatefulWidget {
  final int currentUserId;
  final String token;

  UsersListPage({required this.currentUserId, required this.token});

  @override
  _UsersListPageState createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  List<dynamic> users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  void loadUsers() async {
    try {
      final res = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/users"),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          users = data.where((u) => u['id'] != widget.currentUserId).toList();
          loading = false;
        });
      }
    } catch (e) {
      print("Error loading users: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select User to Chat'),
        automaticallyImplyLeading: false,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? Center(child: Text('No other users found'))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user['username'][0].toUpperCase()),
                      ),
                      title: Text(user['username']),
                      subtitle: Text(user['email']),
                      trailing: Icon(Icons.chat),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              sender: widget.currentUserId,
                              receiver: user['id'],
                              token: widget.token,
                              receiverName: user['username'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
