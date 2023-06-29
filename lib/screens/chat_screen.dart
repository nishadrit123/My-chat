import 'package:flutter/material.dart';
import '../constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
User? loggeduser;
String msgtime = '';
bool flag = true;
DateTime? currentDate;

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);
  static const cs = 'chat_screen';

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  String messageText = '';
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getemail();
  }

  void getemail() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        //ignore: avoid_print
        print(user.email);
        loggeduser = user;
      }
    } catch (e) {
      //ignore: avoid_print
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: const Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Expanded(child: MessageStream()),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      textCapitalization: TextCapitalization.sentences,
                      controller: textController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      textController.clear();
                      final timestamp = FieldValue.serverTimestamp();
                      _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': loggeduser?.email,
                        'timestamp': timestamp,
                        'isDeleted': false,
                        'deletedBy': loggeduser?.email
                      });
                    },
                    child: const Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  const MessageStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
      _firestore
          .collection('messages')
          .orderBy('timestamp')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child:
            CircularProgressIndicator(backgroundColor: Colors.blueAccent),
          );
        }

        final messages = snapshot.data!.docs;
        List<Widget> messageWidgets = [];
        String? currentFormattedDate;

        for (var message in messages) {
          final messageText = message['text'];
          final messageSender = message['sender'];
          final currUser = loggeduser?.email;
          final timestamp = message['timestamp'];
          if (timestamp != null) {
            final DateTime date = DateTime.fromMillisecondsSinceEpoch(
                timestamp.seconds * 1000);
            final String formattedDate = _getFormattedDate(date);

            // if (message['timestamp'] != null) {
            final DateTime date1 = DateTime.fromMillisecondsSinceEpoch(
                message['timestamp'].seconds * 1000);
            final String formattedTime =
                '${date1.hour.toString().padLeft(2, '0')}:${date1.minute
                .toString().padLeft(2, '0')}';
            msgtime = formattedTime;
            // }

            final messageBubble = MessageBubble(
              sender: messageSender,
              text: messageText,
              isMe: messageSender == currUser,
              msgTime: msgtime,
              timestamp: timestamp,
            );

            if (formattedDate != currentFormattedDate) {
              currentFormattedDate = formattedDate;
              currentDate = date;
              messageWidgets.add(
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }
            if ((!message['isDeleted']) || (message['isDeleted']) && message['deletedBy'] != loggeduser?.email) {
              messageWidgets.add(messageBubble);
            }
          }
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding:
            const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageWidgets.reversed.toList(),
          ),
        );
      },
    );
  }

  String _getFormattedDate(DateTime date) {
    final String month = _getMonthName(date.month);
    return '$month ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }
}

class MessageBubble extends StatefulWidget {
  const MessageBubble({
    Key? key,
    required this.sender,
    required this.text,
    required this.isMe,
    required this.msgTime,
    required this.timestamp
  }) : super(key: key);

  final String sender;
  final String text;
  final bool isMe;
  final String msgTime;
  final Timestamp timestamp;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showDeleteIcon = false;

  void _handleLongPress() {
    setState(() {
      _showDeleteIcon = true;
    });
  }

  void _handleTap() {
    setState(() {
      _showDeleteIcon = false;
    });
  }

  deleteForEveryone() {
    final CollectionReference messageRef = FirebaseFirestore.instance.collection('messages');
    final DateTime timestamp = widget.timestamp.toDate(); // Convert Timestamp to DateTime
    messageRef
        .where('timestamp', isEqualTo: timestamp)
        .get()
        .then((snapshot) {
      if (snapshot.size > 0) {
        final document = snapshot.docs[0];
        document.reference.delete();
      }
    });
  }

  deleteForMe() {
    final CollectionReference messageRef = FirebaseFirestore.instance.collection('messages');
    final DateTime timestamp = widget.timestamp.toDate(); // Convert Timestamp to DateTime
    messageRef
        .where('timestamp', isEqualTo: timestamp)
        .get()
        .then((snapshot) {
      if (snapshot.size > 0) {
        final document = snapshot.docs[0];
        document.reference.update({
          'isDeleted': true,
          'deletedBy': loggeduser?.email
        });
      }
    });
  }

  void _showPopup(BuildContext context, bool ifme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete message ?'),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0), // Adjust the padding as needed
          buttonPadding: const EdgeInsets.only(top: 16.0), // Add spacing between buttons
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (ifme)
                  TextButton(
                    child: const Text('Delete for everyone'),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      deleteForEveryone();
                      Navigator.of(context).pop();
                    },
                  ),
                TextButton(
                  child: const Text('Delete for me'),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    deleteForMe();
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _handleDelete(bool ifme) {
    setState(() {
      _showDeleteIcon = false;
    });

    _showPopup(context, ifme);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.sender,
            style: const TextStyle(color: Colors.black, fontSize: 15.0),
          ),
          GestureDetector(
            onLongPress: _handleLongPress,
            onTap: _handleTap,
            child: Material(
              elevation: 10.0,
              borderRadius: widget.isMe
                  ? const BorderRadius.only(
                topLeft: Radius.circular(30.0),
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0),
              )
                  : const BorderRadius.only(
                topRight: Radius.circular(30.0),
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0),
              ),
              color: widget.isMe ? Colors.lightBlueAccent : Colors.white,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end, // Align time to the right
                  children: [
                    Text(
                      widget.text,
                      style: const TextStyle(fontSize: 20.0),
                    ),
                    Text(
                      widget.msgTime,
                      style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showDeleteIcon)
            GestureDetector(
              onTap: (){
                _handleDelete(widget.isMe);
                },
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
                padding: const EdgeInsets.all(8.0),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
