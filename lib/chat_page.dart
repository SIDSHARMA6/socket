import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api.dart';

class ChatPage extends StatefulWidget {
  final int sender;
  final int receiver;
  final String token;

  ChatPage({required this.sender, required this.receiver, required this.token});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late IO.Socket socket;
  List<Map<String, dynamic>> messages = [];
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    connectSocket();
    loadOldMessages();
  }

  void loadOldMessages() async {
    try {
      final old = await ApiService.getMessagesWithAuth(widget.token);
      setState(() {
        messages = old
            .map((e) {
              final text = e["text"]?.toString() ?? "";
              final senderId = e["sender"]?["id"];
              final isMe = senderId == widget.sender;
              return {"text": text, "isMe": isMe};
            })
            .where((msg) => (msg["text"] as String).isNotEmpty)
            .toList();
      });
    } catch (e) {
      print("Error loading messages: $e");
    }
  }

  void connectSocket() {
    socket = IO.io(ApiService.baseUrl, <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
    });

    socket.connect();

    socket.onConnect((_) {
      print("Connected to socket");
    });

    socket.on("message-${widget.sender}", (data) {
      try {
        final text = data["text"]?.toString();
        final senderId = data["sender"]?["id"];
        if (text != null && text.isNotEmpty) {
          setState(() {
            messages.add({"text": text, "isMe": senderId == widget.sender});
          });
        }
      } catch (e) {
        print("Error receiving message: $e");
      }
    });
  }

  void sendMsg() {
    if (controller.text.trim().isEmpty) return;

    try {
      socket.emit("sendMessage", {
        "text": controller.text,
        "sender": widget.sender,
        "receiver": widget.receiver
      });

      controller.clear();
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  @override
  void dispose() {
    socket.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final msg = messages[i];
                final isMe = msg["isMe"] ?? false;
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["text"] ?? "",
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                      hintText: "Type message...",
                      contentPadding: EdgeInsets.all(12)),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: sendMsg,
              ),
            ],
          )
        ],
      ),
    );
  }
}
