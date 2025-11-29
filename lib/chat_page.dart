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
  final ScrollController scrollController = ScrollController();
  bool isConnected = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    connectSocket();
    loadOldMessages();
  }

  void loadOldMessages() async {
    try {
      setState(() => isLoading = true);

      final old = await ApiService.getMessagesWithAuth(widget.token);
      print("📥 Loaded ${old.length} messages");

      setState(() {
        messages = old.where((e) {
          final senderId = e["sender"] is Map ? e["sender"]["id"] : e["sender"];
          final receiverId =
              e["receiver"] is Map ? e["receiver"]["id"] : e["receiver"];

          // Only messages between these 2 users
          return (senderId == widget.sender && receiverId == widget.receiver) ||
              (senderId == widget.receiver && receiverId == widget.sender);
        }).map((e) {
          final text = e["text"]?.toString() ?? "";
          final senderId = e["sender"] is Map ? e["sender"]["id"] : e["sender"];
          final time = e["createdAt"]?.toString() ?? DateTime.now().toString();

          return {
            "text": text,
            "isMe": senderId == widget.sender,
            "time": time
          };
        }).toList();

        isLoading = false;
      });

      print("✅ Processed ${messages.length} messages");
      scrollToBottom();
    } catch (e) {
      print("❌ Error loading messages: $e");
      setState(() => isLoading = false);
    }
  }

  void connectSocket() {
    print("🔌 Connecting to: ${ApiService.baseUrl}");

    socket = IO.io(ApiService.baseUrl, <String, dynamic>{
      "transports": ["websocket", "polling"],
      "autoConnect": true,
    });

    socket.onConnect((_) {
      print("✅ Socket connected!");
      setState(() => isConnected = true);
    });

    socket.onConnectError((data) {
      print("❌ Connection error: $data");
      setState(() => isConnected = false);
    });

    socket.onDisconnect((_) {
      print("⚠️ Socket disconnected");
      setState(() => isConnected = false);
    });

    // Listen for messages
    socket.on("message-${widget.sender}", (data) {
      print("📨 Received message: $data");

      try {
        final text = data["text"]?.toString() ?? "";
        final senderId =
            data["sender"] is Map ? data["sender"]["id"] : data["sender"];
        final receiverId =
            data["receiver"] is Map ? data["receiver"]["id"] : data["receiver"];

        // Only add if relevant to this conversation
        if ((senderId == widget.sender && receiverId == widget.receiver) ||
            (senderId == widget.receiver && receiverId == widget.sender)) {
          setState(() {
            messages.add({
              "text": text,
              "isMe": senderId == widget.sender,
              "time": DateTime.now().toString()
            });
          });

          print("✅ Message added. Total: ${messages.length}");
          scrollToBottom();
        }
      } catch (e) {
        print("❌ Error processing message: $e");
      }
    });
  }

  void sendMsg() {
    if (controller.text.trim().isEmpty) return;

    final text = controller.text.trim();
    print("📤 Sending: $text");

    // Add to UI immediately
    setState(() {
      messages
          .add({"text": text, "isMe": true, "time": DateTime.now().toString()});
    });

    controller.clear();
    scrollToBottom();

    // Send via socket
    socket.emit("sendMessage",
        {"text": text, "sender": widget.sender, "receiver": widget.receiver});

    print("✅ Message sent via socket");
  }

  void scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    socket.dispose();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        actions: [
          Icon(
            isConnected ? Icons.circle : Icons.circle_outlined,
            color: isConnected ? Colors.green : Colors.red,
            size: 12,
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          if (isLoading) LinearProgressIndicator(),
          Expanded(
            child: messages.isEmpty && !isLoading
                ? Center(child: Text('No messages yet'))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[i];
                      final isMe = msg["isMe"] ?? false;
                      final time = msg["time"] ?? "";
                      final timeStr = time.isNotEmpty
                          ? DateTime.parse(time)
                              .toLocal()
                              .toString()
                              .substring(11, 16)
                          : "";

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg["text"] ?? "",
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                ),
                              ),
                              if (timeStr.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Type message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => sendMsg(),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: sendMsg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
