import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api.dart';
import 'dart:async';

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

enum MessageStatus { sending, sent, delivered, read, failed }

class ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  final String? tempId;
  final int? messageId;
  MessageStatus status;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    this.tempId,
    this.messageId,
    this.status = MessageStatus.sending,
  });
}

class _ChatPageState extends State<ChatPage> {
  late IO.Socket socket;
  List<ChatMessage> messages = [];
  TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  bool isConnected = false;
  bool isTyping = false;
  bool receiverTyping = false;
  bool isLoading = true;
  Timer? typingTimer;

  @override
  void initState() {
    super.initState();
    connectSocket();
    loadOldMessages();

    // Listen to text changes for typing indicator
    controller.addListener(onTextChanged);
  }

  void onTextChanged() {
    if (controller.text.isNotEmpty && !isTyping) {
      isTyping = true;
      socket.emit('typing', {'receiver': widget.receiver, 'isTyping': true});
    }

    // Reset typing timer
    typingTimer?.cancel();
    typingTimer = Timer(Duration(seconds: 2), () {
      if (isTyping) {
        isTyping = false;
        socket.emit('typing', {'receiver': widget.receiver, 'isTyping': false});
      }
    });
  }

  void loadOldMessages() async {
    try {
      setState(() => isLoading = true);

      final old = await ApiService.getMessagesWithAuth(widget.token);

      setState(() {
        messages = old.where((e) {
          final senderId = e["sender"] is Map ? e["sender"]["id"] : e["sender"];
          final receiverId =
              e["receiver"] is Map ? e["receiver"]["id"] : e["receiver"];
          return (senderId == widget.sender && receiverId == widget.receiver) ||
              (senderId == widget.receiver && receiverId == widget.sender);
        }).map((e) {
          final text = e["text"]?.toString() ?? "";
          final senderId = e["sender"] is Map ? e["sender"]["id"] : e["sender"];
          final time = e["createdAt"]?.toString() ?? DateTime.now().toString();

          return ChatMessage(
            text: text,
            isMe: senderId == widget.sender,
            time: time,
            messageId: e["id"],
            status: MessageStatus.delivered,
          );
        }).toList();

        isLoading = false;
      });

      scrollToBottom();
    } catch (e) {
      print("Error loading messages: $e");
      setState(() => isLoading = false);
      showError("Failed to load messages");
    }
  }

  void connectSocket() {
    socket = IO.io(
      ApiService.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .setAuth({'token': widget.token})
          .build(),
    );

    socket.onConnect((_) {
      print("✅ Socket connected");
      setState(() => isConnected = true);
    });

    socket.onConnectError((data) {
      print("❌ Connection error: $data");
      setState(() => isConnected = false);
      showError("Connection failed");
    });

    socket.onDisconnect((_) {
      print("⚠️ Socket disconnected");
      setState(() => isConnected = false);
    });

    socket.onReconnect((_) {
      print("🔄 Reconnected");
      setState(() => isConnected = true);
    });

    // Listen for new messages
    socket.on('newMessage', (data) {
      print("📨 New message received: $data");

      final senderId =
          data["sender"] is Map ? data["sender"]["id"] : data["sender"];
      if (senderId == widget.receiver) {
        final text = data["text"]?.toString() ?? "";
        final time = data["createdAt"]?.toString() ?? DateTime.now().toString();

        setState(() {
          messages.add(ChatMessage(
            text: text,
            isMe: false,
            time: time,
            messageId: data["id"],
            status: MessageStatus.delivered,
          ));
        });

        scrollToBottom();

        // Send read receipt
        socket.emit(
            'messageRead', {'messageId': data["id"], 'senderId': senderId});
      }
    });

    // Listen for message sent confirmation
    socket.on('messageSent', (data) {
      print("✅ Message sent confirmation: ${data['tempId']}");

      setState(() {
        final index = messages.indexWhere((m) => m.tempId == data['tempId']);
        if (index != -1) {
          messages[index].status = MessageStatus.sent;
          messages[index] = ChatMessage(
            text: messages[index].text,
            isMe: messages[index].isMe,
            time: messages[index].time,
            tempId: messages[index].tempId,
            messageId: data['id'],
            status: MessageStatus.sent,
          );
        }
      });
    });

    // Listen for message delivered
    socket.on('messageDelivered', (data) {
      print("📬 Message delivered: ${data['tempId']}");

      setState(() {
        final index = messages.indexWhere((m) => m.tempId == data['tempId']);
        if (index != -1) {
          messages[index].status = MessageStatus.delivered;
        }
      });
    });

    // Listen for message read
    socket.on('messageRead', (data) {
      print("👁️ Message read: ${data['messageId']}");

      setState(() {
        final index =
            messages.indexWhere((m) => m.messageId == data['messageId']);
        if (index != -1) {
          messages[index].status = MessageStatus.read;
        }
      });
    });

    // Listen for typing indicator
    socket.on('userTyping', (data) {
      if (data['userId'] == widget.receiver) {
        setState(() => receiverTyping = data['isTyping']);
      }
    });

    // Listen for errors
    socket.on('messageError', (data) {
      print("❌ Message error: $data");

      setState(() {
        final index = messages.indexWhere((m) => m.tempId == data['tempId']);
        if (index != -1) {
          messages[index].status = MessageStatus.failed;
        }
      });

      showError("Failed to send message");
    });
  }

  void sendMsg() {
    if (controller.text.trim().isEmpty) return;

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final text = controller.text.trim();

    // Add message to UI immediately (optimistic update)
    setState(() {
      messages.add(ChatMessage(
        text: text,
        isMe: true,
        time: DateTime.now().toString(),
        tempId: tempId,
        status: MessageStatus.sending,
      ));
    });

    controller.clear();
    scrollToBottom();

    // Stop typing indicator
    if (isTyping) {
      isTyping = false;
      socket.emit('typing', {'receiver': widget.receiver, 'isTyping': false});
    }

    // Send via socket
    socket.emit("sendMessage", {
      "text": text,
      "receiver": widget.receiver,
      "tempId": tempId,
    });
  }

  void retryMessage(ChatMessage message) {
    if (message.tempId != null) {
      setState(() {
        final index = messages.indexOf(message);
        if (index != -1) {
          messages[index].status = MessageStatus.sending;
        }
      });

      socket.emit("sendMessage", {
        "text": message.text,
        "receiver": widget.receiver,
        "tempId": message.tempId,
      });
    }
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

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return '🕐';
      case MessageStatus.sent:
        return '✓';
      case MessageStatus.delivered:
        return '✓✓';
      case MessageStatus.read:
        return '✓✓';
      case MessageStatus.failed:
        return '❌';
    }
  }

  @override
  void dispose() {
    socket.dispose();
    controller.dispose();
    scrollController.dispose();
    typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName),
            if (receiverTyping)
              Text(
                'typing...',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
          ],
        ),
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
                      final timeStr = DateTime.parse(msg.time)
                          .toLocal()
                          .toString()
                          .substring(11, 16);

                      return Align(
                        alignment: msg.isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: GestureDetector(
                          onLongPress: msg.status == MessageStatus.failed
                              ? () => retryMessage(msg)
                              : null,
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: msg.isMe ? Colors.blue : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.text,
                                  style: TextStyle(
                                    color:
                                        msg.isMe ? Colors.white : Colors.black,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: msg.isMe
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                    if (msg.isMe) ...[
                                      SizedBox(width: 4),
                                      Text(
                                        getStatusIcon(msg.status),
                                        style: TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
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
                    icon: Icon(Icons.send, color: Colors.white),
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
