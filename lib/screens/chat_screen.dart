import 'package:flutter/material.dart';
import '../constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
final _firestore = FirebaseFirestore.instance;
User? loggeduser;

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
      final user = await _auth.currentUser;
      if (user != null){
        //ignore: avoid_print
        print(user.email);
        loggeduser = user;
      }
    } catch (e){
      //ignore: avoid_print
      print(e);
    }
  }

  // void getmessages() async {
  //   final messages = await _firestore.collection('messages').get();
  //   for (var m in messages.docs){
  //     //ignore: avoid_print
  //     print(m.data);
  //   }
  // }

  void messageStream() async {
    await for (var snapshot in _firestore.collection('messages').snapshots()){
      for (var m in snapshot.docs){
        //ignore: avoid_print
        print(m.data);
      }
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
            const MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
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
                      _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': loggeduser?.email,
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
    return StreamBuilder (
        stream: _firestore.collection('messages').snapshots(),
        builder: (context, snapshot){
          if (! snapshot.hasData){
            return const Center(
              child: CircularProgressIndicator(backgroundColor: Colors.blueAccent,),
            );
          }
          final messages = (snapshot.data!).docs.reversed;

          List <MessageBubble> messageBubbles = [];
          for (var i in messages){
            final messageText = i['text'];
            final messageSender = i['sender'];
            final currUser = loggeduser?.email;
            final messageBubble = MessageBubble(sender: messageSender, text: messageText, isme: messageSender == currUser,);
            messageBubbles.add(messageBubble);
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              children: messageBubbles,
            ),
          );
        }
    );
  }
}


class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.sender, required this.text, required this.isme});

  final String sender;
  final String text;
  final bool isme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isme ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(sender, style: const TextStyle(color: Colors.black, fontSize: 15.0),),
          Material(
            elevation: 10.0,
            borderRadius: isme ? const BorderRadius.only(topLeft: Radius.circular(30.0), bottomLeft: Radius.circular (30.0), bottomRight: Radius.circular (30.0))
              : const BorderRadius.only(topRight: Radius.circular(30.0), bottomLeft: Radius.circular (30.0), bottomRight: Radius.circular (30.0)),
            color: isme ? Colors.lightBlueAccent : Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                child: Text(text, style: const TextStyle(fontSize: 20.0),),
              )
          ),
        ],
      ),
    );
  }
}
