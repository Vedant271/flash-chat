import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/rendering.dart';

late User loggedInUser;
final _firestore = FirebaseFirestore.instance;

class ChatScreen extends StatefulWidget {

  static const String id = 'Chat_Screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  late String messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try{
      final user = await _auth.currentUser!;
      if(user!=null)
      {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    }
    catch(e){
      print(e);
    }
  }

  // void getMessages()async{
  //   final messages = await _firestore.collection('messages').get();
  //   for(var message in messages.docs)
  //     {
  //         print(message.data()); // not got result when "message.data" is used, got result when "message.data()" is used
  //     }
  // }

  void messageStream() async
  {
     await for(var snapshot in _firestore.collection('messages').snapshots())
     for(var message in snapshot.docs){
       print(message.data());
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                messageStream();
                //Implement logout functionality
                // _auth.signOut();
                // Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        //Do something with the user input.
                        messageText=value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      //Implement send functionality.
                      //messsageText + loggedInUser.email
                      messageTextController.clear();
                    _firestore.collection('messages').add({
                      'text':messageText,
                      'sender':loggedInUser.email,
                      'time':FieldValue.serverTimestamp()
                    });
                    },
                    child: Text(
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

class MessagesStream extends StatelessWidget {
  const MessagesStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('messages')
          .orderBy('time',descending: false)
          .snapshots(),
      builder:(context,snapshot){
        if(!snapshot.hasData){
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        final messages = snapshot.data!.docs.reversed;
        List<MessageBubble> messageBubbles = [];
        for(var message in messages){
          final messageText = message.get("text");
          final messageSender = message.get("sender");
          final messageTime = message.get('time') as Timestamp;

          final currentUser = loggedInUser.email;

          if(currentUser==messageSender){
          }

          final messageBubble = MessageBubble(
            text: messageText,
            sender: messageSender,
            isMe: currentUser==messageSender,
            time: messageTime,
          );

          messageBubbles.add(messageBubble);
        }

        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10.0,vertical: 20.0),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}


class MessageBubble extends StatelessWidget {

  MessageBubble({required this.text, required this.sender, required this.isMe, required this.time});

  final Timestamp time;
  final bool isMe;
  final String text;
  final String sender;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
              sender,
          style : TextStyle(
            fontSize: 12.0,
            color: Colors.black54,
          ),
          ),
          Material(
            color: isMe ? Colors.lightBlueAccent:Colors.white,
            elevation: 15.0,
            borderRadius: isMe ? BorderRadius.only(topLeft: Radius.circular(15.0),bottomLeft: Radius.circular(15.0),bottomRight: Radius.circular(15.0)) :
            BorderRadius.only(topRight: Radius.circular(15.0),bottomLeft: Radius.circular(15.0),bottomRight: Radius.circular(15.0)),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                text,
                style:TextStyle(
                  fontSize: 15.0,
                  color: isMe ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



