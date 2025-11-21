import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api.dart';

class ChatPage extends StatefulWidget {
  final int sender;
  final int receiver;
  final String token;
  final String receiverName;

  ChatPage({
    required this.sender,
    required this.receiver,
    required this.token,
    this.receiverName = "Chat",
  });

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
      print("=== LOADING OLD MESSAGES ===");
      print("Sender ID: ${widget.sender}");
      print("Receiver ID: ${widget.receiver}");

      final old = await ApiService.getMessagesWithAuth(widget.token);
      print("Raw messages received: $old");
      print("Number of messages: ${old.length}");

      setState(() {
        messages = old
            .map((e) {
              print("Processing message: $e");
              // Handle both direct response and nested data structure
              final text = e["text"]?.toString() ?? "";
              final senderId =
                  e["sender"] is Map ? e["sender"]["id"] : e["sender"];
              final isMe = senderId == widget.sender;
              print("Text: $text, SenderId: $senderId, IsMe: $isMe");
              return {"text": text, "isMe": isMe};
            })
            .where((msg) => (msg["text"] as String).isNotEmpty)
            .toList();
      });

      print("Processed messages count: ${messages.length}");
    } catch (e) {
      print("Error loading messages: $e");
    }
  }

  void connectSocket() {
    print("=== CONNECTING TO SOCKET ===");
    print("Socket URL: ${ApiService.baseUrl}");
    print("Listening on channel: message-${widget.sender}");

    socket = IO.io(ApiService.baseUrl, <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
    });

    socket.connect();

    socket.onConnect((_) {
      print("✅ Socket connected successfully!");
      print("Socket ID: ${socket.id}");
    });

    socket.onConnectError((data) {
      print("❌ Socket connection error: $data");
    });

    socket.onDisconnect((_) {
      print("⚠️ Socket disconnected");
    });

    socket.on("message-${widget.sender}", (data) {
      print("=== RECEIVED MESSAGE ON SOCKET ===");
      print("Raw data: $data");
      try {
        final text = data["text"]?.toString();
        final senderId =
            data["sender"] is Map ? data["sender"]["id"] : data["sender"];
        print("Text: $text");
        print("Sender ID: $senderId");
        print("Is from me: ${senderId == widget.sender}");

        if (text != null && text.isNotEmpty) {
          setState(() {
            messages.add({"text": text, "isMe": senderId == widget.sender});
          });
          print("Message added to list. Total messages: ${messages.length}");
        }
      } catch (e) {
        print("Error receiving message: $e");
      }
    });
  }

  void sendMsg() {
    if (controller.text.trim().isEmpty) return;

    print("=== SENDING MESSAGE ===");
    print("Text: ${controller.text}");
    print("Sender: ${widget.sender}");
    print("Receiver: ${widget.receiver}");
    print("Socket connected: ${socket.connected}");

    try {
      final messageData = {
        "text": controller.text,
        "sender": widget.sender,
        "receiver": widget.receiver
      };

      print("Emitting data: $messageData");
      socket.emit("sendMessage", messageData);
      print("✅ Message emitted to socket");

      // Add message to UI immediately (optimistic update)
      setState(() {
        messages.add({"text": controller.text, "isMe": true});
      });
      print("Message added to UI. Total: ${messages.length}");

      controller.clear();
    } catch (e) {
      print("❌ Error sending message: $e");
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
      appBar: AppBar(title: Text(widget.receiverName)),
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
